# frozen_string_literal: true

module ::RedeemForCepForum
  class Reward < ::ActiveRecord::Base
    self.table_name = "redeem_for_cep_forum_rewards"

    belongs_to :user

    validates :user_id, :reward_key, :cep_user_id, :trial_days, :redeem_code, :issued_at, presence: true
    validates :reward_key, uniqueness: { scope: :user_id }
  end
end
