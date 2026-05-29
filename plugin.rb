# frozen_string_literal: true

# name: redeem-for-cep-forum
# about: Issue CEP redeem codes to users when they reach configured trust levels
# meta_topic_id: TODO
# version: 0.0.1
# authors: Maple
# url: TODO
# required_version: 2.7.0

enabled_site_setting :redeem_for_cep_forum_enabled

module ::RedeemForCepForum
  PLUGIN_NAME = "redeem-for-cep-forum"
end

require_relative "lib/redeem_for_cep_forum/engine"

after_initialize do
  require_relative "app/models/redeem_for_cep_forum/redeem_grant"
  require_relative "app/services/redeem_for_cep_forum/issuer"
  require_relative "app/services/redeem_for_cep_forum/grant_service"

  DiscourseEvent.on(:user_promoted) do |event|
    next unless SiteSetting.redeem_for_cep_forum_enabled

    user = User.find_by(id: event[:user_id])
    next if user.blank?

    RedeemForCepForum::GrantService.reward_levels_for(user).each do |reward_level|
      Jobs.enqueue(
        :redeem_for_cep_forum_issue_grant,
        user_id: user.id,
        reward_level: reward_level,
      )
    end
  end
end
