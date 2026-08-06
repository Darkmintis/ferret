# Ferret

Modern HTTP inspector for Flutter — zero setup, production-safe, raw visibility.

**See everything. Ship nothing you didn't mean to.**

[![pub package](https://img.shields.io/pub/v/ferret.svg)](https://pub.dev/packages/ferret)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Ferret captures Dio, `package:http`, and `dart:io` traffic into a Material 3 inspector: floating bubble, request list, raw detail, timeline, diff, cURL/HAR export, session share, replay, and an optional LAN mirror.

## Why Ferret

| | Alice / others | Ferret |
|---|---|---|
| Release builds | Easy to leave on by accident | **Off by default** — true no-op |
| Forced on in release | Easy to miss | Loud console banner + permanent red tag |
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
    enableInRelease: false,     // must be explicit for release
    showReleaseWarning: true,   // banner + red "FERRET ACTIVE" tag
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

### Release safety

| Mode | Behavior |
|---|---|
| Debug / Profile | On when `enabled: true` (default) |
| Release | **Fully off** unless `enableInRelease: true` |
| Release + forced on | Console warning + permanent on-screen tag |

When disabled, Ferret does not intercept, store, or render anything.

## Features

- Floating draggable bubble (tap to open, long-press to minimize)
- Live call list — method, URL, status, duration, size
- Raw request/response detail with JSON formatting
- Search & filters — method, failed-only, slow-only
- Timeline / waterfall view
- Side-by-side response diff
- Copy as cURL
- HAR export & share session (optional redaction **on export only**)
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

The example fires real requests with Dio, `package:http`, and `dart:io` against a public API so you can see each client in the inspector.

## API surface

```dart
Ferret.install(config: ...);
Ferret.builder                 // MaterialApp / CupertinoApp builder
Ferret.createDio([options])
Ferret.dioInterceptor
Ferret.wrapClient(client)
Ferret.showOverlay(context)    // optional manual overlay
Ferret.openDashboard(context)
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
