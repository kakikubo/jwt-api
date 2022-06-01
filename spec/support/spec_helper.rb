# frozen_string_literal: true

# https://breakthrough-tech.yuta-u.com/rspec/how-to-make-spec-support/
module SpecHelpers
  def active_user
    User.find_by(activated: true)
  end

  # api path
  def api(path = '/')
    "/api/v1#{path}"
  end

  # 認可ヘッダ
  def auth(token)
    { Authorization: "Bearer #{token}" }
  end

  # 引数のparamsでログインを行う
  def login(params)
    post api('/auth_token'), xhr: true, params:
  end

  # ログアウトapi
  def logout
    delete api('/auth_token'), xhr: true
  end

  # レスポンスJSONをハッシュで返す
  def res_body
    JSON.parse(@response.body)
  end

  # tokenのリフレッシュを行うapi
  def refresh_api
    post api('/auth_token/refresh'), xhr: true
  end

  # プロジェクトapi
  def projects_api(token)
    get api('/projects'), xhr: true, headers: auth(token)
  end
end
