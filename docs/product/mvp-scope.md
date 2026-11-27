# MVP scope

- Status: Proposed
- Last updated: 2026-11-27

The MVP is the smallest version of FlowWave that lets one person on Android
see their own daily rhythm of energy and focus, understand what it relates to,
and get explained suggestions for planning the day. Product context:
[`vision.md`](vision.md). Architecture:
[`system-overview.md`](../architecture/system-overview.md).

## Users

- First: the owner (Android phone, Mi Band moved to Mi Fitness, Windows PC).
- Then: a small group of testers on Android, recruited by the owner.

## In scope

| ID | Feature | Roadmap phase |
| --- | --- | --- |
| F1 | One-tap energy and focus check-ins from a notification, a home-screen widget, or the app | 1 |
| F2 | Quick logs for meals (time, size), caffeine (time, small / medium / large), exercise (start, end, intensity), and rest or breaks (start, end) | 1 |
| F3 | Manual sleep entry when no wearable data is available | 1 |
| F4 | Day timeline showing all inputs, with missing inputs marked as missing | 1 |
| F5 | Energy estimate with factors, missing inputs, and disclaimer (existing core rule) | 1 |
| F6 | Consent screens for every external source and data type, with revocation | 2 |
| F7 | Health Connect import: sleep sessions, steps, heart rate, resting heart rate, exercise sessions | 2 |
| F8 | Screen use: screen-on minutes and unlock count per hour from `UsageStatsManager` | 3 |
| F9 | Opt-in account, backup, and sync through the NestJS API; export; account deletion | 4 |
| F10 | Rhythm view: typical energy and focus by hour of day, with how many days each value is based on | 5 |
| F11 | Load view: uninterrupted work or screen blocks and time since the last break, compared with the person's usual range | 5 |
| F12 | Day suggestions based on the person's rhythm, each with its explanation | 5 |

## User stories and acceptance criteria

**F1 Check-in.** As a user, I want to rate my energy and focus in one tap so
that logging does not interrupt me.
- Given a check-in notification, when I tap a rating, then it is saved without
  opening the app, also offline.
- When I dismiss the notification, no value is stored and no value is assumed.

**F2 Life events.** As a user, I want to log a meal, coffee, exercise, or a
break in under five seconds.
- Each log needs at most two taps; time defaults to now and can be adjusted.
- Every entry is stored with UTC time, time zone, and offset.

**F4 and F5 Day timeline and estimate.** As a user, I want to see my day and an
energy estimate I can understand.
- Every estimate lists the inputs used and the inputs missing, with reasons.
- With no inputs, the app shows "not enough data" and suggests a check-in
  instead of a number.
- The disclaimer is visible wherever an estimate is shown.

**F6 and F7 Wearable data.** As a user, I want my band's sleep, steps, and heart
rate in FlowWave without extra effort, and to control what is read.
- Nothing is read from Health Connect before I grant both the in-app consent and
  the Health Connect permission for that data type.
- Revoking either stops reading that type on the next import, and the input
  shows as missing (no consent).
- Importing the same night twice never creates two sleep sessions.

**F8 Screen use.** As a user, I want to see how much time I spend on my phone
per hour, without FlowWave seeing what I do on it.
- Only screen-on minutes and unlock counts are stored; no app names.
- Without usage access, screen use shows as missing (no consent).

**F9 Sync.** As a user, I want an optional backup.
- The app works fully without an account.
- Retried uploads never create duplicates.
- Deleting my account removes all my data from the server.

**F10 to F12 Rhythm, load, and suggestions.** As a user, I want to know when I
usually have the most energy and focus, and how to plan around it.
- The rhythm view appears after at least 14 days with check-ins; before that it
  shows how many more days are needed.
- Each suggestion says which inputs and how many days of history it is based
  on, for example: "Your focus ratings were highest between 9:00 and 11:00 on
  10 of the last 14 days."
- Wording follows the rules in [`vision.md`](vision.md#recommendation-principles);
  no diagnostic or clinical terms.

## Non-goals for the MVP

- iOS app, Next.js web panel, Windows agent.
- Per-app or per-category screen-time breakdown.
- Machine-learning models; MVP patterns use transparent statistics on the
  person's own data.
- Medication tracking, dosing, or any claim to diagnose, treat, or replace
  treatment.
- Social features, sharing, leaderboards, streak penalties.
- Writing data to Health Connect.
- Multi-device sync (one active device per account).

## Success measures (for the owner and testers)

- At least three check-ins per day on at least 10 of 14 days, without the user
  feeling the app is a burden (short survey).
- Rhythm view available after 14 days for every tester who met the check-in measure.
- Users rate the explanations as understandable (survey, 4 of 5 or higher).
- FlowWave's own background work stays under 2% battery per day.
- No crash or data loss reported in the test period.

## Assumptions

- The owner's band can move to Mi Fitness and its data reaches Health Connect.
- Testers use Android 9 or newer.
- Two to three weeks of check-ins are enough to show a useful personal rhythm.

## Risks

| Risk | Mitigation |
| --- | --- |
| Check-in fatigue | One-tap input, adjustable reminder count, quiet hours, no penalties for missed check-ins. |
| Wearable data gaps or the band cannot use Mi Fitness | Manual sleep entry; missing data shown honestly. |
| Suggestions read as medical advice | Wording rules, disclaimer, review of every user-facing text against the vision document. |
| Google Play review of health and usage-access permissions | Minimal permissions, rationale screens, privacy policy matching the data inventory. |

## MVP is done when

- F1–F12 meet their acceptance criteria on the owner's phone.
- The owner and at least two testers used the app for 14 days.
- All CI checks pass, and the data inventory lists every stored field.
