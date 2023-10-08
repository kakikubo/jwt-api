# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentications' do
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

      context 'tokenが有効期限切れのとき' do
        before do
          travel_to(access_lifetime.from_now)
        end

        it 'セッションキーがあるか' do
          expect(cookies[session_key]).not_to be_blank
        end

        it '有効期限切れは401が返っているか' do
          projects_api(access_token)
          expect(response).to have_http_status(:unauthorized)
        end

        it '有効期限切れはbodyがない' do
          projects_api(access_token)
          expect(response.body).not_to be_present
        end

        it '有効期限切れはセッションキーがないか' do
          projects_api(access_token)
          expect(cookies[session_key]).to be_blank
        end
      end

      it '不正なtokenが投げられた場合に認証エラーになっている' do
        projects_api(invalid_token)
        expect(response).to have_http_status(:unauthorized)
      end

      it '不正なtokenが投げられた場合にbodyがない' do
        projects_api(invalid_token)
        expect(response.body).not_to be_present
      end
    end
    # it 'works! (now write some real specs)' do
    #   get authentications_path
    #   expect(response).to have_http_status(200)
    # end
  end
end
