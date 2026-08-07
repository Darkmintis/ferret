# Ferret example

A simple social-feed demo for [`ferret`](https://pub.dev/packages/ferret).

## Run

```bash
# JDK 17 or 21 recommended for Android (Gradle 8.14)
cd example
flutter run
```

If Gradle fails with `IllegalArgumentException: 25.0.2`:

```bash
flutter config --jdk-dir=/usr/lib/jvm/temurin-21-jdk-amd64
```

## What it shows

- Loads posts + users from `jsonplaceholder.typicode.com` (social feed UI)
- Tap a post to load comments
- FAB creates a post (Dio POST)
- Menu runs extra demos: `package:http`, `dart:io`, and a deliberate 404

Open the Ferret floating count button to inspect every request.
