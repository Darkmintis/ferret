# Ferret example

Minimal demo for [`ferret`](https://pub.dev/packages/ferret).

## Run

```bash
cd example
flutter run
```

## What it shows

Four buttons = four Ferret use cases:

| Button | What it demos |
|--------|----------------|
| **Load posts** (green) | Dio GET + response body + posts list |
| **Create post** (blue) | Dio POST + request body |
| **http GET** (purple) | `package:http` client capture |
| **Trigger error** (red) | Failed call → Ferret **Error** tab |

Open the Ferret bubble after each tap to inspect the call.
