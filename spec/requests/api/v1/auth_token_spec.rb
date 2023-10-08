# frozen_string_literal: true

require 'rails_helper'

# テスト成功要件
# cookies[]の操作にはapplication.rbにCookieを処理するmiddlewareを追加
# config.middleware.use ActionDispatch::Cookies

RSpec.describe 'Api::V1::AuthTokens' do
  let!(:user) { active_user }
  let!(:params) { { auth: { email: user.email, password: 'password' } } }
  let!(:access_lifetime) { UserAuth.access_token_lifetime }
  let!(:refresh_lifetime) { UserAuth.refresh_token_lifetime }
  let!(:session_key) { UserAuth.session_key.to_s }
  let!(:access_token_key) { 'token' }

  # rubocop:disable Metrics/AbcSize
  shared_context 'response check of invalid request' do |status, error_msg = nil|
  end

  # 無効なリクエストで返ってくるレスポンスチェック
  def response_check_of_invalid_request(status, error_msg = nil)
    expect(response.status).to eq(status)
    user.reload
    expect(user.refresh_jti).to be_nil
    expect(response.body).not_to be_present if error_msg.nil?
    expect(error_msg).to eq(res_body['error']) unless error_msg.nil?
  end
  # rubocop:enable Metrics/AbcSize

  describe '有効なログイン' do
    context 'valid_login_from_create_action' do
      let(:access_token) { User.decode_access_token(res_body[access_token_key]) }
      let(:access_lifetime_to_i) { access_lifetime.from_now.to_i }
      let(:refresh_lifetime_to_i) { refresh_lifetime.from_now.to_i }
      let(:token_exp) { access_token.payload['exp'] }
      # cookieのオプションを取得する場合は下記を使用
      let(:cookie) { request.cookie_jar.instance_variable_get(:@set_cookies)[session_key] }
      # refresh token
      let(:token_from_cookies) { cookies[session_key] }
      let(:refresh_token) { User.decode_refresh_token(token_from_cookies) }

      before do
        login params
      end

      it 'レスポンスが正常か' do
        expect(response).to have_http_status(:ok)
      end

      it 'jtiは保存されているか' do
        user.reload
        expect(user.refresh_jti).not_to be_nil
      end

      it 'レスポンスユーザは正しいか' do
        expect(res_body['user']['id']).to eq(user.id)
      end

      it 'レスポンス有効期限は想定通りか(1誤差許容)' do
        expect(res_body['expires']).to be_within(1.seconds).of(access_lifetime_to_i)
      end

      it 'ユーザーはログイン本人と一致しているか' do
        expect(access_token.entity_for_user).to eq(user)
      end

      it '有効期限はレスポンスと一致しているか' do
        expect(token_exp).to eq(res_body['expires'])
      end

      it 'expiresは想定通りか(1秒許容)' do
        expect(cookie[:expires]).to be_within(1.seconds).of(Time.at(refresh_lifetime_to_i))
      end

      it 'secureは一致しているか' do
        # allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        expect(cookie[:secure]).to eq(Rails.env.production?)
      end

      it 'http_onlyはtrueか' do
        expect(cookie[:http_only]).to be_truthy
      end

      context 'リロード' do
        before { user.reload }

        it 'ログイン本人と一致しているか' do
          expect(refresh_token.entity_for_user).to eq(user)
        end

        it 'jtiは一致しているか' do
          expect(refresh_token.payload['jti']).to eq(user.refresh_jti)
        end

        it 'token有効期限とcookie有効期限は一致しているか' do
          expect(refresh_token.payload['exp']).to eq(refresh_lifetime_to_i)
        end
      end
    end
  end

  describe '無効なログイン' do
    let(:pass) { 'password' }

    context '不正なユーザの場合' do
      let(:invalid_params) { { auth: { email: user.email, password: "#{pass}a" } } }

      before { login invalid_params }

      it '404が返される' do
        response_check_of_invalid_request 404
      end
    end

    context 'アクティブユーザでない場合' do
      let(:inactive_user) { User.create(name: 'a', email: 'a@a.a', password: pass) }
      let(:invalid_params) { { auth: { email: inactive_user.email, password: pass } } }

      before { login invalid_params }

      it 'アクティブにはならない' do
        expect(inactive_user.activated).to be_falsy
        response_check_of_invalid_request 404
      end
    end

    context 'Ajax通信でない場合' do
      before do
        post api('/auth_token'), xhr: false, params:
      end

      it '通信が拒否される' do
        response_check_of_invalid_request 403, 'Forbidden'
      end
    end
  end

  describe '有効なリフレッシュ' do
    context '有効なログイン' do
      before do
        login params
        user.reload
        @old_access_token = res_body[access_token_key]
        @old_refresh_token = cookies[session_key]
        @old_user_jti = user.refresh_jti
      end

      it '正常なレスポンスが返る' do
        expect(response).to have_http_status(:ok)
      end

      it 'nilでないか' do
        expect(@old_access_token).not_to be_nil
        expect(@old_refresh_token).not_to be_nil
        expect(@old_user_jti).not_to be_nil
      end

      context 'refreshアクションにアクセス' do
        let(:payload) { User.decode_refresh_token(@new_refresh_token).payload }

        before do
          refresh_api
          user.reload
          @new_access_token = res_body[access_token_key]
          @new_refresh_token = cookies[session_key]
          @new_user_jti = user.refresh_jti
        end

        it '正常なレスポンスが返る' do
          expect(response).to have_http_status(:ok)
        end

        it 'nilでないか' do
          expect(@new_access_token).not_to be_nil
          expect(@new_refresh_token).not_to be_nil
          expect(@new_user_jti).not_to be_nil
        end

        it 'tokenとjtiが新しく発行されているか' do
          expect(@old_access_token).not_to eq @new_access_token
          expect(@old_refresh_token).not_to eq @new_refresh_token
          expect(@old_user_jti).not_to eq @new_user_jti
        end

        it 'user.refresh_jtiは最新のjtiと一致しているか' do
          expect(payload['jti']).to eq @new_user_jti
        end
      end
    end
  end

  describe '無効なリフレッシュ' do
    before do
      refresh_api
    end

    it 'refresh_tokenが存在しない場合はアクセスできないか' do
      response_check_of_invalid_request 401
    end

    context 'ユーザが2回のログインを行った場合' do
      before do
        login params
        @old_refresh_token = cookies[session_key]
        login params
        @new_refresh_token = cookies[session_key]
        cookies[session_key] = @old_refresh_token # 1つ目のブラウザの方で操作をする
      end

      it '1つ目のブラウザの値が入っていること' do
        expect(cookies[session_key]).not_to be_blank
      end

      context '1つ目のブラウザ(古いrefresh_token)でアクセスする' do
        before { refresh_api }

        it '1つ目のブラウザ(古いrefresh_token)でアクセスするとエラーを吐いているか' do
          expect(response).to have_http_status(:unauthorized)
        end

        it 'クッキーが削除されていること' do
          expect(cookies[session_key]).to be_blank
        end

        it 'jtiエラーはカスタムメッセージを吐いているか' do
          expect(res_body['error']).to eq('Invalid jti for refresh token')
        end

        it '有効期限後はアクセスできないか' do
          travel_to(refresh_lifetime.from_now) do
            refresh_api
            expect(response).to have_http_status(:unauthorized)
            expect(response.body).not_to be_present
          end
        end
      end
    end
  end

  describe 'ログアウト' do
    describe 'destroy_action' do
      context '有効なログイン' do
        before { login params }

        it '正常なレスポンスが返される' do
          expect(response).to have_http_status(:ok)
          user.reload
          expect(user.refresh_jti).to be_truthy
          expect(request.cookie_jar[session_key]).to be_truthy
          expect(cookies[session_key]).not_to be_blank
        end

        context '有効なログアウト' do
          before { logout }

          it 'cookieは削除されているか' do
            expect(response).to have_http_status(:ok)
            expect(cookies[session_key]).to be_blank
          end

          it 'userのjtiは削除できているか' do
            user.reload
            expect(user.refresh_jti).to be_nil
          end
        end

        context 'sessionがない状態でログアウト' do
          before do
            cookies[session_key] = nil
            logout
          end

          it 'エラーが返ってくる' do
            expect(response).to have_http_status(:unauthorized)
            # FIXME: response_check_of_invalid_request 401 # L28でエラーになる(refresh_jtiがnilになっていない)
          end
        end
      end

      context '有効なログイン' do
        before { login params }

        it '正常なレスポンスが返される' do
          expect(response).to have_http_status(:ok)
          user.reload
          expect(cookies[session_key]).not_to be_blank
        end

        it 'session有効期限後にログアウトしたらエラーは返ってくるか' do
          travel_to(refresh_lifetime.from_now) do
            logout
            expect(response).to have_http_status(:unauthorized)
            expect(cookies[session_key]).to be_blank
          end
        end
      end
    end
  end
end
