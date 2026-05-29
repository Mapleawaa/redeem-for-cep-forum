# frozen_string_literal: true

module RedeemForCepForum
  class RedeemGrant < ::ActiveRecord::Base
    self.table_name = "cep_redeem_grants"

    belongs_to :user

    STATUSES = %w[pending issued delivered failed retryable].freeze
    MAX_DAYS_PER_CODE = 30

    validates :user_id, :username, :reward_level, :user_trust_level, :total_trial_days,
              presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :reward_level, inclusion: { in: [1, 2, 3] }
    validates :total_trial_days, numericality: { only_integer: true, greater_than: 0 }
    validates :user_id, uniqueness: { scope: :reward_level }

    scope :unfinished, -> { where(status: %w[pending issued retryable]) }

    def delivered?
      status == "delivered"
    end

    def issue_complete?
      redeem_codes.size >= expected_code_count
    end

    def expected_code_count
      (total_trial_days.to_f / MAX_DAYS_PER_CODE).ceil
    end
  end
end
