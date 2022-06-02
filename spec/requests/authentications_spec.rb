# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentications', type: :request do
  describe 'GET /authentications' do
    let(:user) { active_user }
    let(:params) { { auth: { email: user.email, password: 'password' } } }
    let(:access_lifetime) { UserAuth.access_token_lifetime }
    let(:session_key) { UserAuth.session_key.to_s }
    let(:access_token_key) { 'token' }
    let(:access_token) { res_body[access_token_key] }
    let(:invalid_token) { "a.#{access_token}" }

    context '認証メソッドテスト' do
      before do
        login params
      end

      it '有効なtokenでアクセスできているか' do
        projects_api(access_token)
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_present
      end

      it '有効期限切れは401が返っているか' do
        travel_to(access_lifetime.from_now) do
          expect(cookies[session_key]).not_to be_blank
          projects_api(access_token)
          expect(response).to have_http_status(:unauthorized)
          expect(response.body).not_to be_present
          expect(cookies[session_key]).to be_blank
        end
      end

      it '不正なtokenが投げられた場合' do
        projects_api(invalid_token)
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).not_to be_present
      end
    end
    # it 'works! (now write some real specs)' do
    #   get authentications_path
    #   expect(response).to have_http_status(200)
    # end
  end
end

#   # 認証メソッドテスト
#   test "authenticate_user_method" do
#     login(@params)
#     access_token = res_body[@access_token_key]

#     # 有効なtokenでアクセスできているか
#     projects_api(access_token)
#     assert_response 200
#     assert response.body.present?

#     # 有効期限切れは401が返っているか
#     travel_to (@access_lifetime.from_now) do
#       # アクセス前のcookieは存在するか
#       assert_not cookies[@session_key].blank?

#       # レスポンスは想定通りか
#       projects_api(access_token)
#       assert_response 401
#       assert_not response.body.present?

#       # cookieは削除されているか
#       assert cookies[@session_key].blank?
#     end

#     # 不正なtokenが投げられた場合
#     invalid_token = "a." + access_token
#     projects_api(invalid_token)

#     assert_response 401
#     assert_not response.body.present?
#   end
# end
