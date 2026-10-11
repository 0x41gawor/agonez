# Agonez Mobile

Android-first Flutter client for Agonez training plans, workouts, and the
exercise atlas. Workout entry is local-first: a session remains usable without
a connection and synchronizes through a durable operation outbox.

The implementation architecture and recovery rules are described in
[`docs/architecture.md`](docs/architecture.md).

## Requirements

- Flutter 3.38.7 or a compatible stable release (Dart 3.10.7)
- JDK 17
- Android SDK 36 and an Android device or emulator
- A reachable Agonez API

Install packages and generate source files from this directory:

```powershell
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
```

The pinned `build_runner` version is intentional for the repository's Dart
toolchain. Commit regenerated localization and Drift output whenever their
inputs change.

## API configuration

There is no implicit server. Every run or build must provide `API_BASE_URL` as
a compile-time Dart definition:

```powershell
flutter run -d <device-id> --dart-define=API_BASE_URL=http://192.46.236.119:33287
flutter build apk --debug --dart-define=API_BASE_URL=http://192.46.236.119:33287
```

The app fails at startup with a configuration error when the definition is
missing. Keep the scheme and port in the value and do not add an API path; the
client appends `/api/v1/mobile/...` itself.

Each request supplies the installation UUID in `X-Agonez-Device-Id`, the app
version in `X-Agonez-Client`, and the selected language in `Accept-Language`.
The installation UUID is persisted in Drift and must not be regenerated per
launch.

### HTTP during development

Cleartext traffic is permitted by
`android/app/src/debug/res/xml/network_security_config.xml` and referenced only
by the debug manifest. Release builds retain Android's secure default, so a
production endpoint must use HTTPS unless a deliberate release policy is added
and reviewed.

A physical phone cannot reach a workstation service through the workstation's
`localhost`. Use a server address reachable from the phone, or reverse a local
port over ADB and point the app at the phone-side loopback address:

```powershell
adb -s <device-id> reverse tcp:33287 tcp:33287
flutter run -d <device-id> --dart-define=API_BASE_URL=http://127.0.0.1:33287
```

## Physical-device run

Enable USB debugging, authorize the workstation on the phone, then verify the
target before launching:

```powershell
adb devices
flutter devices
flutter run -d ZY22LNTRJ6 --dart-define=API_BASE_URL=http://192.46.236.119:33287
```

`ZY22LNTRJ6` is the current Motorola test device; replace it when testing on a
different device. Android 13 and newer ask for notification permission at
runtime. Denying it only disables rest-timer notifications; workout recording
and the in-app timer continue to work.

## Verification

```powershell
dart format lib test
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://192.46.236.119:33287
```

For an end-to-end device smoke test, verify both connected and airplane-mode
workout entry, kill and reopen the app during a workout, restore connectivity,
and confirm the sync state reaches saved before finalization.

## Localization and assets

English and Polish are the supported locales. Edit
`lib/src/l10n/app_en.arb` and `app_pl.arb`, keep their message keys aligned,
then run `flutter gen-l10n`. Runtime locale selection is saved locally and is
also sent to the API.

The offline anatomy surface is `assets/anatomy.svg`; the brand mark is
`assets/brand/agonez-mark.png`. Both are declared in `pubspec.yaml` and ship in
the APK. The app deliberately uses platform fonts: the web project's WOFF2
files are not suitable Flutter font bundles.
