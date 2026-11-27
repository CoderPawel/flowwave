# MVP scope

- Status: Proposed; feature list aligned with roadmap steps 2–17
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

| ID | Feature | Roadmap step |
| --- | --- | --- |
| F1 | Check-in in under 8 seconds: energy, focus, and overload (1–10); optional mood, sleepiness, stress (1–5) and a short note; from the dashboard, a notification, or a widget | 6 |
| F2 | Quick logs for meals (light / normal / heavy), caffeine (type, optional amount), exercise (intensity, duration), rest (type, duration), and focus sessions (start, stop) | 7 |
| F3 | Manual sleep entry when no wearable data is available | 7 |
| F4 | Day timeline showing all inputs, with missing inputs marked as missing | 5, 13 |
| F5 | Energy Score (0–100) with confidence, factors, missing inputs, and disclaimer | 12 |
| F6 | Separate consent for health data, device usage, notifications, and analytics, with withdrawal | 4 |
| F7 | Health Connect import: sleep sessions and stages, steps, heart rate, resting heart rate, exercise sessions | 8 |
| F8 | Device usage per 30 minutes: screen-active time, unlocks, app switches, and time per broad app category | 9 |
| F9 | Account, offline-first sync, export, and account deletion | 4, 10 |
| F10 | Rhythm curves for energy, focus, and overload by 30-minute bucket, with READY, FLOW, and recovery windows | 11 |
| F11 | Intensity Debt (0–100) with explanation | 12 |
| F12 | One explained recommendation at a time, with dismiss, snooze, and feedback | 14 |
| F13 | Today dashboard combining F4, F5, F10, F11, and F12 | 13 |

The web panel (step 15) and the pilot tooling (step 16) are tracked in the
[roadmap](../roadmap.md); they are not needed for the MVP on the owner's phone.

## User stories and acceptance criteria

**F1 Check-in.** As a user, I want to rate my energy, focus, and overload in
under 8 seconds so that logging does not interrupt me.
- From the dashboard or a check-in notification, the three required values can
  be saved in under 8 seconds with large touch targets, also offline, with
  visible confirmation.
- A check-in can be edited for 15 minutes after saving; submitting the same
  check-in twice stores it once.
- When I dismiss the notification, no value is stored and no value is assumed.

**F2 Life events.** As a user, I want to log a meal, coffee, exercise, a
break, or a focus session in under five seconds.
- Common events need at most two taps, with recent choices first; time defaults
  to now and can be adjusted; events can be edited.
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

**F8 Device usage.** As a user, I want to see how I use my phone during the
day, without FlowWave seeing what I do in apps.
- Only 30-minute aggregates are stored: screen-active minutes, unlocks, app
  switches, and minutes per broad category (work, communication, social,
  video, games, browser, productivity, health, navigation, other).
- App identifiers are mapped to categories in memory and never stored.
- Without usage access, screen use shows as missing (no consent).

**F9 Account and sync.** As a user, I want my data backed up and in sync.
- Logging works fully offline; whether insights also work without an account
  depends on decision A in the [roadmap](../roadmap.md).
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
- Per-app usage breakdowns or storing app identifiers.
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

- F1–F13 meet their acceptance criteria on the owner's phone.
- The owner and at least two testers used the app for 14 days.
- All CI checks pass, and the data inventory lists every stored field.
