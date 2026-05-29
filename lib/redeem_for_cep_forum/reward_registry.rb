# frozen_string_literal: true

module ::RedeemForCepForum
  module RewardRegistry
    CEP_USER_ID_FIELD = "cep_user_id"
    CLIENT_ID = "discourse-plugin"

    REWARDS = {
      "registration_bonus" => {
        title: "Registration bonus",
        description: "Reward for registering and linking your CEP account.",
        days_setting: :cep_redeem_registration_days,
      },
      "first_post_bonus" => {
        title: "First post bonus",
        description: "Reward for publishing your first forum post.",
        days_setting: :cep_redeem_first_post_days,
      },
      "trust_level_1_bonus" => {
        title: "Trust level 1 bonus",
        description: "Reward for reaching trust level 1.",
        days_setting: :cep_redeem_trust_level_1_days,
        trust_level: 1,
      },
      "trust_level_2_bonus" => {
        title: "Trust level 2 bonus",
        description: "Reward for reaching trust level 2.",
        days_setting: :cep_redeem_trust_level_2_days,
        trust_level: 2,
      },
      "trust_level_3_bonus" => {
        title: "Trust level 3 bonus",
        description: "Reward for reaching trust level 3.",
        days_setting: :cep_redeem_trust_level_3_days,
        trust_level: 3,
      },
      "trust_level_4_bonus" => {
        title: "Trust level 4 bonus",
        description: "Reward for reaching trust level 4.",
        days_setting: :cep_redeem_trust_level_4_days,
        trust_level: 4,
      },
    }.freeze

    def self.find(reward_key)
      REWARDS[reward_key]
    end

    def self.all
      REWARDS
    end

    def self.trial_days(reward)
      SiteSetting.public_send(reward.fetch(:days_setting)).to_i
    end
  end
end
