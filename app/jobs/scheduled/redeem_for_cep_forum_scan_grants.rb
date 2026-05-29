# frozen_string_literal: true

module Jobs
  class RedeemForCepForumScanGrants < ::Jobs::Scheduled
    every 1.day

    def execute(args)
      return unless SiteSetting.redeem_for_cep_forum_enabled

      enqueue_missing_grants
      enqueue_unfinished_grants
    end

    private

    def enqueue_missing_grants
      User.real.not_suspended.where("trust_level >= ?", 1).find_each do |user|
        RedeemForCepForum::GrantService.reward_levels_for(user).each do |reward_level|
          next if RedeemForCepForum::RedeemGrant.exists?(user_id: user.id, reward_level: reward_level)

          Jobs.enqueue(
            :redeem_for_cep_forum_issue_grant,
            user_id: user.id,
            reward_level: reward_level,
          )
        end
      end
    end

    def enqueue_unfinished_grants
      RedeemForCepForum::RedeemGrant.unfinished.find_each do |grant|
        Jobs.enqueue(
          :redeem_for_cep_forum_issue_grant,
          user_id: grant.user_id,
          reward_level: grant.reward_level,
        )
      end
    end
  end
end
