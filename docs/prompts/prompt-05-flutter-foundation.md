# Prompt 5: Flutter app foundation (verbatim)

Source: the owner's Copilot plan, pasted on 2026-11-28. Kept verbatim so later
steps can refer to the exact wording. How it was implemented, and where it was
adapted to the project rules, is in [roadmap step 5](../roadmap.md) and
decision [0015](../architecture/0015-flutter-app-architecture.md).

```text
Prompt 5: aplikacja Flutter

Build the Flutter mobile application foundation for FlowWave.

Use:
- Riverpod
- go_router
- Dio
- Drift with SQLite
- Freezed/json_serializable
- flutter_secure_storage
- Material 3

Architecture:
- feature-first structure
- domain, data and presentation layers
- repository interfaces
- offline-first write queue
- API synchronization service
- centralized error mapping
- Polish and English localization
- dark and light theme
- accessibility labels

Screens:
1. Splash/startup
2. Registration
3. Login
4. Privacy introduction
5. Consent selection
6. Onboarding
7. Today dashboard placeholder
8. Check-in placeholder
9. Timeline placeholder
10. Insights placeholder
11. Settings
12. Data and privacy screen

Do not add Health Connect yet.
Create widget tests and repository tests.
Run flutter analyze and flutter test.
```
