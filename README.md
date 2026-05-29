# Redeem for CEP Forum Plugin

Discourse plugin for issuing CEP trial redeem codes from forum rewards.

## Features

- Rewards page mounted at `/rewards`.
- Rewards sidebar link in the user/community sidebar.
- Registration reward.
- First post reward.
- Trust level 1-4 rewards.
- CEP redeem API integration through `POST /api/redeem/issue`.
- Redeem codes are stored server-side but returned to the user only once, during the successful redeem request.

## Required CEP user field

The plugin reads the CEP user id from the Discourse user custom field:

```text
cep_user_id
```

This should be populated by the CEP OAuth login flow from `userinfo.sub`.

## Settings

Configure these site settings from Discourse admin:

```text
cep_redeem_enabled
cep_redeem_api_url
cep_redeem_client_secret
cep_redeem_registration_days
cep_redeem_first_post_days
cep_redeem_trust_level_1_days
cep_redeem_trust_level_2_days
cep_redeem_trust_level_3_days
cep_redeem_trust_level_4_days
```

The CEP `client_id` is fixed as:

```text
discourse-plugin
```

Do not hard-code `client_secret`; keep it in the Discourse site setting.
