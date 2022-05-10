# frozen_string_literal: true

module Api
  module V1
    # ユーザ一覧を返すコントローラ
    class UsersController < ApplicationController
      def index
        users = User.all
        # as_json => ハッシュの形でJSONデータを返す { "id" => 1, "name" => "test", ...}
        render json: users.as_json(only: %i[id name email created_at])
      end
    end
  end
end
