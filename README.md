# CafeConnect v0.1.0-alpha

Staff-only POS app for café/restaurant. Waiters, kitchen, bar, managers — no customer app, no QR.

## Run
```bash
flutter pub get
flutter run -d chrome        # or: flutter run -d macos
# NOTE: Do NOT use `flutter run -d web-server` — the DWDS devserver crashes on Flutter 3.44.3
```

## Tech stack
Flutter 3.44 · Material 3 · Provider · GoRouter · Hive · google_fonts · flutter_animate

## Status
v0.1.0-alpha. All core waiter flows functional. Data persists via Hive. Settings screen live.

## Reset demo data
Settings → Данные → Сброс к демо-данным
