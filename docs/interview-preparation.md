# Visitor App - Interview Preparation

## About the app

### 1. What does this app do?

This is a Flutter visitor management app. It registers visitors, creates QR passes, and records check-in and check-out.

### 2. Which technology did you use?

Flutter and Dart for the app, Provider for state management, SharedPreferences for local storage, and the http package for API requests.

### 3. What is the basic app flow?

Register a visitor, open the QR pass, check the visitor in, and then check the visitor out. Users can also search, filter, edit, and delete visitors.

## Storage and API

### 4. Does the app work locally?

Yes. With no API URL configured, it runs in local demo mode and saves visitor records on the device. No internet is needed for local saving.

### 5. Are you using SQL or SQLite?

No. The current local implementation uses SharedPreferences. Visitor records are converted to JSON text and saved there.

### 6. How does the app choose local storage or the API?

It checks whether the configured API URL is empty. An empty URL selects local storage. A non-empty URL selects the API. It does not choose based on internet availability.

### 7. In which file is that check?

lib/bootstrap.dart, inside the build method. The check is: url.isEmpty ? LocalVisitorRepository(widget.preferences) : ApiVisitorRepository(url).

### 8. Where does the API URL come from?

The app first reads the saved api_url setting from SharedPreferences. If no setting exists, it reads API_BASE_URL supplied at build time. The user can change it in API Settings.

### 9. What is stored in SharedPreferences?

The API URL is saved under api_url. Local demo visitor records are saved as JSON under demo_visitors_v1. In API mode, visitor records are sent to the API rather than saved as a local cache.

### 10. What happens when the internet is unavailable in API mode?

The request fails and the app shows an error. It does not automatically switch to local storage or queue the change for later.

### 11. Which API methods are used?

GET reads visitors, POST creates a visitor, PUT updates a visitor or status, and DELETE removes a visitor. The configured URL must use HTTPS.

### 12. Where is the data saved in API mode?

The app sends JSON to the configured server. That server handles storage. This Flutter project does not include the server database, so I cannot say whether it uses SQL.

### 13. Do local demo records upload when you switch to API mode?

No. Switching modes does not upload local records. Local and API records remain separate.

### 14. Have you tested a live API?

The automated tests check API requests using a simulated server. They do not prove that a real hosted API works. A live API must be configured and tested separately.

## State management and code structure

### 15. Which state management did you use?

Provider with ChangeNotifier. VisitorStore holds shared visitor data and tells the screens when it changes.

### 16. Where is state management implemented?

lib/providers/visitor_store.dart contains VisitorStore. lib/bootstrap.dart makes it available to the app through ChangeNotifierProvider.

### 17. What does notifyListeners do?

It tells listening widgets that the data changed, so they can rebuild and show the latest values.

### 18. Why use a repository?

A repository handles reading and saving data. Screens call VisitorStore, and VisitorStore calls the repository. This keeps storage and HTTP code out of the screens.

### 19. How is the code organized?

models contains visitor data and rules. screens contains pages. providers contains shared state. repositories contains local and API storage. widgets contains reusable UI. main.dart starts the app; bootstrap.dart selects storage; app.dart sets up the theme and home screen.

### 20. What is in common_widgets.dart?

StatusChip shows the visitor status. VisitorCard shows visitor information and actions. EmptyState shows an empty-list message. displayTime formats dates, showMessage displays a snackbar, and runAction handles success or error messages.

## Visitor rules and testing

### 21. What is inside the Visitor model?

It stores the visitor ID, name, mobile, email, type, project, purpose, status, and timestamps. It also converts JSON and validates status transitions.

### 22. How does the QR code work?

The QR contains only the visitor ID. Scanning uses that ID to look up the visitor and open the pass. Scanning does not automatically check the visitor in.

### 23. What are the allowed visitor statuses?

Registered, Checked In, and Checked Out. The normal flow is Registered to Checked In to Checked Out. A completed visit cannot be checked in again.

### 24. How are screens updated after saving?

VisitorStore updates its visitor list with the saved record and calls notifyListeners. Listening screens then show the latest data.

### 25. How did you verify the app?

Code analysis passed, all six automated tests passed, and the web build succeeded. Tests cover local persistence, visitor status rules, date counts, QR validation, API requests and errors, and registration with check-in.

### 26. What are the current limitations?

A real API URL must be supplied for online storage. The app has no login or automatic offline sync. Physical camera scanning still needs testing on an Android device.

