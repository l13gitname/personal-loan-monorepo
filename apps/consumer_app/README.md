# Consumer app (Flutter)

Personal loan and motorcycle loan quotation app. Both products use the same
multi-step flow; only the loan step shows motorcycle fields.

Stack: Flutter, MVVM + Repository, Riverpod, go_router, Dio, Freezed +
json_serializable, flutter_secure_storage, flutter_test + integration_test.

> This code was written without access to a Flutter SDK, so it has **not been
> compiled yet**. Run `./scripts/check-flutter.sh` (or `.ps1`) from the repo
> root first and fix anything it reports. Package versions in `pubspec.yaml`
> could not be checked against pub.dev either.

## First run

```bash
cd apps/consumer_app

# 1. Create the platform folders once (this repo only contains Dart code)
flutter create --org com.yourcompany --project-name consumer_app --platforms android,ios .

# 2. Dependencies and generated code (Freezed / json_serializable)
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 3. Point the app at the API (copy, then edit)
cp env/dev.example.json env/dev.json

# 4. Run
flutter run --dart-define-from-file=env/dev.json
```

Platform settings to add after `flutter create`:

- **Android (debug only):** the emulator reaches the API over plain HTTP.
  In `android/app/src/debug/AndroidManifest.xml` add
  `android:usesCleartextTraffic="true"` to `<application>`. Production must use HTTPS.
- **iOS:** in `ios/Runner/Info.plist` add `NSCameraUsageDescription` and
  `NSPhotoLibraryUsageDescription` (document photos).
- API URLs: Android emulator `http://10.0.2.2:3000/api/v1`, iOS simulator
  `http://localhost:3000/api/v1`, real device `http://<LAN-IP>:3000/api/v1`.

Use `build_runner watch` while developing.

## Structure

```text
lib/
├── main.dart, app.dart
├── core/
│   ├── config/        API_BASE_URL (--dart-define)
│   ├── network/       Dio provider, auth interceptor (bearer + refresh), ApiException
│   ├── router/        go_router with auth redirect
│   ├── storage/       TokenStorage (secure storage) + in-memory fake for tests
│   └── ui/            shared text fields and validators
└── features/<feature>/
    ├── data/          models (Freezed) + repository (the only code that calls Dio)
    └── presentation/  ViewModel (Riverpod Notifier) + screens/widgets
```

Rules: widgets never call Dio; ViewModels never import widgets; repositories
turn `DioException` into `ApiException`.

Features: `auth` (login, session), `catalog` (products + required documents and
consents), `quotation` (list + 6-step form, draft saved on the server after each
step so users can resume), `documents` (multipart upload to server storage).

## Testing

```bash
flutter test                                              # unit + widget
flutter test integration_test --dart-define-from-file=env/dev.json
# with a running backend and a registered user:
flutter test integration_test --dart-define=E2E_BACKEND=true --dart-define-from-file=env/dev.json
```

## CI/CD (GitHub Actions)

- `flutter-ci.yml` - generate code, format check, analyze, test on every PR.
- `flutter-distribute.yml` - build a release APK and upload to Firebase App Distribution.
  Repository secrets: `FIREBASE_ANDROID_APP_ID`, `FIREBASE_SERVICE_ACCOUNT_JSON`,
  `API_BASE_URL_STAGING`, `API_BASE_URL_PRODUCTION`.
- **Signing:** add a release keystore (keep it out of Git; store it as a secret and
  write it in the workflow) before sending builds beyond internal testers.
- iOS distribution needs a macOS runner and Apple signing; add it later.

## Firebase Crashlytics (not wired yet)

1. `dart pub global activate flutterfire_cli && flutterfire configure`
2. Add `firebase_core` and `firebase_crashlytics`, initialize them in `main.dart`,
   and forward `FlutterError.onError` / `PlatformDispatcher.instance.onError`.
3. **Privacy:** never put national ID numbers, names, phone numbers or document
   content in logs, custom keys or breadcrumbs. Use the quotation id only.

## Known gaps

- Brand/model/color are typed as codes; replace with pickers once a master-data API exists.
- Only the main occupation, ID-card and contact addresses are collected.
- No quotation calculation yet (interest/installment): waiting for the pricing rules.
- Non-draft quotations are read-only list items (no detail screen yet).
- No registration screen (use `POST /auth/register` or add one).
