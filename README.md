# CafeConnect

CafeConnect is a Flutter implementation of the supplied FlutterFlow MVP brief. It includes role-based flows for client, waiter, cook, bartender, and manager, Russian UI copy, reusable Apple-style components, local/offline state, mock REST/WebSocket behavior, and animated interactions.

## What is included

- QR/manual table entry
- Client menu, dish bottom sheet, cart, and order status
- Waiter table grid and table order mode
- Kitchen and bar order feeds
- Staff chat list and chat screen
- Manager dashboard, team management, menu management, and editor forms
- Shared components: app buttons, cards, category chips, menu grid items, order cards, status badges, staff rows, chat bubbles, steppers, and hero carousel
- Local app state with seeded users, tables, menu, orders, staff, groups, messages, drafts, and offline queue

## Run locally

Flutter is not installed in this workspace, so the app was not built here. On a machine with Flutter 3.x:

```bash
flutter create .
flutter pub get
flutter run
```

The app is portrait-oriented in code and uses mock services by default. Replace `MockCafeApi` and `MockRealtimeHub` in `lib/main.dart` with real REST and WebSocket implementations when the backend is ready.

## Demo logins

- Client: `client` / `1234`
- Waiter: `waiter` / `1234`
- Cook: `cook` / `1234`
- Bartender: `bar` / `1234`
- Manager: `manager` / `1234`
