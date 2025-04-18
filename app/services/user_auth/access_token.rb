# frozen_string_literal: true

require 'jwt'

module UserAuth
  # アクセストークンを扱う共通クラス
  class AccessToken
    include TokenCommons

    attr_reader :user_id, :payload, :lifetime, :token, :options

    # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    def initialize(user_id: nil, payload: {}, token: nil, options: {})
      if token.present?
        # decode
        @token = token
        @options = options
        @payload = JWT.decode(@token.to_s, decode_key, true, verify_claims.merge(@options)).first
        @user_id = get_user_id_from(@payload)
      else
        # encode
        @user_id = encrypt_for(user_id)
        @lifetime = payload[:lifetime] || UserAuth.access_token_lifetime
        @payload = claims.merge(payload.except(:lifetime))
        @token = JWT.encode(@payload, secret_key, algorithm, header_fields)
      end
    end
    # rubocop:enable Metrics/AbcSize,Metrics/MethodLength

    # 暗号化された@user_idからユーザーを取得する
    def entity_for_user
      User.find(decrypt_for(@user_id))
    end

    # @lifetimeの日本語テキストを返す
    def lifetime_text
      time, period = @lifetime.inspect.sub(/s\z/, '').split
      time + I18n.t("datetime.periods.#{period}", default: '')
    end

    private

    ## エンコードメソッド

    # issuerの値がある場合にtrueを返す
    def verify_issuer?
      UserAuth.token_issuer.present?
    end

    # issuerを返す
    def token_issuer
      verify_issuer? && UserAuth.token_issuer
    end

    # audienceの値がある場合にtrueを返す
    def verify_audience?
      UserAuth.token_audience.present?
    end

    # audienceを返す
    def token_audience
      verify_audience? && UserAuth.token_audience
    end

    # user_idの値がある場合にtrueを返す
    def verify_user_id?
      @user_id.present?
    end

    # 有効期限をUnixtimeで返す(必須)
    def token_expiration
      @lifetime.from_now.to_i
    end

    # エンコード時のデフォルトクレーム

    # rubocop:disable Lint/UnderscorePrefixedVariableName
    def claims
      _claims = {}
      _claims[:exp] = token_expiration
      _claims[user_claim] = @user_id if verify_user_id?
      _claims[:iss] = token_issuer if verify_issuer?
      _claims[:aud] = token_audience if verify_audience?
      _claims
    end
    # rubocop:enable Lint/UnderscorePrefixedVariableName

    ## デコードメソッド

    # @optionsにsubjectがある場合にtrueを返す
    def verify_subject?
      @options.key?(:sub)
    end

    # @optionsのsubの値を返す
    def token_subject
      verify_subject? && @options[:sub]
    end

    # デコード時のデフォルトオプション
    # Doc: https://github.com/jwt/ruby-jwt
    # default: https://www.rubydoc.info/github/jwt/ruby-jwt/master/JWT/DefaultOptions
    def verify_claims
      {
        iss: token_issuer,
        aud: token_audience,
        sub: token_subject,
        verify_expiration: true,      # 有効期限の検証するか(必須)
        verify_iss: verify_issuer?,   # payloadとissの一致を検証するか
        verify_aud: verify_audience?, # payloadとaudの一致を検証するか
        verify_sub: verify_subject?,  # payloadとsubの一致を検証するか
        algorithm: # decode時のアルゴリズム
      }
    end
  end
end
