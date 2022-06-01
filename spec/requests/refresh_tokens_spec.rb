# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'RefreshTokens', type: :request do
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
      expect(user.refresh_jti).to eq(nil)
      expect { UserAuth::RefreshToken.new(token: encode.token) }.to raise_error(JWT::InvalidJtiError)
    end
  end
end
# # api/test/integration/refresh_token_test.rb
# require 'test_helper'

# class RefreshTokenTest < ActionDispatch::IntegrationTest
#   def setup
#     @user = active_user
#     @encode = UserAuth::RefreshToken.new(user_id: @user.id)
#     @lifetime = UserAuth.refresh_token_lifetime
#   end

#   # エンコード
#   test 'encode_token' do
#     # payload[:exp]の値は想定通りか(1秒許容)
#     payload = @encode.payload
#     expect_lifetime = @lifetime.from_now.to_i
#     assert_in_delta expect_lifetime, payload[:exp], 1.second

#     # payload[:jti]の値は想定通りか
#     encode_user = @encode.entity_for_user
#     expect_jti = encode_user.refresh_jti
#     assert_equal expect_jti, payload[:jti]

#     # payload[:sub]の値は想定通りか
#     user_claim = @encode.send(:user_claim)
#     assert_equal @encode.user_id, payload[user_claim]
#   end

#   # デコード
#   test 'decode_token' do
#     decode = UserAuth::RefreshToken.new(token: @encode.token)
#     payload = decode.payload

#     # デコードユーザーは一致しているか
#     token_user = decode.entity_for_user
#     assert_equal @user, token_user

#     # verify_claimsは想定通りか
#     verify_claims = decode.send(:verify_claims)
#     assert verify_claims[:verify_expiration]
#     assert_equal UserAuth.token_signature_algorithm,
#                  verify_claims[:algorithm]

#     # 有効期限後トークンはエラーを吐いているか
#     travel_to(@lifetime.from_now) do
#       assert_raises JWT::ExpiredSignature do
#         UserAuth::RefreshToken.new(token: @encode.token)
#       end
#     end

#     # トークンが書き換えられた場合エラーを吐いているか
#     invalid_token = @encode.token + 'a'
#     assert_raises JWT::VerificationError do
#       UserAuth::RefreshToken.new(token: invalid_token)
#     end
#   end

#   # デコードオプション
#   test 'verify_claims' do
#     @user.reload
#     assert_equal @user.refresh_jti, @encode.payload[:jti]

#     # userのjtiが正常の場合
#     assert UserAuth::RefreshToken.new(token: @encode.token)

#     # userのjtiが不正な場合
#     @user.remember('invalid')
#     e = assert_raises JWT::InvalidJtiError do
#       UserAuth::RefreshToken.new(token: @encode.token)
#     end
#     # エラーメッセージをtestする場合
#     assert_equal 'Invalid jti', e.message

#     # userにjtiが存在しない場合
#     @user.forget
#     @user.reload
#     assert_nil @user.refresh_jti
#     assert_raises JWT::InvalidJtiError do
#       UserAuth::RefreshToken.new(token: @encode.token)
#     end
#   end
# end
