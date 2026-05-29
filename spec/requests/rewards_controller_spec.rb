# frozen_string_literal: true

RSpec.describe RedeemForCepForum::RewardsController do
  fab!(:user)

  before do
    enable_current_plugin
    SiteSetting.cep_redeem_enabled = true
    SiteSetting.cep_redeem_client_secret = "secret"
    sign_in(user)
  end

  describe "GET /redeem-for-cep-forum/rewards" do
    it "returns configured rewards without redeem codes" do
      RedeemForCepForum::Reward.create!(
        user: user,
        reward_key: "registration_bonus",
        cep_user_id: 123,
        trial_days: 7,
        redeem_code: "CEPv1.secret",
        shown_once: true,
        issued_at: Time.zone.now,
        shown_at: Time.zone.now,
      )

      get "/redeem-for-cep-forum/rewards.json"

      expect(response.status).to eq(200)
      body = response.parsed_body
      registration_reward = body["rewards"].find { |reward| reward["key"] == "registration_bonus" }

      expect(registration_reward["claimed"]).to eq(true)
      expect(response.body).not_to include("CEPv1.secret")
    end
  end

  describe "POST /redeem-for-cep-forum/rewards/:reward_key/redeem" do
    before do
      user.custom_fields[RedeemForCepForum::RewardRegistry::CEP_USER_ID_FIELD] = 123
      user.save_custom_fields(true)
    end

    it "issues and returns the code only during the first successful redeem" do
      issuer = instance_double(RedeemForCepForum::Issuer)
      result = RedeemForCepForum::Issuer::Result.new(success?: true, code: "CEPv1.once")

      expect(RedeemForCepForum::Issuer).to receive(:new).and_return(issuer)
      expect(issuer).to receive(:issue).with(cep_user_id: 123, trial_days: 7).and_return(result)

      post "/redeem-for-cep-forum/rewards/registration_bonus/redeem.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["code"]).to eq("CEPv1.once")

      get "/redeem-for-cep-forum/rewards.json"

      expect(response.status).to eq(200)
      expect(response.body).not_to include("CEPv1.once")
    end

    it "does not issue a reward twice" do
      RedeemForCepForum::Reward.create!(
        user: user,
        reward_key: "registration_bonus",
        cep_user_id: 123,
        trial_days: 7,
        redeem_code: "CEPv1.existing",
        shown_once: true,
        issued_at: Time.zone.now,
        shown_at: Time.zone.now,
      )

      expect(RedeemForCepForum::Issuer).not_to receive(:new)

      post "/redeem-for-cep-forum/rewards/registration_bonus/redeem.json"

      expect(response.status).to eq(409)
      expect(response.body).not_to include("CEPv1.existing")
    end

    it "rejects users without a CEP user id" do
      user.custom_fields.delete(RedeemForCepForum::RewardRegistry::CEP_USER_ID_FIELD)
      user.save_custom_fields(true)

      post "/redeem-for-cep-forum/rewards/registration_bonus/redeem.json"

      expect(response.status).to eq(422)
    end
  end
end
