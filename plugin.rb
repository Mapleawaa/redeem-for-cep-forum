# frozen_string_literal: true

# name: redeem-for-cep-forum
# about: Issue CEP trial redeem codes from Discourse rewards
# version: 0.0.1
# authors: Maple
# required_version: 2.7.0

enabled_site_setting :cep_redeem_enabled

module ::RedeemForCepForum
  PLUGIN_NAME = "redeem-for-cep-forum"
end

require_relative "lib/redeem_for_cep_forum/engine"
require_relative "lib/redeem_for_cep_forum/reward_registry"

register_user_custom_field_type RedeemForCepForum::RewardRegistry::CEP_USER_ID_FIELD, :integer
