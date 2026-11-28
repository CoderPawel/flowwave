# 0013. Authentication and sessions

- Status: Accepted
- Date: 2026-11-28
- Implements: roadmap step 4 ([prompt 4](../prompts/prompt-04-auth-privacy.md)); the authentication note promised in [0008](0008-nestjs-sync-api.md)

## Context

Sync, export and account deletion (steps 4 and 10) need accounts. Prompt 4 asks
for email and password sign-in for development, Argon2id, short-lived access
tokens, rotating refresh tokens with reuse detection, sign-out from one or all
devices, audit events, rate limiting, and secure token storage with automatic
refresh on the phone. Social sign-in is out of scope. The app keeps working
without an account (offline-first, rule 8); an account is only needed for
sync, export and server-side deletion.

## Decision

**Credentials.** `user_credentials` holds a normalized email (trimmed,
lowercase) and an Argon2id hash in PHC format. Parameters follow the OWASP
minimum (19 MiB memory, 2 iterations, 1 lane) and are stored in the hash, so
they can be raised later; a sign-in with an outdated hash rehashes it.
Passwords are 12–128 characters, with no composition rules (NIST SP 800-63B).
Sign-in with an unknown email still runs a hash verification, so response
time does not reveal whether an account exists. There is no email
verification or password reset yet: both need email delivery, which is not
part of the MVP. Pilot accounts are created by the owner or by the testers
themselves. Registration is therefore off by default when
`NODE_ENV=production` (`AUTH_REGISTRATION_ENABLED`).

**Tokens are opaque random strings, not JWTs.** Each token is 32 random bytes
in base64url with a prefix (`fwat_` access, `fwrt_` refresh) that secret
scanners can recognize. The database stores only their SHA-256 hashes (the
tokens are long and random, so a slow hash adds nothing). Every request looks
up its access token, which costs one indexed query, but sign-out, reuse
detection and account deletion take effect immediately, and there is no
signing key to manage or leak. No JWT library is needed.

**Sessions.** Signing in creates a `devices` row for the installation and one
`auth_sessions` row for it. Each refresh issues a new token pair in
`auth_tokens`:

- Access token: 15 minutes (`ACCESS_TOKEN_TTL_SECONDS`).
- Refresh token: 30 days, sliding (`REFRESH_TOKEN_TTL_DAYS`); single use.
- Rotation marks the presented refresh token as used with a conditional
  update, so of two concurrent refreshes with the same token exactly one
  succeeds.
- **Reuse detection**: presenting a refresh token that was already used
  revokes the whole session (all tokens of that device) and writes a
  `refresh_token_reused` audit event. A stolen and used refresh token
  therefore logs out both the thief and the user, who signs in again.
- The phone performs one refresh at a time (single flight), so normal use
  never triggers reuse detection.

**Sign-out.** `POST /v1/auth/logout` revokes the current session and signs the
device out (`devices.deleted_at_utc`). `POST /v1/auth/sessions/{id}/revoke`
signs out another device of the same user. `POST /v1/auth/logout-all` revokes
every session. Revoked sessions stop working at once, including their
unexpired access tokens.

**Audit events** (`audit_events`, append-only): account created, sign-in
succeeded or failed (only for existing accounts; no email is stored for
unknown ones), device registered, signed out, signed out everywhere, session
revoked, refresh token reused, consent recorded, export requested and
completed, account deleted. Metadata never contains health values, tokens,
passwords, emails or IP addresses.

**Rate limiting.** A global guard limits requests per client IP, with stricter
limits per route: sign-in 10 per 15 minutes per IP and 5 failed attempts per
15 minutes per email, registration 5 per hour per IP, refresh 30 per minute
per IP, export 3 per day per user, account deletion 5 per hour per user,
everything else 120 per minute per IP. Exceeding a limit returns `429` with
`Retry-After`. Counters live in memory, which is correct for the single API
instance of the MVP; a shared store is needed before running several
instances. `TRUST_PROXY_HOPS` tells Express how many reverse proxies to trust
for the client IP. The per-email limit lets someone delay another user's
sign-in by 15 minutes; this is accepted in exchange for slowing password
guessing.

**Mobile.**

- Tokens are kept in `flutter_secure_storage`, which encrypts them with a key
  held in the Android Keystore. They are never written to preferences, files
  or logs, and Android backup is already disabled.
- An HTTP client wrapper adds the access token and refreshes it 60 seconds
  before it expires. On a `401` it refreshes once and retries. Concurrent
  requests share one refresh.
- If the refresh is rejected (expired, revoked, reused), the app signs out
  locally.
- Sign-out always completes locally, also offline. It tells the server when
  possible, then deletes the tokens and every piece of local data registered
  as user data (later steps register the local database and caches), so the
  next person who signs in on that phone sees nothing of the previous user.

## Dependencies

| Dependency | Why it is required |
| --- | --- |
| `@node-rs/argon2` (API) | Argon2id is required by the prompt and is not in Node.js 22 `crypto`. Prebuilt binaries for Linux, Windows and macOS, no install scripts, no JavaScript dependencies. |
| `flutter_secure_storage` (mobile) | Native secure storage (Android Keystore), required by the prompt; Flutter has no built-in equivalent. |
| `http` (mobile) | HTTP client for the API, maintained by the Dart team; `dart:io` `HttpClient` lacks the testing support (`MockClient`) the refresh logic needs. |

## Consequences

- One database lookup per authenticated request. Fine for the MVP; a cache
  can be added if needed without changing the token format.
- A client that retries a refresh after losing the response is signed out and
  must sign in again. Rare, and safer than a grace window.
- Moving to several API instances needs a shared rate-limit store.
- Social sign-in, passkeys, email verification and password reset need their
  own decision notes.

## Acceptance criteria

- Tests show: registration and sign-in return a token pair; wrong passwords
  and unknown emails get the same `401`; access tokens expire; a refresh
  returns a new pair and invalidates the old refresh token; reusing a refresh
  token revokes the session; sign-out ends one session and logout-all ends
  every session; one user cannot read or revoke another user's sessions,
  consents or exports; limits return `429`.
- The mobile tests show that tokens are stored only through the secure store,
  that expiring tokens are refreshed once for concurrent requests, and that
  sign-out deletes tokens and registered local data even when the server
  cannot be reached.
