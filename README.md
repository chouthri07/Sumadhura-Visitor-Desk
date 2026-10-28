# Sumadhura Visitor Desk

Flutter Android application for front-desk visitor registration, QR passes and one-session entry/exit tracking.

## Screenshots (Redmi Android)

Screenshots captured on a Redmi Android phone. Click any image to view it at full size. The dashboard and visitor list show local demo mode.

| Dashboard | Visitors | Register visitor |
|:---:|:---:|:---:|
| <a href="docs/screenshots/redmi-dashboard.jpeg"><img src="docs/screenshots/redmi-dashboard.jpeg" alt="Redmi Android visitor dashboard" width="240"></a> | <a href="docs/screenshots/redmi-visitors.jpeg"><img src="docs/screenshots/redmi-visitors.jpeg" alt="Visitor list with search and status filters" width="240"></a> | <a href="docs/screenshots/redmi-registration.jpeg"><img src="docs/screenshots/redmi-registration.jpeg" alt="Visitor registration form" width="240"></a> |

| Scan visitor pass | Visitor QR pass |
|:---:|:---:|
| <a href="docs/screenshots/redmi-scanner.jpeg"><img src="docs/screenshots/redmi-scanner.jpeg" alt="QR scanner and manual visitor ID lookup" width="240"></a> | <a href="docs/screenshots/redmi-visitor-pass.jpeg"><img src="docs/screenshots/redmi-visitor-pass.jpeg" alt="Visitor QR pass showing checked out status" width="240"></a> |

## Run now

Developed with Flutter **3.44.1**, Dart **3.12.1**, Java **17**.

```powershell
flutter pub get
flutter run -d emulator-5554
# Or run in Chrome (camera requires browser permission):
flutter run -d chrome
```

No login or credentials are required. The default build opens a clearly labelled **local demo** with an empty visitor list. Register your own test visitor; records persist on this device. Local demo is provided for checking the flow without an API account and does **not** satisfy the assignment's mandatory live REST requirement.

## Connect a persistent mock REST API

No backend code or server deployment is required. Create a project at https://mockapi.io and a `visitors` resource. Its full URL normally resembles `https://<project-id>.mockapi.io/api/v1/visitors`.

Keep MockAPI's server-generated `id` field. Add these fields (use String for mobile, not Number):

| Field | Type | Notes |
|---|---|---|
| name | String | Required |
| mobile | String | Exactly 10 digits |
| email | String | Optional; app sends null when blank |
| visitor_type | String | Customer, Vendor, Other |
| project | String | Project A, Project B, Project C |
| purpose | String | Required |
| status | String | Registered, Checked In, Checked Out |
| created_at | String | ISO 8601 timestamp |
| check_in_time | String | ISO 8601 timestamp or null |
| check_out_time | String | ISO 8601 timestamp or null |

Start with an empty resource; automatically generated mock rows may not match the required enum values. Register test visitors through the app. Open the gear icon on the dashboard, paste the collection URL and save. Configuration survives restarts. The local demo banner disappears in API mode. Switching modes does not upload demo records or delete them.

Alternatively configure the URL at build time (a saved in-app setting takes precedence):

```powershell
flutter run --dart-define=API_BASE_URL=https://YOUR-PROJECT.mockapi.io/api/v1/visitors
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-PROJECT.mockapi.io/api/v1/visitors
```

The API must remain available during evaluation. Never put production credentials or secrets in the app. Only HTTPS is supported.

### REST contract

| Method | Path relative to configured URL | Operation |
|---|---|---|
| GET | / | List (JSON array) |
| GET | /{id} | Retrieve one visitor |
| POST | / | Create; server returns visitor including generated ID |
| PUT | /{id} | Edit or update status; returns updated visitor |
| DELETE | /{id} | Delete |

The URL already includes `/visitors`. Requests time out after 20 seconds. Non-2xx, missing records, malformed JSON and network errors are shown to the user. A failed REST request never silently switches to local storage. Create requests omit `id`; QR data is the returned API ID only.

## Architecture

```text
lib/
  main.dart                           starts the app
  bootstrap.dart                      saved API configuration and storage selection
  app.dart                            app theme
  models/visitor.dart                  visitor fields, JSON, status rules, date helpers
  repositories/
    visitor_repository.dart           storage contract and user-facing exception
    local_visitor_repository.dart     saves demo records on this device
    api_visitor_repository.dart       sends HTTPS requests to the configured API
  providers/visitor_store.dart         shared state, search, filters and actions
  screens/                            dashboard, form, details, scanner, settings
  widgets/common_widgets.dart         reusable cards, status chips and feedback
```

Start reading at `main.dart`, then `bootstrap.dart`, then `app.dart` and
`screens/home_screen.dart`. Screens call `providers/visitor_store.dart`, which
calls a repository to read or save records. The repository returns `Visitor`
models and the store updates the screens.

