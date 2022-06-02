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
        expect { UserAuth::AccessToken.new(token: "#{encode.token}aaaaaaa") }.to raise_error(JWT::VerificationError)
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
  describe '��コードオプション' do
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
# require 'test_helper'

# class AccessTokenTest < ActionDispatch::IntegrationTest
#   def setup
#     @user = active_user
#     @encode = UserAuth::AccessToken.new(user_id: @user.id)
#     @lifetime = UserAuth.access_token_lifetime
#   end

#   # 共通メソッド
#   test 'auth_token_methods' do
#     # 初期設定値は想定通りか
#     assert_equal 'HS256', @encode.send(:algorithm)
#     assert_equal @encode.send(:secret_key), @encode.send(:decode_key)
#     assert_equal :sub, @encode.send(:user_claim)
#     assert_equal({ typ: 'JWT', alg: 'HS256' }, @encode.send(:header_fields))

#     # user_idがnilの場合、暗号メソッドはnilを返しているか
#     user_id = nil
#     assert_nil @encode.send(:encrypt_for, user_id)

#     # user_idがnilの場合、複合メソッドはnilを返しているか
#     assert_nil @encode.send(:decrypt_for, user_id)

#     # user_idが不正な場合、複合メソッドはnilを返しているか
#     user_id = 'aaaaaa'
#     assert_nil @encode.send(:decrypt_for, user_id)
#   end

#   # エンコード検証
#   test 'encode_token' do
#     # トークン有効期限は期待される時間と同じか(1秒許容)
#     expect_lifetime = @lifetime.from_now.to_i
#     assert_in_delta expect_lifetime,
#                     @encode.send(:token_expiration),
#                     1.second

#     # 発行時の@payloadは想定通りか
#     payload = @encode.payload
#     user_claim = @encode.send(:user_claim)
#     assert_equal expect_lifetime, payload[:exp]
#     assert_equal @encode.user_id, payload[user_claim]
#     assert_equal UserAuth.token_issuer, payload[:iss]
#     assert_equal UserAuth.token_audience, payload[:aud]

#     # lifetime_textメ���ッドは想定通りか
#     assert_equal '30分', @encode.lifetime_text

#     # lifetimeキーがある場合、claimsの値が変わっているか
#     time = 1
#     lifetime = time.hour
#     payload = { lifetime: }
#     encode = UserAuth::AccessToken.new(user_id: @user.id, payload:)
#     claims = encode.send(:claims)
#     expect_lifetime = lifetime.from_now.to_i
#     assert_equal expect_lifetime, claims[:exp]

#     # lifetime_textは想定通りか
#     assert_equal "#{time}時間", encode.lifetime_text
#   end

#   # デコード検証
#   test 'decode_token' do
#     decode = UserAuth::AccessToken.new(token: @encode.token)
#     payload = decode.payload

#     # デコードユーザーは一致しているか
#     token_user = decode.entity_for_user
#     assert_equal @user, token_user

#     # verify_claimsは想定通りか
#     verify_claims = decode.send(:verify_claims)
#     assert_equal UserAuth.token_issuer, verify_claims[:iss]
#     assert_equal UserAuth.token_audience, verify_claims[:aud]
#     assert_equal UserAuth.token_signature_algorithm,
#                  verify_claims[:algorithm]
#     assert verify_claims[:verify_expiration]
#     assert verify_claims[:verify_iss]
#     assert verify_claims[:verify_aud]
#     assert_not verify_claims[:sub]
#     assert_not verify_claims[:verify_sub]

#     # 有効期限内はエラーを吐いていないか
#     travel_to(@lifetime.from_now - 1.second) do
#       assert UserAuth::AccessToken.new(token: @encode.token)
#     end

#     # 有効期限後トークン��エラーを吐いているか
#     travel_to(@lifetime.from_now) do
#       assert_raises JWT::ExpiredSignature do
#         UserAuth::AccessToken.new(token: @encode.token)
#       end
#     end

#     # トークンが書き換えられた場合エラーを吐いているか
#     invalid_token = @encode.token + 'a'
#     assert_raises JWT::VerificationError do
#       UserAuth::AccessToken.new(token: invalid_token)
#     end

#     # issuerが改ざんされたtoken����エラーを吐いているか
#     invalid_token = UserAuth::AccessToken.new(payload: { iss: 'invalid' }).token
#     assert_raises JWT::InvalidIssuerError do
#       UserAuth::AccessToken.new(token: invalid_token)
#     end

#     # audienceが改ざんされたtokenはエラーを吐いているか
#     invalid_token = UserAuth::AccessToken.new(payload: { aud: 'invalid' }).token
#     assert_raises JWT::InvalidAudError do
#       UserAuth::AccessToken.new(token: invalid_token)
#     end
#   end

#   # デコードオプション
#   test 'verify_claims' do
#     # subオプションは有効か
#     sub = @encode.user_id
#     options = { sub: }
#     decode = UserAuth::AccessToken.new(token: @encode.token, options:)
#     verify_claims = decode.send(:verify_claims)
#     assert_equal sub, verify_claims[:sub]
#     assert verify_claims[:verify_sub]

#     # subオプシ���ンで有効なユーザーは返ってきているか
#     token_user = decode.entity_for_user
#     assert_equal @user, token_user

#     # 不正なsubにはエラーを吐いているか
#     options = { sub: 'invalid' }
#     assert_raises JWT::InvalidSubError do
#       UserAuth::AccessToken.new(token: @encode.token, options:)
#     end
#   end

#   # not activeユーザーの挙動
#   test 'not_active_user' do
#     not_active = User.create(
#       name: 'a', email: 'a@a.a', password: 'password'
#     )
#     assert_not not_active.activated
#     encode_token = UserAuth::AccessToken.new(user_id: not_active.id).token

#     # アクティブではないユーザも取得できているか
#     decode_token_user = UserAuth::AccessToken.new(token: encode_token).entity_for_user

#     assert_equal not_active, decode_token_user
#   end
# end
