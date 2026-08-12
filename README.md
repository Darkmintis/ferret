# Ferret

Modern HTTP inspector for Flutter — zero setup, production-safe, raw visibility.

**See everything. Ship nothing you didn't mean to.**

[![pub package](https://img.shields.io/pub/v/ferret.svg)](https://pub.dev/packages/ferret)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Ferret captures Dio, `package:http`, and `dart:io` traffic into a Material 3 inspector: floating bubble, call list, raw detail, and cURL / HAR export.

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
      builder: Ferret.builder, // floating bubble (center-right by default)
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

### Platform support

| Platform | Dio | package:http | dart:io |
|---|---|---|---|
| Android / iOS / macOS / Windows / Linux | ✓ | ✓ | ✓ |
| Web | ✓ | ✓ | — (not available) |

On web, use `Ferret.createDio()` or `Ferret.wrapClient()` — the inspector UI and HAR/cURL export work the same.

## Configuration

```dart
Ferret.install(
  config: const FerretConfig(
    enabled: true,              // master switch (debug/profile)
    enableInRelease: false,     // set true only when you intentionally need release
    maxEntries: 500,            // ring buffer size
    captureBody: true,
    clients: {
      HttpClientType.dio,
      HttpClientType.http,
      HttpClientType.dartIo,
    },
    slowThreshold: Duration(seconds: 2),
  ),
);
```

### Debug and release behavior

| Mode | Behavior |
|---|---|
| Debug / Profile | On when `enabled: true` (default) |
| Release | **Fully off** unless `enableInRelease: true` |
| Release + `enableInRelease: true` | On, with a loud console warning **and** a permanent red **FERRET ACTIVE** tag |

When disabled, Ferret does not intercept, store, or render anything.

### Floating bubble

- Circular count button, default position **center-right** (drag to move).
- Flashes **red** briefly when a new failed call arrives.
- **Tap** opens the full inspector.
- Hidden while the inspector is open.

## Features

- Floating count button → full inspector
- Call list with method, path, host, status, duration, size
- Detail tabs: Overview · Request · Response · Error
- Search & filters (method, failed, slow)
- Copy as cURL (per call)
- Share / copy session as HAR

## Repository

https://github.com/darkmintis/ferret

## Example

```bash
git clone https://github.com/darkmintis/ferret.git
cd ferret
fvm use 3.44.1
cd example
flutter run
```

## API surface

```dart
Ferret.install(config: ...);
Ferret.navigatorKey
Ferret.builder
Ferret.createDio([options])
Ferret.dioInterceptor
Ferret.wrapClient(client)
Ferret.openDashboard()
Ferret.clear()
Ferret.toCurl(entry)
Ferret.toHar(redact: false)
Ferret.shareSession(redact: false)
Ferret.shareCurl(entry)
Ferret.isActive
```

## Requirements

- Flutter `>=3.44.0`
- Dart `^3.12.1`

## License

MIT © Darkmintis
