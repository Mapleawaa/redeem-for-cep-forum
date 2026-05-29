# CEP Redeem Rewards Plugin

Issues CEP trial redeem codes when a Discourse user reaches trust level 1, 2, or 3.

Default rewards:

- TL1: 14 days
- TL2: 30 days
- TL3: 60 days, issued as two 30-day redeem codes

The plugin does not add an admin page or application route. It stores structured grant records in
`cep_redeem_grants` and writes summaries to the existing Discourse staff action logs with custom
type `cep_redeem_grant`.
