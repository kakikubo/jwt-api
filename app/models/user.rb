# frozen_string_literal: true

class User < ApplicationRecord
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
  # \A          => 文字列の先頭にマッチ
  # [\w\-]      => a-zA-Z0-9_-
  # +           => 1文字以上繰り返す
  # \z          => 文字列の末尾にマッチ
  VALID_PASSWORD_REGEX = /\A[\w\-]+\z/
  validates :password, presence: true,
                       length: { minimum: 8, allow_blank: true },
                       format: {
                         with: VALID_PASSWORD_REGEX,
                         allow_blank: true
                       },
                       allow_nil: true   # nilの場合スキップ
end
