# frozen_string_literal: true

module ::RedeemForCepForum
  class RewardsController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_action :ensure_logged_in

    def index
      render json: { rewards: serialized_rewards }
    end

    def show
      render html: "", layout: "application"
    end

    def redeem
      reward_key = params.require(:reward_key)
      reward = RewardRegistry.find(reward_key)
      if reward.blank?
        return render_json_error(
          I18n.t("redeem_for_cep_forum.errors.unknown_reward"),
          status: 404,
        )
      end

      cep_user_id = current_cep_user_id
      if cep_user_id.blank?
        return render_json_error(
          I18n.t("redeem_for_cep_forum.errors.cep_user_not_bound"),
          status: 422,
        )
      end

      unless RewardEligibility.new(current_user).eligible?(reward)
        return render_json_error(
          I18n.t("redeem_for_cep_forum.errors.not_eligible"),
          status: 403,
        )
      end

      trial_days = RewardRegistry.trial_days(reward)

      DistributedMutex.synchronize("redeem-for-cep-forum:#{current_user.id}:#{reward_key}") do
        existing_reward = Reward.find_by(user_id: current_user.id, reward_key: reward_key)
        if existing_reward.present?
          return render_json_error(
            I18n.t("redeem_for_cep_forum.errors.already_redeemed"),
            status: 409,
          )
        end

        result = Issuer.new.issue(cep_user_id:, trial_days:)
        unless result.success?
          return render_json_error(
            I18n.t("redeem_for_cep_forum.errors.cep_api_failed", error: result.error),
            status: 502,
          )
        end

        Reward.create!(
          user: current_user,
          reward_key: reward_key,
          cep_user_id: cep_user_id,
          trial_days: trial_days,
          redeem_code: result.code,
          shown_once: true,
          issued_at: Time.zone.now,
          shown_at: Time.zone.now,
        )

        @issued_rewards_by_key = nil
        render(
          json: {
            success: true,
            code: result.code,
            reward: serialized_reward(reward_key, reward),
          },
        )
      end
    rescue ActiveRecord::RecordNotUnique
      render_json_error(
        I18n.t("redeem_for_cep_forum.errors.already_redeemed"),
        status: 409,
      )
    end

    private

    def serialized_rewards
      RewardRegistry.all.map { |reward_key, reward| serialized_reward(reward_key, reward) }
    end

    def serialized_reward(reward_key, reward)
      issued_reward = issued_rewards_by_key[reward_key]
      eligible = RewardEligibility.new(current_user).eligible?(reward)
      cep_bound = current_cep_user_id.present?

      {
        key: reward_key,
        title: reward[:title],
        description: reward[:description],
        trial_days: RewardRegistry.trial_days(reward),
        eligible: eligible && cep_bound,
        claimed: issued_reward.present?,
        issued_at: issued_reward&.issued_at,
        shown_once: issued_reward&.shown_once || false,
        locked_reason: locked_reason(eligible, cep_bound, issued_reward),
      }
    end

    def locked_reason(eligible, cep_bound, issued_reward)
      return "claimed" if issued_reward.present?
      return "cep_user_not_bound" if !cep_bound
      return "not_eligible" if !eligible

      nil
    end

    def issued_rewards_by_key
      @issued_rewards_by_key ||=
        Reward.where(user_id: current_user.id).index_by(&:reward_key)
    end

    def current_cep_user_id
      value = current_user.custom_fields[RewardRegistry::CEP_USER_ID_FIELD]
      return if value.blank?

      value.to_i if value.to_i.positive?
    end
  end
end
