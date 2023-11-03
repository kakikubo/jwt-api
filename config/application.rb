# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  # Rails Applicationの基本設定
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Railsアプリのタイムゾーン(default 'UTC')
    # TimeZoneList: http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html
    config.time_zone = ENV.fetch('TZ', nil)
    # データベースの読み書きに使用するタイムゾーン(:local | :utc(default))
    config.active_record.default_timezone = :utc
    # i18nで使われるデフォルトのロケールファイルの指定(default :en)
    config.i18n.default_locale = :ja
    # $LOAD_PATHにautoload pathを追加しない(Zeitwerk有効時false推奨)
    # Rails.autoloaders.zeitwerk_enabled? でZeitwerkが有効になっているかどうかを確認できます。
    config.add_autoload_paths_to_load_path = false

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # cookies[]の操作にはapplication.rbにCookieを処理するmiddlewareを追加
    config.middleware.use ActionDispatch::Cookies

    # Cookieのsamesite属性を変更する(Rails v6.1〜, :strict, :lax, :none)
    config.action_dispatch.cookies_same_site_protection = ENV['COOKIES_SAME_SITE'].to_sym if Rails.env.production?
  end
end
