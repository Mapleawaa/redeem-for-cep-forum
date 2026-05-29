# frozen_string_literal: true

module RedeemForCepForum
  class GrantService
    LOG_TYPE = "cep_redeem_grant"

    def self.reward_days_for(trust_level)
      case trust_level.to_i
      when 1
        SiteSetting.redeem_for_cep_forum_tl1_trial_days.to_i
      when 2
        SiteSetting.redeem_for_cep_forum_tl2_trial_days.to_i
      when 3
        SiteSetting.redeem_for_cep_forum_tl3_trial_days.to_i
      end
    end

    def self.reward_levels_for(user)
      [1, 2, 3].select { |level| user.trust_level >= level && reward_days_for(level).to_i.positive? }
    end

    def initialize(user:, reward_level:)
      @user = user
      @reward_level = reward_level.to_i
    end

    def call
      return if @user.blank? || @user.bot? || @user.staged?
      return if @reward_level < 1 || @reward_level > 3
      return if @user.trust_level < @reward_level

      @total_days = self.class.reward_days_for(@reward_level).to_i
      return if @total_days <= 0

      cep_user_id = read_cep_user_id
      if cep_user_id.blank?
        return create_error_grant(
          "missing_cep_user_id",
          "CEP user id custom field is blank",
          retryable: true,
        )
      end

      @grant = find_or_create_grant(cep_user_id)
      refresh_grant_context(cep_user_id)
      return if @grant.delivered?

      issue_codes unless @grant.issue_complete?
      deliver_private_message if @grant.issue_complete?
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    private

    def read_cep_user_id
      field_name = SiteSetting.redeem_for_cep_forum_cep_user_id_field.presence || "user_id"
      value =
        [
          field_name,
          field_name.tr(" ", "_"),
          field_name.tr("_", " "),
          field_name.downcase,
          field_name.downcase.tr(" ", "_"),
          field_name.downcase.tr("_", " "),
        ].uniq.lazy.map { |name| @user.custom_fields[name] }.find(&:present?)
      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end

    def find_or_create_grant(cep_user_id)
      RedeemGrant.find_or_create_by!(user_id: @user.id, reward_level: @reward_level) do |grant|
        grant.username = @user.username
        grant.cep_user_id = cep_user_id
        grant.user_trust_level = @user.trust_level
        grant.total_trial_days = @total_days
        grant.status = "pending"
      end
    end

    def refresh_grant_context(cep_user_id)
      @grant.update!(
        username: @user.username,
        cep_user_id: cep_user_id,
        user_trust_level: @user.trust_level,
        total_trial_days: @total_days,
      )
    end

    def create_error_grant(error_code, error_message, retryable:)
      grant =
        RedeemGrant.find_or_initialize_by(user_id: @user.id, reward_level: @reward_level)
      return if grant.persisted? && grant.delivered?

      grant.assign_attributes(
        username: @user.username,
        cep_user_id: nil,
        user_trust_level: @user.trust_level,
        total_trial_days: @total_days,
        status: retryable ? "retryable" : "failed",
        error_code: error_code,
        error_message: error_message,
        failed_at: Time.zone.now,
      )
      grant.save!
      log_grant(grant)
    end

    def issue_codes
      issuer = Issuer.new

      remaining_days.each do |days|
        code = issuer.issue_code(cep_user_id: @grant.cep_user_id, trial_days: days)
        codes = @grant.redeem_codes + [code]
        @grant.update!(
          redeem_codes: codes,
          status: codes.size >= @grant.expected_code_count ? "issued" : "retryable",
          error_code: nil,
          error_message: nil,
          attempts: @grant.attempts + 1,
          issued_at: @grant.issued_at || Time.zone.now,
        )
      end

      log_grant(@grant)
    rescue Issuer::Error => e
      @grant.update!(
        status: e.retryable ? "retryable" : "failed",
        error_code: e.code,
        error_message: e.message,
        attempts: @grant.attempts + 1,
        failed_at: Time.zone.now,
      )
      log_grant(@grant)
    end

    def remaining_days
      remaining = @grant.total_trial_days
      chunks = []

      while remaining.positive?
        days = [remaining, Issuer::MAX_DAYS_PER_CODE].min
        chunks << days
        remaining -= days
      end

      chunks.drop(@grant.redeem_codes.size)
    end

    def deliver_private_message
      sender = sender_user
      post =
        PostCreator.create!(
          sender,
          target_usernames: @user.username,
          archetype: Archetype.private_message,
          subtype: TopicSubtype.system_message,
          title: pm_title,
          raw: pm_body,
        )

      @grant.update!(
        status: "delivered",
        error_code: nil,
        error_message: nil,
        delivered_at: Time.zone.now,
      )
      log_grant(@grant, topic_id: post.topic_id, post_id: post.id)
    rescue StandardError => e
      @grant.update!(
        status: "issued",
        error_code: "pm_delivery_failed",
        error_message: e.message,
        failed_at: Time.zone.now,
      )
      log_grant(@grant)
    end

    def sender_user
      username = SiteSetting.redeem_for_cep_forum_sender_username
      username.present? ? User.find_by(username: username) || Discourse.system_user : Discourse.system_user
    end

    def pm_title
      template = SiteSetting.redeem_for_cep_forum_pm_title.presence || "你的 CEP 体验会员兑换码"
      render_template(template)
    end

    def pm_body
      template =
        SiteSetting.redeem_for_cep_forum_pm_body_template.presence ||
          "你已获得 {total_days} 天 CEP 体验会员兑换码：\n\n{codes}"
      render_template(template)
    end

    def render_template(template)
      template
        .gsub("{trust_level}", @reward_level.to_s)
        .gsub("{total_days}", @grant.total_trial_days.to_s)
        .gsub("{codes}", formatted_codes)
    end

    def formatted_codes
      @grant.redeem_codes.map { |code| "`#{code}`" }.join("\n")
    end

    def log_grant(grant, topic_id: nil, post_id: nil)
      StaffActionLogger.new(Discourse.system_user).log_custom(
        LOG_TYPE,
        user_id: grant.user_id,
        username: grant.username,
        cep_user_id: grant.cep_user_id,
        reward_level: grant.reward_level,
        total_trial_days: grant.total_trial_days,
        status: grant.status,
        code_count: grant.redeem_codes.size,
        code_tails: code_tails(grant),
        error_code: grant.error_code,
        error_message: grant.error_message,
        attempts: grant.attempts,
        topic_id: topic_id,
        post_id: post_id,
      )
    end

    def code_tails(grant)
      grant.redeem_codes.map { |code| code.to_s.last(8) }.join(",")
    end
  end
end
