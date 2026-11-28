# Prompt 4: authentication and privacy (verbatim)

Source: the owner's Copilot plan, pasted on 2026-11-28. Kept verbatim so later
steps can refer to the exact wording. How it was implemented, and where it was
adapted to the project rules, is in [roadmap step 4](../roadmap.md) and
decisions [0013](../architecture/0013-authentication-and-sessions.md) and
[0014](../architecture/0014-consent-types-export-and-deletion.md).

```text
Prompt 4: autoryzacja i prywatność

Implement authentication and privacy foundations for FlowWave.

Backend:
- email/password development authentication
- Argon2id password hashing
- short-lived access token
- rotating refresh tokens
- refresh token reuse detection
- logout from one device
- logout from all devices
- audit events
- rate limiting
- account data export job
- account deletion workflow

Mobile:
- secure token storage using native secure storage
- automatic token refresh
- full logout cleanup

Consent model:
- separate consent for health data
- separate consent for device usage data
- separate consent for notifications
- separate consent for analytics
- consent version and timestamp
- withdrawal support

Do not add social login yet.

Generate tests for:
- authentication
- refresh rotation
- token reuse
- data isolation
- consent withdrawal
```
