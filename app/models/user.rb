# frozen_string_literal: true

require 'validator/email_validator'

# Userモデル
class User < ApplicationRecord
  include TokenGenerateService
  before_validation :downcase_email

  # gem bcrypt
  # 1. passwordを暗号化する
  # 2. password_digest => password
  # 3. password_confirmation という仮想属性が使える => パスワードの一致確認
  # 4. 一致のバリデーション追加
  # 5. authenticate()
  # 6. 最大文字数 72文字まで
  # 7. User.create() => 入力必須バリデーション, User.update() => X
  has_secure_password

  # validates
  validates :name, presence: true, # 入力必須
                   length: {
                     maximum: 30, # 最大文字数
                     allow_blank: true # nil, 空白文字の場合スキップ
                   }

  validates :email, presence: true, email: { allow_blank: true }

  # \A          => 文字列の先頭にマッチ
  # [\w\-]      => a-zA-Z0-9_-
  # +           => 1文字以上繰り返す
  # \z          => 文字列の末尾にマッチ
  VALID_PASSWORD_REGEX = /\A[\w\-]+\z/
  validates :password, presence: true,
                       length: { minimum: 8, allow_blank: true },
                       format: {
                         with: VALID_PASSWORD_REGEX,
                         message: :invalid_password,
                         allow_blank: true
                       },
                       allow_nil: true # nilの場合スキップ

  ## methods
  # class method  ###########################
  class << self
    # emailからアクティブなユーザーを返す
    def find_by_activated(email)
      find_by(email:, activated: true)
    end
  end
  # class method end #########################

  # 自分以外の同じemailのアクティブなユーザーがいる場合にtrueを返す
  def email_activated?
    users = User.where.not(id:)
    users.find_by_activated(email).present?
  end

  # リフレッシュトークンのJWT IDを記憶する
  def remember(jti)
    update!(refresh_jti: jti)
  end

  # リフレッシュトークンのJWT IDを削除する
  def forget
    update!(refresh_jti: nil)
  end

  # 共通のJSONレスポンス
  def response_json(payload = {})
    as_json(only: %i[id name]).merge(payload).with_indifferent_access
  end

  private

  # email小文字化
  def downcase_email
    email&.downcase!
  end
end
