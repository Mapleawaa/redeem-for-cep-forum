# frozen_string_literal: true

module Jobs
  class RedeemForCepForumIssueGrant < ::Jobs::Base
    def execute(args)
      return unless SiteSetting.redeem_for_cep_forum_enabled

      user = User.find_by(id: args[:user_id])
      return if user.blank?

      reward_level = args[:reward_level].presence || args[:trust_level]
      RedeemForCepForum::GrantService.new(user: user, reward_level: reward_level).call
    end
  end
end
