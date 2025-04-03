# frozen_string_literal: true

# 共通のコントローラ
class ApplicationController < ActionController::API
  # 301リダイレクト(本番環境のみ有効)
  before_action :moved_permanently, if: :redirect?
  # Cookieを扱う
  include ActionController::Cookies
  # 認可を行う
  include UserAuthenticateService

  # CSRF対策
  before_action :xhr_request?

  private

  # XMLHttpRequestでない場合は403エラーを返す
  def xhr_request?
    # リクエストヘッダ X-Requested-With: 'XMLHttpRequest' の存在を判定
    return false if request.xhr?

    render status: :forbidden, json: { status: 403, error: 'Forbidden' }
  end

  # Internal Server Error
  def response_500(msg = 'Internal Server Error')
    render status: 500, json: { status: 500, error: msg }
  end

  # リダイレクト条件に一致した場合はtrueを返す
  def redirect?
    redirect_domain = 'herokuapp.com'
    Rails.env.production? && ENV.fetch('BASE_URL', nil) && request.host.include?(redirect_domain)
  end

  # 301リダイレクトを行う
  def moved_permanently
    redirect_to "#{ENV.fetch('BASE_URL', nil)}#{request.path}", status: 301
  end
end
