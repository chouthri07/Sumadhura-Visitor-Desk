# Build and verification notes

- Flutter analyze: no issues.
- Flutter test: 6 passing tests.
- Flutter web release build: successful.
- Browser workflow: registration, generated pass, check-in and check-out verified using keyboard input in Chrome.
- Mobile viewport screenshots: docs/screenshots.
- Android packaging on this machine uses the matching installed Flutter engine native libraries through a temporary local Maven mirror to avoid slow duplicate downloads. Application source uses the standard remote Flutter repository and has no dependency on that mirror.
- Android-specific lint and library annotation extraction were skipped for this evaluation APK because they require additional large tool downloads. Flutter static analysis was run. The normal documented flutter build command runs Android checks as configured by Gradle.
- Live hosted REST and physical-device camera scanning have not been verified. A real MockAPI endpoint is required to evaluate persistent REST CRUD. Repository tests verify the HTTP methods, server-generated IDs, response parsing and failure handling using an injected HTTP client.

Android emulator smoke check: APK installed successfully on Pixel 6 / Android 14 (API 34), launched into the dashboard, and emitted no AndroidRuntime/Flutter errors in the checked logs. Native capture: docs/screenshots/android-dashboard.png. Physical camera scanning remains unverified.
