# frozen_string_literal: true

# JWT IDのリフレッシュカラムをユーザテーブルに追加する
class AddRefreshJtiToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :refresh_jti, :string
  end
end
