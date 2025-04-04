# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV['API_DOMAIN'] || 'localhost:3000'

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true
    # Nuxtからは `XMLHttpRequest.withCredentials: true`が送信される
    # credentials: trueを設定する事で `Access-Control-Allow-Credentials: true` をセットしてNuxtへ返す
  end
end
