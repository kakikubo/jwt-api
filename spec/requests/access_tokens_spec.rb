# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AccessTokens', type: :request do
  let!(:user) { active_user }
  let!(:encode) { UserAuth::AccessToken.new(user_id: user.id) }
  let!(:lifetime) { UserAuth.access_token_lifetime }
  let!(:expect_lifetime) { lifetime.from_now.to_i }

  describe '共通メソッド' do
    context 'auth_token_methods' do
      it '初期設定値は想定どおりか' do
        expect(encode.send(:algorithm)).to eq('HS256')
        expect(encode.send(:secret_key)).to eq(encode.send(:decode_key))
        expect(encode.send(:user_claim)).to eq(:sub)
        expect(encode.send(:header_fields)).to eq({ typ: 'JWT', alg: 'HS256' })
      end

      it 'user_idがnilの場合、暗号メソッドはnilを返しているか' do
        user_id = nil
        expect(encode.send(:encrypt_for, user_id)).to be nil
      end

      it 'user_idがnilの場合、複合メソッドはnilを返しているか' do
        user_id = nil
        expect(encode.send(:decrypt_for, user_id)).to be nil
      end

      it 'user_idが不正な場合、複合メソッドはnilを返しているか' do
        user_id = 'aaaaaa'
        expect(encode.send(:decrypt_for, user_id)).to be nil
      end
    end
  end

  describe 'エンコード検証' do
    context 'encode_token' do
      let!(:payload) { encode.payload }
      let!(:user_claim) { encode.send(:user_claim) }

      it 'トークン有効期限は期待される時間と同じか(1秒許容)' do
        expect(encode.send(:token_expiration)).to be_within(1.seconds).of(expect_lifetime)
      end

      it '発行時のpayloadは想定通りか' do
        expect(payload[:exp]).to eq(expect_lifetime)
        expect(payload[user_claim]).to eq(encode.user_id)
        expect(payload[:iss]).to eq(UserAuth.token_issuer)
        expect(payload[:aud]).to eq(UserAuth.token_audience)
      end

      it 'lifetime_textメソッドは想定どおりか' do
        expect(encode.lifetime_text).to eq('30分')
      end
    end
  end

  describe 'デコード検証' do
    context 'decode_token' do
      let!(:decode) { UserAuth::AccessToken.new(token: encode.token) }
      let!(:payload) { decode.payload }
      let!(:verify_claims) { decode.send(:verify_claims) }

      it 'デコードユーザーは一致しているか' do
        expect(decode.entity_for_user).to eq(user)
      end

      it 'verify_claimsは想定どおりか' do
        expect(verify_claims[:iss]).to eq(UserAuth.token_issuer)
        expect(verify_claims[:aud]).to eq(UserAuth.token_audience)
        expect(verify_claims[:algorithm]).to eq(UserAuth.token_signature_algorithm)
        expect(verify_claims[:verify_expiration]).to be_truthy
        expect(verify_claims[:verify_iss]).to be_truthy
        expect(verify_claims[:verify_aud]).to be_truthy
        expect(verify_claims[:sub]).to be_falsy
        expect(verify_claims[:verify_sub]).to be_falsy
      end

      it '有効期限内はエラーを吐いていないか' do
        travel_to(lifetime.from_now - 1.second) do
          expect(UserAuth::AccessToken.new(token: encode.token)).to be_truthy
        end
      end

      it '有効期限後トークンはエラーを吐いているか' do
        travel_to(lifetime.from_now) do
          expect { UserAuth::AccessToken.new(token: encode.token) }.to raise_error(JWT::ExpiredSignature)
        end
      end

      it 'トークンが書き換えられた場合エラーを吐いているか' do
        expect { UserAuth::AccessToken.new(token: "#{encode.token}aaaaaaa") }.to raise_error(JWT::DecodeError)
      end

      it 'issuerが改ざんされたtokenはエラーを吐いているか' do
        invalid_token = UserAuth::AccessToken.new(payload: { iss: 'invalid' }).token
        expect { UserAuth::AccessToken.new(token: invalid_token) }.to raise_error(JWT::InvalidIssuerError)
      end

      it 'audienceが改ざんされたtokenはエラーを吐いているか' do
        invalid_token = UserAuth::AccessToken.new(payload: { aud: 'invalid' }).token
        expect { UserAuth::AccessToken.new(token: invalid_token) }.to raise_error(JWT::InvalidAudError)
      end
    end
  end

  describe 'デコードオプション' do
    context 'verify_claims' do
      let!(:sub) { encode.user_id }
      let!(:decode) { UserAuth::AccessToken.new(token: encode.token, options: { sub: }) }

      it 'subオプションは有効か' do
        verify_claims = decode.send(:verify_claims)
        expect(verify_claims[:sub]).to eq(sub)
        expect(verify_claims[:verify_sub]).to be_truthy
      end

      it 'subオプションで有効なユーザは返ってきているか' do
        expect(decode.entity_for_user).to eq(user)
      end

      it '不正なsubにはエラーを吐いているか' do
        expect do
          UserAuth::AccessToken.new(token: encode.token, options: { sub: 'invalid' })
        end.to raise_error(JWT::InvalidSubError)
      end
    end
  end

  describe 'not activeユーザーの挙動' do
    context 'not_active_user' do
      let!(:not_active) do
        User.create(name: 'a', email: 'a@a.a', password: 'password')
      end
      let!(:encode_token) { UserAuth::AccessToken.new(user_id: not_active.id).token }
      let!(:decode_token_user) { UserAuth::AccessToken.new(token: encode_token).entity_for_user }

      it 'not activeと判定されているか' do
        expect(not_active.activated).to be_falsy
      end

      it 'アクティブではないユーザも取得できているか' do
        expect(decode_token_user).to eq(not_active)
      end
    end
  end
end
