# Draft: accounts and "Sign in with Google"

- **Status:** draft for the product owner to think through. **Nothing is decided or built yet.**
- **Written by:** mobile-fe agent, 2026-10-25, from a read of `be/`, `web-fe/` and `mobile-fe/`.
- **Audience:** you first. Once you've settled the decisions in § 3, this becomes the brief for
  the backend, web and mobile agents.

---

## 1. Where we are

There is no identity anywhere in the system:

- **The API trusts everyone who can reach it.** `https://agonez.com/api/...` and — because
  `be/compose.yml` publishes the container port (`${MAMMOONE}:8000`) — also
  `http://<server-ip>:33287` directly, bypassing Caddy.
- Anyone who finds either address can read every plan and workout, change them, and since
  this week **delete plan runs** (`DELETE /plan-runs/{id}`).
- The mobile app's `X-Agonez-Device-Id` is a label for its installation, used for
  write leases. It is not a secret and proves nothing.
- All data implicitly belongs to one person: you. There is no "owner" on any row.

HTTPS (done today) hides the traffic. It does not keep strangers out. That's what accounts are
for.

## 2. How "Sign in with Google" works, in plain terms

**What you actually use is OpenID Connect (OIDC), a thin layer on top of OAuth.** You don't
want access to anyone's Gmail or Drive. You only want Google to vouch for *who* the person
is. So the only scopes are `openid email profile`.

**The ID token.** After the person picks their Google account, Google hands the app a signed
**ID token**: a small JWT that says, roughly, "this is Google account `sub=1043…`, email
`x@gmail.com`, issued for app `<your client id>`, valid for an hour". Google signs it, so
your backend can check it is genuine without calling Google: it verifies the signature
against Google's published keys, the audience (your client id), the issuer and the expiry.

**Google identifies; Agonez decides.** The backend uses the verified ID token **once**, at
sign-in:

1. Find or create the Agonez user for that Google account.
2. Issue **Agonez's own session** — its own tokens, under its own rules and lifetimes.

From then on every API call carries the Agonez session, not anything from Google. You never
store Google tokens and never call Google again. Google is only the doorbell.

**The same backend endpoint serves both clients:**

```text
Web (Vue)                       Mobile (Flutter)
"Sign in with Google" button    google_sign_in → Android Credential Manager
        │                                │
        └──── Google ID token ───────────┘
                     │
        POST /api/v1/auth/google  { id_token }
                     │
     backend verifies the token, upserts the user
                     │
        Agonez session issued
        (web: HttpOnly cookie · mobile: access + refresh token)
```

**Key on Google's `sub`, never on the email.** `sub` is Google's permanent account id. An email
can change, or be recycled.

## 3. Decisions only you can make

These shape everything else. My recommendation is first in each.

**D1 · Who are the users?**
- **(b) You, plus other athletes, each seeing only their own data** *(recommended)*.
- (a) Only you: a lock on the door.
- (c) Coaches and athletes sharing data.

The waitlist module suggests you're heading for (b), perhaps (c) later. Build the data model
for (b) now: every owned row has an owner. Sharing (c) can be added on top later without
redoing it. (a) would be cheaper today but means a second migration later.

**D2 · Which sign-in methods?**
- **Google only for now** *(recommended)*.

