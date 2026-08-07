# Ferret example

Minimal demo app for [`ferret`](https://pub.dev/packages/ferret).

## Run

```bash
# from repo root, with Flutter 3.44.1+ (FVM recommended)
# Android builds need JDK 17 or 21 (Gradle 8.14 does not support Java 25)
cd example
flutter run
```

If Gradle fails with `IllegalArgumentException: 25.0.2`, point Flutter at JDK 21:

```bash
flutter config --jdk-dir=/usr/lib/jvm/temurin-21-jdk-amd64
```

## What it shows

Buttons fire real HTTP calls via:

1. **Dio** — GET / POST
2. **package:http** — GET
3. **dart:io** — GET
4. A deliberate **404** so you can see failed-call highlighting

Open the Ferret bubble to inspect method, URL, status, headers, and bodies.
