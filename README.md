# Ferret

Modern HTTP inspector for Flutter — zero setup, production-safe, raw visibility.

**See everything. Ship nothing you didn't mean to.**

[![pub package](https://img.shields.io/pub/v/ferret.svg)](https://pub.dev/packages/ferret)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Ferret captures Dio, `package:http`, and `dart:io` traffic into a Material 3 inspector: floating bubble, request list, raw detail, timeline, diff, cURL/HAR export, session share, replay, and an optional LAN mirror.

## Why Ferret

Most Flutter HTTP inspectors are **debug-only**. They are not designed to run safely in release builds.

Ferret is different:

| | Typical inspectors | Ferret |
|---|---|---|
| Debug / profile | On | On by default |
| Release builds | Usually unavailable or unsafe | **Off by default** (true no-op) |
| Opt-in release mode | Rare / not supported | Supported via `enableInRelease: true` |
| Release warning | Often missing | **Always on** — console banner + permanent red tag (cannot be disabled) |
| Data in-app | Often masked | **Full raw** bodies & headers |
| Setup | Wire every client | `Ferret.install()` + `builder: Ferret.builder` |

## Install

```yaml
dependencies:
  ferret: ^0.1.0
```

```bash
flutter pub get
```

## Quick start

```dart
import 'package:ferret/ferret.dart';
import 'package:flutter/material.dart';

void main() {
  Ferret.install();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: Ferret.navigatorKey,
      builder: Ferret.builder, // floating bubble
      home: const HomePage(),
    );
  }
}
```

### Capture traffic

```dart
// Dio — recommended
final dio = Ferret.createDio();
// or attach to an existing instance:
dio.interceptors.add(Ferret.dioInterceptor);

// package:http
final client = Ferret.wrapClient(http.Client());

// dart:io HttpClient — captured automatically after install (mobile/desktop)
```

## Configuration

```dart
Ferret.install(
  config: const FerretConfig(
    enabled: true,              // master switch (debug/profile)
    enableInRelease: false,     // set true only when you intentionally need release
    showNotification: true,     // ongoing notification with live counts
    maxEntries: 500,            // ring buffer size
    captureBody: true,
    startMinimized: true,
    clients: {
      HttpClientType.dio,
      HttpClientType.http,
      HttpClientType.dartIo,
    },
    slowThreshold: Duration(seconds: 2),
    // mirrorPort: 7474,        // optional LAN mirror
  ),
);
```

### Debug and release behavior

| Mode | Behavior |
|---|---|
| Debug / Profile | On when `enabled: true` (default) |
| Release | **Fully off** unless `enableInRelease: true` |
| Release + `enableInRelease: true` | On, with a loud console warning **and** a permanent red **FERRET ACTIVE** tag |

The release warning is **not configurable**. If Ferret is running in a release build, the banner and red tag always appear so it is impossible to ship capture silently.

When disabled, Ferret does not intercept, store, or render anything.

### Floating bubble + notification

- **Bubble** is a simple circular button with the **API call count** only. It flashes **red** briefly when a new failed call arrives. **Tap** opens the full inspector (requests, responses, errors, export).
- **Notification** (default on) shows a live status line like `24 calls · 3 failed · 1 slow`. Set `showNotification: false` to disable. On Android 13+ the host app needs `POST_NOTIFICATIONS`.

## Features

- Simple floating count button — tap for full inspector
- Flashes red briefly on new errors
- Ongoing notification with calls / failed / slow counts
- Live call list — method, URL, status, duration, size
- Raw request/response detail with JSON formatting
- Search & filters — method, failed-only, slow-only
- Timeline / waterfall view
- Side-by-side response diff
- Export & share: **HAR**, **JSON**, **text**, **Markdown** (+ redacted HAR)
- Copy as cURL (per call)
- Replay a captured request
- Optional LAN mirror (`mirrorPort`) for desktop viewing

## Example

```bash
git clone https://github.com/darkmintis/ferret.git
cd ferret
fvm use 3.44.1   # or use your Flutter 3.44.1+ SDK
cd example
flutter run
```

The example is a small social feed: it loads posts/users/comments over Dio, with menu actions for `package:http`, `dart:io`, and a deliberate 404 so you can inspect every client in Ferret.

## API surface

```dart
Ferret.install(config: ...);
Ferret.navigatorKey           // attach to MaterialApp
Ferret.builder                // MaterialApp / CupertinoApp builder
Ferret.createDio([options])
Ferret.dioInterceptor
Ferret.wrapClient(client)
Ferret.showOverlay(context)    // optional manual overlay
Ferret.openDashboard()         // opens inspector
Ferret.clear()
Ferret.toCurl(entry)
Ferret.toHar(redact: false)
Ferret.shareSession(redact: false)
Ferret.replay(entry)
Ferret.isActive
```

## Requirements

- Flutter `>=3.44.0`
- Dart `^3.12.1`

## License

MIT © Darkmintis
