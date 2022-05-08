# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Hellos', type: :request do
  describe 'GET /index' do
    # pending "add some examples (or delete) #{__FILE__}"
    context 'valid response' do
      before { get api_v1_hello_index_path }
      it '200' do
        expect(response).to have_http_status(:ok)
      end
      it 'response Hello' do
        binding.break
        expect(response.body).to eq('Hello')
      end
    end
  end
end
