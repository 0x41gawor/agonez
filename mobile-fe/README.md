# Agonez Mobile

Android workout execution client for Agonez. SQLite is the durable workout notebook; the API is synchronized using ordered, idempotent operations.

## Development

```powershell
flutter run -d ZY22LNTRJ6 --dart-define=API_BASE_URL=http://192.46.236.119:33287
flutter build apk --debug --dart-define=API_BASE_URL=http://192.46.236.119:33287
```

`API_BASE_URL` is compile-time configuration. The current endpoint is HTTP development infrastructure and will move behind HTTPS/Caddy. Cleartext traffic is enabled only in the debug manifest.

See [docs/architecture.md](docs/architecture.md) for persistence, identity, synchronization, conflicts, offline lifecycle, Atlas assets, localization and testing.
