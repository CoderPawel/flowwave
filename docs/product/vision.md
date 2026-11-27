# FlowWave product vision

- Status: Proposal, awaiting reconciliation with the owner's earlier plan
- Last updated: 2026-11-27

## Problem

People with ADHD often experience stronger swings in energy and focus than
others: periods of high drive or hyperfocus followed by a crash, difficulty
sensing how much time has passed, and irregular sleep, meals, and breaks that
amplify those swings. Many want practical, non-pharmacological ways to work
with their own rhythm.

FlowWave helps a person observe their personal energy and focus rhythm, see how
it relates to sleep, meals, movement, rest, and screen use, and plan the day
around it.

## Positioning and limits

- **Self-observation and day planning, not treatment.** FlowWave does not
  diagnose, treat, or manage ADHD, and it does not replace medication such as
  methylphenidate (e.g. Medikinet) or lisdexamfetamine (e.g. Elvanse).
  Decisions about medication belong to the user and their doctor. FlowWave can
  complement treatment or other non-pharmacological strategies.
- **Regulatory boundary.** In the EU, software that claims to diagnose or treat
  a condition is a medical device under the Medical Device Regulation (MDR).
  Product copy, store listings, and in-app text must stay within wellbeing and
  self-organization claims. Wording rules are listed below.
- **Health data under GDPR.** Sleep, heart rate, and self-reported energy are
  special-category data (GDPR art. 9). Each source needs explicit, revocable
  consent, and processing stays on the device by default.

## Primary setup (owner's devices)

| Device | Role | Notes |
| --- | --- | --- |
| Android phone | Main app, offline-first; reads wearable data from Health Connect; measures screen time totals | First platform. iOS later; the core already declares Apple Health. |
| Older Mi Band (4–7) currently paired with Zepp Life | Sleep, steps, heart rate | Zepp Life does not write to Health Connect; see [Mi Band integration](#mi-band-integration). |
| Windows computer | Active vs idle minutes only | Small desktop agent in a later phase. |

## How it works

1. **Observe.** Wearable data plus very short self-ratings (energy 1–5,
   focus 1–5, one tap, a few times a day) and quick logs for meals and breaks.
2. **Personal rhythm.** After roughly two to three weeks of data, show the
   person's typical energy and focus curve by time of day, with how much data
   each point is based on.
3. **Patterns.** Look for relationships in the person's own data, for example
   short or late sleep followed by lower focus the next day, a heavy meal
   followed by an energy dip, morning movement followed by better focus, or a
   long uninterrupted work block followed by a crash.
4. **Plan.** Suggest when to schedule demanding work, light tasks, movement,
   meals, and breaks. Every suggestion states which inputs it is based on.
5. **Nudge.** Gentle in-the-moment prompts, for example after a long
   uninterrupted screen or work block: "You have been working for 2 h 40 min
   without a break. After blocks this long your energy usually drops. Water,
   food, or five minutes of movement?"

## Data FlowWave plans to collect

Nothing in this table is collected until the phase that needs it is built and
the field is added to [`docs/privacy/data-inventory.md`](../privacy/data-inventory.md).

| Area | Source | Exactly what | Phase |
| --- | --- | --- | --- |
| Energy and focus | Manual check-in | Rating 1–5 each, with time | 1 |
| Meals | Manual log | Time and size (light / normal / heavy); no calories, no food photos | 1 |
| Sleep | Manual log, later Health Connect | Sleep start, end, duration; stages if available | 1, 2 |
| Breaks | Manual tap | Start and end of a break | 1 |
| Movement | Health Connect | Steps and active minutes, aggregated per hour | 2 |
| Body intensity | Health Connect | Heart rate samples and resting heart rate, if the band exports them | 2 |
| Phone screen time | Android usage statistics, computed on the device | Total screen-on minutes per hour; no app names, no content | 3 |
| Computer activity | Windows agent | Active and idle minutes per interval, from system idle time | 3 |

Never collected, in any phase: window titles, URLs or browsing history,
document contents, messages, file names or paths, keystrokes or typed text.
The Windows agent detects activity from the system idle timer, not by logging
input.

## Mi Band integration

Findings as of 2026-11-27 (verify again before building phase 2):

- **Zepp Life** (older Mi Band models) has no direct Health Connect
  integration. Its Android route was Zepp Life → Google Fit → Health Connect,
  and Google supports the Google Fit APIs only until the end of 2026.
- **Mi Fitness** (Xiaomi Wear) writes to Health Connect and is Xiaomi's current
  app. Some older bands (for example the Mi Band 6) can be moved to Mi Fitness.
  This requires unpairing in Zepp Life first and, in reported cases, a factory
  reset of the band. Xiaomi offers a history transfer from Zepp Life in
  Mi Fitness (Profile → Third-party data → Zepp Life).
- Mi Fitness only syncs while it can run in the background, so battery
  optimization must be disabled for it.
- Some bands measure HRV or stress but do not export them to other apps.
  FlowWave must treat any metric that is not in Health Connect as missing, not
  estimate it.
- FlowWave reads from Health Connect only and does not talk to the band over
  Bluetooth. Xiaomi's protocol is closed and changes between models, while
  Health Connect is stable, consent-based, and also covers other wearables.

If the owner's band model cannot move to Mi Fitness, phase 1 still works with
manual sleep logs, and a newer band can be added later without code changes.

## Recommendation principles

- Every estimate and suggestion lists the inputs it used, the inputs that were
  missing and why, and how much history it is based on.
- Missing data is shown as missing. FlowWave never fills gaps with typical
  values or population averages.
- Patterns are described as observations about the person's own data
  ("in your last 14 days ..."), never as causes or clinical findings.
- Suggestions are optional and easy to dismiss; dismissing is not penalized.

Wording:

| Use | Avoid |
| --- | --- |
| energy estimate, personal rhythm, pattern in your data | diagnosis, symptom, disorder, treatment, therapy |
| suggestion, you could try | you must, prescribed, dose |
| lower energy than your usual | deficit, abnormal, dysfunction |

## Design principles for ADHD

- **Lowest possible friction.** A check-in is one tap from a notification or
  widget. Nothing requires typing.
- **Make time visible.** Show elapsed time in the current block and the time
  until the next planned break.
- **Hyperfocus safety net.** Optional prompts after long uninterrupted blocks
  to drink, eat, or move.
- **No shame mechanics.** No broken-streak penalties, no red failure states;
  missed days are simply missing data.
- **Quiet by default.** Few notifications, user-chosen quiet hours, and no
  notification during a protected focus block unless the user opts in.
- **Works offline.** Everything except optional backup works without a network.

## Open questions

- Owner's exact Mi Band model, and whether it can move to Mi Fitness.
- Whether the owner wants cloud backup and sync between devices, or a
  phone-only first release.
- Reconciliation with the owner's existing schedule prepared with another
  assistant.
