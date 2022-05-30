# frozen_string_literal: true

require 'rails_helper'

# テスト成功要件
# cookies[]の操作にはapplication.rbにCookieを処理するmiddlewareを追加
# config.middleware.use ActionDispatch::Cookies

RSpec.describe 'Api::V1::AuthTokens', type: :request do
  let!(:user) { active_user }
  let!(:params) { { auth: { email: user.email, password: 'password' } } }
  let!(:access_lifetime) { UserAuth.access_token_lifetime }
  let!(:refresh_lifetime) { UserAuth.refresh_token_lifetime }
  let!(:session_key) { UserAuth.session_key.to_s }
  let!(:access_token_key) { 'token' }

  shared_context :response_check_of_invalid_request do |status, error_msg = nil|
  end
  # # tokenのリフレッシュを行うapi
  # def refresh_api
  #   post api('/auth_token/refresh'), xhr: true
  # end

  # 無効なリクエストで返ってくるレスポンスチェック
  def response_check_of_invalid_request(status, error_msg = nil)
    expect(response.status).to eq(status)
    user.reload
    expect(user.refresh_jti).to eq(nil)
    expect(response.body.present?).not_to be_truthy if error_msg.nil?
    expect(error_msg).to eq(res_body['error']) unless error_msg.nil?
  end

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
        expect(user.refresh_jti).not_to be(nil)
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
    context 'invalid_login_from_create_action' do
      let(:pass) { 'password' }
      let(:invalid_params) { { auth: { email: user.email, password: pass + 'a' } } }

      before { login invalid_params }

      it '不正なユーザの場合' do
        response_check_of_invalid_request 404
      end
    end
  end
  # # 無効なログイン
  # test 'invalid_login_from_create_action' do
  #   # 不正なユーザーの場合
  #   pass = 'password'
  #   invalid_params = { auth: { email: @user.email, password: pass + 'a' } }
  #   login(invalid_params)
  #   response_check_of_invalid_request 404

  #   # アクティブユーザーでない場合
  #   inactive_user = User.create(name: 'a', email: 'a@a.a', password: pass)
  #   invalid_params = { auth: { email: inactive_user.email, password: pass } }
  #   assert_not inactive_user.activated
  #   login(invalid_params)
  #   response_check_of_invalid_request 404

  #   # Ajax通���ではない場合
  #   post api('/auth_token'), xhr: false, params: @params
  #   response_check_of_invalid_request 403, 'Forbidden'
  # end

  # # 有効なリフレッシュ
  # test 'valid_refresh_from_refresh_action' do
  #   # 有効なログイン
  #   login(@params)
  #   assert_response 200
  #   @user.reload
  #   old_access_token = res_body[@access_token_key]
  #   old_refresh_token = cookies[@session_key]
  #   old_user_jti = @user.refresh_jti

  #   # nilでないか
  #   assert_not_nil old_access_token
  #   assert_not_nil old_refresh_token
  #   assert_not_nil old_user_jti

  #   # refreshアクションにアクセス
  #   refresh_api
  #   assert_response 200
  #   @user.reload
  #   new_access_token = res_body[@access_token_key]
  #   new_refresh_token = cookies[@session_key]
  #   new_user_jti = @user.refresh_jti

  #   # nilでないか
  #   assert_not_nil new_access_token
  #   assert_not_nil new_refresh_token
  #   assert_not_nil new_user_jti

  #   # tokenとjtiが新しく発行されているか
  #   assert_not_equal old_access_token, new_access_token
  #   assert_not_equal old_refresh_token, new_refresh_token
  #   assert_not_equal old_user_jti, new_user_jti

  #   # user.refresh_jtiは最新のjtiと一致しているか
  #   payload = User.decode_refresh_token(new_refresh_token).payload
  #   assert_equal payload['jti'], new_user_jti
  # end

  # # 無効なリフレッシュ
  # test 'invalid_refresh_from_refresh_action' do
  #   # refresh_tokenが存在しない場合はアク��スできないか
  #   refresh_api
  #   response_check_of_invalid_request 401

  #   ## ユーザーが2回のログインを行なった場合
  #   # 1つ目のブラウザでログイン
  #   login(@params)
  #   assert_response 200
  #   old_refresh_token = cookies[@session_key]

  #   # 2つ目のブラウザでログイン
  #   login(@params)
  #   assert_response 200
  #   new_refresh_token = cookies[@session_key]

  #   # cookieに古いrefresh_token���セ���ト
  #   cookies[@session_key] = old_refresh_token
  #   assert_not cookies[@session_key].blank?

  #   # 1つ目のブラウザ(古いrefresh_token)��アクセスするとエラーを吐いて���るか
  #   refresh_api
  #   assert_response 401

  #   # cookieは削除されているか
  #   assert cookies[@session_key].blank?

  #   # jtiエラーはカスタムメッセージを吐いている��
  #   assert_equal 'Invalid jti for refresh token', res_body['error']

  #   # 有効期限後はアクセスできないか
  #   travel_to(@refresh_lifetime.from_now) do
  #     refresh_api
  #     assert_response 401
  #     assert_not response.body.present?
  #   end
  # end

  # # ログアウト
  # test 'destroy_action' do
  #   # 有効なログイン
  #   login(@params)
  #   assert_response 200
  #   @user.reload
  #   assert_not_nil @user.refresh_jti
  #   assert_not_nil @request.cookie_jar[@session_key]

  #   # 有効なログアウト
  #   assert_not cookies[@session_key].blank?
  #   logout
  #   assert_response 200

  #   # cookieは削除されているか
  #   assert cookies[@session_key].blank?

  #   # userのjtiは削除できているか
  #   @user.reload
  #   assert_nil @user.refresh_jti

  #   # sessionがない状態でログアウトしたらエラーは返ってくるか
  #   cookies[@session_key] = nil
  #   logout
  #   response_check_of_invalid_request 401

  #   # 有効なログイン
  #   login(@params)
  #   assert_response 200
  #   assert_not cookies[@session_key].blank?

  #   # session有効期限後にログアウトしたらエラーは返ってくるか
  #   travel_to(@refresh_lifetime.from_now) do
  #     logout
  #     assert_response 401
  #     # cookieは削除されているか
  #     assert cookies[@session_key].blank?
  #   end
  # end
end