**Storage in simple terms:** an empty API URL selects local demo mode. Visitor
records are saved as JSON in SharedPreferences on the device (browser storage
when running on the web), not in a SQL database. This mode needs no internet.
A configured API URL selects online mode: the app sends GET, POST, PUT and
DELETE requests over HTTPS, and the API server handles storage. This project
does not include that server or determine whether its database uses SQL.
Existing local records and the saved API URL keep the same storage keys after
the folder reorganization, so no data migration is needed.

Provider is sufficient for a small app: a single VisitorStore owns visitor records and mutations, so the dashboard, list and pass use the same state. Widgets do not make HTTP calls. Repositories can be replaced in tests. A save guard prevents concurrent actions in one app instance. Transitions fetch the latest record before validating. Returning updated API records immediately synchronizes every screen; pull-to-refresh and the refresh button fetch external changes. Collection loads started before a mutation cannot overwrite that mutation's result.

Timestamps are stored as UTC ISO 8601 and displayed in the device's local time. Today's counts compare local calendar dates. Dashboard refreshes its local date every minute and on app resume.

## Features and flow

1. Register a visitor: required name/purpose, exactly 10 mobile digits, optional validated email, type and project.
2. Successful registration opens the QR pass with initial Registered status.
3. Check in; the pass becomes Checked In and dashboard occupancy increases.
4. Check out; timestamps are retained and the visit is complete. A completed registration cannot be reused.
5. Search by name/mobile; filter by project/status; edit and delete after confirmation.
6. Scan the pass on a second screen/device. The scanner retrieves its visitor and opens their pass. Scanning never changes status automatically. A lookup guard and duplicate detection prevent repeated navigation. Use Scan again to re-arm.
7. Camera denial shows a meaningful message; manual ID lookup remains available. Grant permission in Android settings and retry.

## Packages

- provider: shared application state
- http: asynchronous REST requests
- qr_flutter: QR pass rendering
- mobile_scanner: camera QR detection (bundled ML Kit on Android)
- shared_preferences: explicit demo persistence and API configuration
- intl: local date/time display

Exact resolved versions are recorded in pubspec.lock. Scanner documentation: https://pub.dev/packages/mobile_scanner

## Validate and build

```powershell
flutter analyze
flutter test
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`. Release builds currently use the Flutter template's debug signing key for evaluation; configure your own signing key before store distribution. Android CAMERA and INTERNET permissions are declared. No gallery permissions are requested.

## Manual acceptance checks

- Empty list, form errors, keyboard scrolling on a small screen.
- Register, edit without changing visit status, search and project/status filters.
- Generate pass, scan it, handle invalid QR and unknown IDs.
- Registered -> Checked In -> Checked Out; verify counts and both timestamps.
- Restart app and verify persisted records (also verify from another client in API mode).
- Cancel/confirm deletion; verify list and dashboard update.
- Deny camera permission; test recovery and manual ID lookup.
- Disconnect internet in API mode; verify retry and failed-save messages.

## Limitations and submission status

- No hosted API account/endpoint was supplied. Live REST operation requires the short MockAPI setup above. The provided default APK is for local flow testing, not a claim of completed live API evaluation.
- MockAPI has no atomic compare-and-swap, authentication or role enforcement here. Multiple devices could race to change one visit; server-side transactional enforcement is outside this frontend assignment.
- Camera scanning must be verified on a physical Android device; emulator camera availability varies. Windows desktop camera scanning is unsupported by mobile_scanner; Android and web are the intended run targets.
- No login, repeat-visit history or production data handling is included.
- GitHub publishing needs your repository/account. This project can be pushed once you choose the repository; no remote is assumed.
- This implementation was produced with AI assistance. The supplied assignment disallows AI tools; clarify acceptance with the recruiting team before submission.

## Verification performed

- `flutter analyze`: clean.
- `flutter test`: six tests passed (lifecycle persistence, metrics, QR validation, HTTP contract/error handling and registration UI).
- `flutter build web`: passed.
- Chrome browser flow: registered Rahul Sharma, opened QR pass, checked in and checked out successfully.
- The screenshots above were supplied from a Redmi Android phone. The scanner image shows the scanner screen; it does not by itself verify a successful QR scan.

Android build configuration: Gradle 8.14.3, Android Gradle Plugin 8.11.1, Kotlin 2.2.20, minimum Android API 24. Initial Android builds may take several minutes while downloading Flutter engine and ML Kit artifacts.

Sample API record: [docs/sample-visitor.json](docs/sample-visitor.json). Omit `id` when posting a new record; let the service generate it.

[Dashboard](docs/screenshots/redmi-dashboard.jpeg) | [Visitors](docs/screenshots/redmi-visitors.jpeg) | [Registration](docs/screenshots/redmi-registration.jpeg) | [Visitor pass](docs/screenshots/redmi-visitor-pass.jpeg) | [Scanner](docs/screenshots/redmi-scanner.jpeg)


Android release APK: successfully built at build/app/outputs/flutter-apk/app-release.apk (69,550,079 bytes). Android lint was skipped as described in docs/verification.md.

Android emulator installation and launch also passed; see the [Redmi dashboard capture](docs/screenshots/redmi-dashboard.jpeg).
