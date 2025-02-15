# frozen_string_literal: true

module Api
  module V1
    # プロジェクト一覧を表示するコントローラ
    class ProjectsController < ApplicationController
      before_action :authenticate_active_user

      def index
        projects = []
        date = Date.new(2021, 4, 1)
        10.times do |n|
          id = n + 1
          name = "#{current_user.name} project #{id.to_s.rjust(2, '0')}"
          updated_at = date + (id * 6).hours
          projects << { id:, name:, updatedAt: updated_at }
        end
        # 本来はcurrent_user.projects
        render json: projects
      end
    end
  end
end
