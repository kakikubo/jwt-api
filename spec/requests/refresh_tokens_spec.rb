# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'RefreshTokens' do
  let!(:user) { active_user }
  let!(:encode) { UserAuth::RefreshToken.new(user_id: user.id) }
  let!(:lifetime) { UserAuth.refresh_token_lifetime }
  let!(:payload) { encode.payload }
  let!(:decode) { UserAuth::RefreshToken.new(token: encode.token) }

  describe 'トークンのエンコード' do
    it 'payload[:exp]の値は想定通りか(1秒許容)' do
      expect_lifetime = lifetime.from_now.to_i
      # assert_in_delta expect_lifetime, payload[:exp], 1.second
      expect(expect_lifetime).to be_within(1.seconds).of(payload[:exp])
    end

    it 'payload[:jti]の値は想定通りか' do
      encode_user = encode.entity_for_user
      expect_jti = encode_user.refresh_jti
      expect(expect_jti).to eq(payload[:jti])
    end

    it 'payload[:sub]の値は想定通りか' do
      user_claim = encode.send(:user_claim)
      expect(encode.user_id).to eq(payload[user_claim])
    end
  end

  describe 'トークンのデコード' do
    before do
      user.reload
    end

    it 'デコードユーザーは一致しているか' do
      expect(decode.entity_for_user).to eq(user)
    end

    it 'verify_claimsは想定通りか' do
      verify_claims = decode.send(:verify_claims)
      expect(verify_claims[:verify_expiration]).to be_truthy
    end

    it 'verify_claimsのsignature_algorithmは想定通りか' do
      verify_claims = decode.send(:verify_claims)
      expect(UserAuth.token_signature_algorithm).to eq(verify_claims[:algorithm])
    end

    it '有効期限後トークンはエラーを吐いているか' do
      travel_to(lifetime.from_now) do
        expect { UserAuth::RefreshToken.new(token: encode.token) }.to raise_error(JWT::ExpiredSignature)
      end
    end

    it 'トークンが書き換えられた場合エラーを吐いているか' do
      invalid_token = "#{encode.token}a"
      expect { UserAuth::RefreshToken.new(token: invalid_token) }.to raise_error(JWT::VerificationError)
    end
  end

  describe 'デコードオプション' do
    before do
      user.reload
    end

    it 'verify claims' do
      expect(user.refresh_jti).to eq(encode.payload[:jti])
    end

    it 'userのjtiが正常の場合' do
      expect(UserAuth::RefreshToken.new(token: encode.token)).to be_truthy
    end

    it 'userのjtiが不正の場合' do
      user.remember('invalid')
      expect { UserAuth::RefreshToken.new(token: encode.token) }.to raise_error(JWT::InvalidJtiError, 'Invalid jti')
    end

    it 'userにjtiが存在しない場合' do
      user.forget
      user.reload
      expect(user.refresh_jti).to be_nil
    end

    it 'userにjtiが存在しない場合エラーになる' do
      user.forget
      user.reload
      expect { UserAuth::RefreshToken.new(token: encode.token) }.to raise_error(JWT::InvalidJtiError)
    end
  end
end
