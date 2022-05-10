# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  describe 'GET /index' do
    before { get api_v1_users_path }
    it '200' do
      expect(response).to have_http_status(:ok)
    end
    it 'response json' do
      jsons = JSON.parse(response.body)
      json1 = jsons.first
      expect(json1['id']).to eq(1)
      expect(json1['name']).to eq('user0')
      expect(json1['email']).to eq('user0@example.com')
    end
  end
end
