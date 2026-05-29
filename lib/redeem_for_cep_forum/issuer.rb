# frozen_string_literal: true

require "net/http"
require "json"

module ::RedeemForCepForum
  class Issuer
    Result = Struct.new(:success?, :code, :error, keyword_init: true)

    TIMEOUT_SECONDS = 10
    RETRY_DELAY_SECONDS = 2

    def initialize(api_url: SiteSetting.cep_redeem_api_url, client_secret: SiteSetting.cep_redeem_client_secret)
      @api_url = api_url
      @client_secret = client_secret
    end

    def issue(cep_user_id:, trial_days:)
      return failure("missing_client_secret") if @client_secret.blank?
      return failure("invalid_days") unless valid_trial_days?(trial_days)

      attempts = 0

      begin
        attempts += 1
        response = perform_request(cep_user_id:, trial_days:)
        parse_response(response)
      rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET => e
        if attempts < 2
          sleep RETRY_DELAY_SECONDS
          retry
        end

        Rails.logger.warn("[redeem-for-cep-forum] CEP redeem network error: #{e.class.name}")
        failure("network_error")
      rescue JSON::ParserError
        failure("invalid_response")
      end
    end

    private

    def valid_trial_days?(trial_days)
      trial_days.is_a?(Integer) && trial_days.between?(1, 30)
    end

    def perform_request(cep_user_id:, trial_days:)
      uri = URI.parse(@api_url)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body =
        JSON.generate(
          client_id: RewardRegistry::CLIENT_ID,
          client_secret: @client_secret,
          user_id: cep_user_id,
          trial_days: trial_days,
        )

      Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: TIMEOUT_SECONDS,
        read_timeout: TIMEOUT_SECONDS,
      ) { |http| http.request(request) }
    end

    def parse_response(response)
      payload = response.body.present? ? JSON.parse(response.body) : {}

      if response.code.to_i == 200 && payload["code"].present?
        Result.new(success?: true, code: payload["code"])
      else
        failure(payload["error"].presence || "cep_api_error")
      end
    end

    def failure(error)
      Result.new(success?: false, error: error)
    end
  end
end
