# frozen_string_literal: true

# トークン生成サービス
module TokenGenerateService
  # include時の初期化処理実行場所(include先のオブジェクト)
  def self.included(base)
    # include時にクラスメソッドを追加する
    base.extend ClassMethods
  end

  ## クラスメソッド
  module ClassMethods
    # アクセストークンのインスタンス生成(オプション => sub: encrypt user id)
    def decode_access_token(token, options = {})
      UserAuth::AccessToken.new(token:, options:)
    end

    # アクセストークンのuserを返す
    def from_access_token(token, options = {})
      decode_access_token(token, options).entity_for_user
    end

    # リフレッシュトークンのインスタンス生成
    def decode_refresh_token(token)
      UserAuth::RefreshToken.new(token:)
    end

    # リフレッシュトークンのuserを返す
    def from_refresh_token(token)
      decode_refresh_token(token).entity_for_user
    end
  end

  ## インスタンスメソッド

  # アクセストークンのインスタンス生成
  def encode_access_token(payload = {})
    UserAuth::AccessToken.new(user_id: id, payload:)
  end

  # アクセストークンを返す(期限変更 => lifetime: 10.minute)
  def to_access_token(payload = {})
    encode_access_token(payload).token
  end

  # リフレッシュトークンのインスタンス生成
  def encode_refresh_token
    UserAuth::RefreshToken.new(user_id: id)
  end

  # リフレッシュトークンを返す
  def to_refresh_token
    encode_refresh_token.token
  end
end
