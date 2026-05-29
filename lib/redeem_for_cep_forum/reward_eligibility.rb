# frozen_string_literal: true

module ::RedeemForCepForum
  class RewardEligibility
    def initialize(user)
      @user = user
    end

    def eligible?(reward)
      return false if @user.blank?

      required_trust_level = reward[:trust_level]
      return @user.trust_level.to_i >= required_trust_level if required_trust_level.present?

      if reward[:days_setting] == :cep_redeem_first_post_days
        return Post.where(user_id: @user.id, post_type: Post.types[:regular], deleted_at: nil).exists?
      end

      true
    end
  end
end