Store identities in their own table, so Apple (needed if there's ever an iOS app) or an
email magic link can be added later without touching users.

**D3 · Who may sign up?**
- **Invite or allowlist** *(recommended)*, e.g. emails from the waitlist, or an allowlist you
  manage.
- Open sign-up.

Invite-only keeps it private while it's young; open sign-up is a later switch.

**D4 · How does the web app hold its session?**
- **An HttpOnly, Secure, SameSite cookie on `agonez.com`** *(recommended)*. The web app and API
  share the domain, so this is the safest and simplest option: JavaScript can't read it. It
  needs basic CSRF protection for writes.
- Bearer tokens kept in JavaScript: simpler on paper, but readable by any injected script.

**D5 · How long do sessions last?** Recommended:
- A short access token (~15 min) plus a long, rotating **refresh** token (60–90 days, renewed
  on use).
- On mobile: you shouldn't need to sign in again at the gym. And **offline training must keep
  working with an expired session**. Tokens are only needed to sync, so recording a workout
  never waits for sign-in.

**D6 · Existing data?**
- **Assign everything that exists today to your account** when it's created *(recommended)*.

**D7 · What stays public?**
- **The Atlas catalogue (read), the waitlist and health checks** *(recommended)*. Plans, plan
  runs, workouts and analysis require sign-in.

**D8 · Account deletion and privacy.** With other people's data (and EU users), you'll need:
- a privacy policy (Google also asks for its URL on the consent screen)
- "delete my account and data"
- ideally "export my data"

These can come in the multi-user phase, but plan for them.

## 4. What changes where

### Backend (largest part)

- **New `auth` schema:**
  - `users`: id (uuid), email, display_name, avatar_url, status, created_at, last_login_at.
  - `user_identities`: user_id, provider (`google`), provider_subject (Google `sub`), email at
    link time; unique per (provider, subject).
  - `sessions` (refresh tokens): id, user_id, **device_id** (the mobile installation UUID,
    nullable for web), token hash (never the token itself), created / last used / expires /
    revoked, user agent. This gives "sign out this device" and "sign out everywhere".
- **Endpoints:**
  - `POST /api/v1/auth/google` (exchange an ID token for a session)
  - `POST /api/v1/auth/refresh`
  - `POST /api/v1/auth/logout`
  - `GET /api/v1/me`
  - later `DELETE /api/v1/me`
- **A `CurrentUser` dependency** on every private router. Missing or invalid session →
  `401`. Another user's resource → **`404`, not `403`**, so ids don't reveal what exists.
- **Ownership.**
  - `owner_user_id` on the root of each aggregate: plans (`plans` schema) and plan runs
    (`exec.plan_runs`). Everything below a run (sessions, prescriptions, performances,
    mobile sync ops) belongs to its run's owner through joins.
  - **Every repository query must be scoped to the current user.** This is the bulk of the
    work and the main risk: one unscoped query is a data leak. It needs a helper that makes
    scoping the default, and an isolation test per endpoint ("user B gets 404 on user A's
    run").
- **Infrastructure:** stop publishing port 33287 in `compose.yml`, so the API is only
  reachable through Caddy and HTTPS. CORS stays same-origin.
- **Google verification:** a well-known library (e.g. `google-auth` or `authlib`) with
  Google's cached public keys. Accept the web client id as the audience; mobile requests the
  token *for* the web client id (see below), so one audience is enough.

### Web (Vue 3 + Pinia + vue-router)

- A sign-in page with Google's official button (Google Identity Services). It returns an ID
  token, which the page posts to `/auth/google`.
- A Pinia `auth` store (`/me` on load), router guards that send signed-out users to sign-in,
  and "Sign out".
- Requests go out with credentials (cookie). A `401` sends the user to sign-in. Mutating
  requests carry a CSRF header (if D4 = cookie).

### Mobile (Flutter)

- A sign-in screen on first launch and whenever refresh fails. It uses `google_sign_in` with
  `serverClientId` = the **web** client id, so the ID token's audience is the backend's.
- Tokens are kept in Android's Keystore-backed secure storage (`flutter_secure_storage`),
  never in the app database.
- A Dio interceptor adds `Authorization: Bearer …`. On `401` it refreshes once and retries;
  if refresh fails, it shows sign-in.
- **Offline-first stays intact.** Recording works signed out or offline. The sync engine
  simply pauses until there is a valid session, then resumes as the same user. Signing in as a
  *different* user on the same phone must not upload the previous person's queued workouts.
- **One person per installation** (recommended). Signing out requires everything to be
  synced (or an explicit "discard unsynced data") and then clears the local database.
- `X-Agonez-Device-Id` stays as the installation id for write leases. It is no longer
  treated as identity.

### Google Cloud Console (you, about an hour)

- An **OAuth consent screen**: app name, logo, support email, authorised domain `agonez.com`,
  privacy policy URL. It can stay in **Testing** (up to 100 named test users) while it's just
  you and friends. Going to production with only the basic scopes needs only light brand
  verification.
- **OAuth client ids:**
  - **Web** (authorised origin `https://agonez.com`).
  - **Android** (package `com.gawor.agonez` plus the **SHA-1 of the signing key**). The debug
    key, your release key and, if you ever publish on Play, Google Play's app-signing key are
    *different* fingerprints, and sign-in fails without a clear message if the right one is
    missing.

## 5. Rollout, without locking yourself out

1. **Foundation (nothing enforced).**
   - Backend: `auth` tables, the auth endpoints, Google verification, your user created.
   - Ownership: `owner_user_id` added and filled with your id everywhere.
   - Everything keeps working as today.
2. **Clients sign in.**
   - Web and mobile get sign-in and send their session.
   - The backend *accepts but doesn't require* it, and logs unauthenticated calls, so you can
     see when every client is ready.
3. **Enforce.**
   - Private endpoints require a session, and queries are scoped by owner.
   - The cross-user isolation tests must pass.
   - Close port 33287.
4. **Multi-user readiness.**
   - The sign-up policy (D3).
   - The consent screen moves to production.
   - Privacy policy, account deletion, data export (D8).

Keep an escape hatch during steps 2–3: an environment-variable allowlist with your Google
`sub`, so a bug can't lock you out of your own data.

## 6. Risks and gotchas

- **Unscoped queries leak data.** The biggest risk. Mitigated by a scoping helper as the
  default path, plus an isolation test per endpoint.
- **Lockout during rollout.** Mitigated by steps 2 → 3 and the escape hatch.
- **Android fingerprints.** The wrong SHA-1 means silent sign-in failure. Register debug and
  release (and Play signing, later).
- **Offline expiry.** A workout must never be blocked or lost because a token expired. Sync
  waits; it doesn't drop anything.
- **Account switching on one phone.** Never sync one person's queued workouts under another
  account.
- **Email isn't identity.** Key on Google's `sub`.
- **Google's own tokens aren't needed.** No Google refresh tokens are stored, so Google's
  7-day expiry in Testing mode doesn't affect us.

## 7. Rough size

| Part | Size | Notes |
| --- | --- | --- |
| Backend auth module (tables, endpoints, verification, sessions) | M | Self-contained. |
| Backend ownership + query scoping + isolation tests | **L** | Touches every module: `plans`, `execution`, `mobile_execution`, analysis. |
| Web sign-in, store, guards, CSRF | S–M | |
| Mobile sign-in, secure storage, interceptor, offline and sign-out rules | M | |
| Google Cloud Console setup | S | You, once. |

## 8. Questions to answer before any agent starts

1. D1: (a), (b) or (c)? Is a coach role on the horizon?
2. D3: invite or allowlist, or open sign-up? If invite-based, should it come from the waitlist?
3. D4: cookie for the web? (recommended)
4. D5: are 15-minute access and 60–90-day refresh lifetimes acceptable?
5. D7: should the Atlas stay readable without signing in (e.g. for the marketing site)?
6. D8: will other people use it soon (privacy policy and deletion become urgent), or later?
7. Will there ever be an iOS app? (Then "Sign in with Apple" becomes mandatory next to Google.)
