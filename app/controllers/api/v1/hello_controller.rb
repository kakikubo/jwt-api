# frozen_string_literal: true

module Api
  module V1
    # Hello controller API v1
    class HelloController < ApplicationController
      def index
        render json: 'Hello'
      end
    end
  end
end
