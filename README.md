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
| Release warning | Often missing | **Always on** — console banner + permanent red bubble border (cannot be disabled) |
| Data in-app | Often masked | **Full raw** bodies & headers |
| Setup | Wire every client | `Ferret.install()` + `builder: Ferret.builder` |

## Install

```yaml
dependencies:
  ferret: ^0.2.1
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

### MaterialApp.router / GoRouter

Wire Ferret's key to the router (same idea as `MaterialApp.navigatorKey`):

```dart
void main() {
  Ferret.install();
  runApp(const MyApp());
}

final _router = GoRouter(
  navigatorKey: Ferret.navigatorKey,
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomePage()),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      builder: Ferret.builder,
    );
  }
}
```

If your app already owns a `GlobalKey<NavigatorState>`, pass it in:

```dart
Ferret.install(config: FerretConfig(navigatorKey: yourNavKey));
// GoRouter(navigatorKey: yourNavKey, …)
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

`Ferret.dioInterceptor` and `Ferret.wrapClient()` are order-independent: you
can create your Dio / http client before `Ferret.install()` (for example in a
DI container) and calls are captured once Ferret is installed and active.

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
    maxBodyBytes: 256 * 1024,   // per body; null = unlimited
    clients: {
      HttpClientType.dio,
      HttpClientType.http,
      HttpClientType.dartIo,
    },
    slowThreshold: Duration(seconds: 2),
    // navigatorKey: yourNavKey, // only if GoRouter / app already owns a key
    // onOpenUrl: (url) => launchUrl(url), // enables "Open" in the link sheet
  ),
);
```

Bodies larger than `maxBodyBytes` are cut at a character boundary; the
inspector shows a "Truncated" notice and sizes still report the full body.

### Links and image previews

URLs in headers and bodies are tappable. Tapping one opens a sheet with icon
buttons: copy, preview (eye, image URLs only) and open (only when `onOpenUrl`
is set). A **Links** tab lists every unique URL in a call, grouped by where it
appeared. `image/*` response bodies render as images.

Headers and body cards have a chevron to collapse long sections.

Ferret has no `url_launcher` dependency; wire it yourself:

```dart
import 'package:url_launcher/url_launcher.dart';

FerretConfig(
  onOpenUrl: (url) => launchUrl(url, mode: LaunchMode.externalApplication),
)
```

> **Security note:** image previews make a real network request from the
> device, but only when you tap the preview (eye) icon. The request does **not** send
> the original call's auth headers, so authenticated images may fail (the
> HTTP status is shown). With `enableInRelease: true` this also applies to
> release builds: only enable it for builds you trust.

### Debug and release behavior

| Mode | Behavior |
|---|---|
| Debug / Profile | On when `enabled: true` (default) |
| Release | **Fully off** unless `enableInRelease: true` |
| Release + `enableInRelease: true` | On, with a loud console warning **and** a permanent red border around the bubble |

When disabled, Ferret does not intercept, store, or render anything.

### Floating bubble

- Count button (48×48), default **center-right** — drag to move, snaps to the nearer edge.
- Remembers position after you close the inspector.
- Flashes **red** briefly when a new failed call arrives.
- **Tap** opens the inspector; **long-press** hides until hot reload / hot restart.
- Hidden while the inspector is open.

## Features

- Floating count button → full inspector
- Call list with method, path, host, status, duration, size
- Detail tabs: Overview · Request · Response · Links · Error
- Tappable URLs, link sheet, tap-to-load image previews
- Body size cap (`maxBodyBytes`) to bound memory
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
