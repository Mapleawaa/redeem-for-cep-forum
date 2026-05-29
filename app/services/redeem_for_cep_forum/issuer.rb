# frozen_string_literal: true

require "faraday"
require "json"

module RedeemForCepForum
  class Issuer
    class Error < StandardError
      attr_reader :code, :retryable

      def initialize(code, message, retryable: false)
        @code = code
        @retryable = retryable
        super(message)
      end
    end

    MAX_DAYS_PER_CODE = 30
    NETWORK_RETRY_DELAY = 2.seconds

    def initialize(
      client_id: SiteSetting.redeem_for_cep_forum_client_id,
      client_secret: SiteSetting.redeem_for_cep_forum_client_secret,
      issue_url: SiteSetting.redeem_for_cep_forum_issue_url
    )
      @client_id = client_id
      @client_secret = client_secret
      @issue_url = issue_url
    end

    def issue_codes(cep_user_id:, total_days:, already_issued: 0)
      validate_configuration!

      split_days(total_days)
        .drop(already_issued.to_i)
        .map { |days| issue_code(cep_user_id: cep_user_id, trial_days: days) }
    end

    def issue_code(cep_user_id:, trial_days:)
      validate_configuration!

      response =
        with_network_retry do
          connection.post(@issue_url) { |request| build_request(request, cep_user_id, trial_days) }
        end

      handle_response(response)
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      raise Error.new("network_error", e.message, retryable: true)
    rescue JSON::ParserError => e
      raise Error.new("invalid_json", e.message, retryable: true)
    end

    private

    def validate_configuration!
      raise Error.new("missing_client_id", "CEP client_id is not configured") if @client_id.blank?
      if @client_secret.blank?
        raise Error.new("missing_client_secret", "CEP client_secret is not configured")
      end
      raise Error.new("missing_issue_url", "CEP issue URL is not configured") if @issue_url.blank?
    end

    def split_days(total_days)
      remaining = total_days.to_i
      chunks = []

      while remaining.positive?
        days = [remaining, MAX_DAYS_PER_CODE].min
        chunks << days
        remaining -= days
      end

      chunks
    end

    def with_network_retry
      yield
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed
      sleep NETWORK_RETRY_DELAY
      yield
    end

    def connection
      @connection ||=
        Faraday.new(nil, request: { timeout: 10, open_timeout: 10 }) do |builder|
          builder.adapter FinalDestination::FaradayAdapter
        end
    end

    def build_request(request, cep_user_id, trial_days)
      request.headers["Content-Type"] = "application/json"
      request.body =
        {
          client_id: @client_id,
          client_secret: @client_secret,
          user_id: cep_user_id,
          trial_days: trial_days,
        }.to_json
    end

    def handle_response(response)
      body = response.body.present? ? JSON.parse(response.body) : {}

      return body.fetch("code") if response.status == 200 && body["code"].present?

      error_code = body["error"].presence || "http_#{response.status}"
      retryable = response.status == 429 || response.status >= 500

      raise Error.new(error_code, "CEP issue API returned HTTP #{response.status}", retryable: retryable)
    end
  end
end
