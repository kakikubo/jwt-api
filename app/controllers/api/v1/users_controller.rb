class Api::V1::UsersController < ApplicationController
  def index
    users = User.all
    # as_json => ハッシュの形でJSONデータを返す { "id" => 1, "name" => "test", ...}
    render json: users.as_json(only: %i[id name email created_at])
  end
end
