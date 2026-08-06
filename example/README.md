# Ferret example

Minimal demo app for [`ferret`](https://pub.dev/packages/ferret).

## Run

```bash
# from repo root, with Flutter 3.44.1+ (FVM recommended)
cd example
flutter run
```

## What it shows

Buttons fire real HTTP calls via:

1. **Dio** — GET / POST
2. **package:http** — GET
3. **dart:io** — GET
4. A deliberate **404** so you can see failed-call highlighting

Open the Ferret bubble to inspect method, URL, status, headers, and bodies.
