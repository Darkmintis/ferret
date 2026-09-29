# Changelog

All notable changes to this project will be documented in this file.

## [0.2.1]

### Changed

- Release builds (`enableInRelease: true`) mark the bubble with a red border
  instead of the `FERRET ACTIVE` text tag, plus a
  "Ferret active in release build" screen-reader label.
- Bubble keeps a 12px gap from every edge inside the safe area (status bar,
  navigation bar, notches).
- Example app enables Ferret in release builds to show the red border.

### Fixed

- Bubble sometimes started in the top-left corner when the first frame
  reported a 0×0 screen (and could throw); it now waits for the real size.

## [0.2.0]

### Added

- `FerretConfig.maxBodyBytes` (default 256 KB, `null` = unlimited) caps each
  captured request/response body. Truncation is UTF-8 safe, the inspector
  shows a "Truncated" notice, and sizes / HAR still report the full size.
- Tappable URLs in headers and bodies, with a link sheet of icon buttons
  (copy / preview / open).
- Collapsible Headers and Body cards (chevron or tap the title).
- `FerretConfig.onOpenUrl` callback powers "Open" (no `url_launcher`
  dependency).
- **Links** tab listing unique URLs per call, grouped by source.
- Tap-to-load image previews that show the HTTP status on failure;
  `image/*` response bodies render as images instead of raw bytes.

### Fixed

- `Ferret.dioInterceptor` and `Ferret.wrapClient()` read before
  `Ferret.install()` no longer silently capture nothing; both resolve the
  engine per request.
- Streamed `dart:io` request bodies now respect `captureBody` /
  `maxBodyBytes`.

### Changed

- Wider dependency ranges: `share_plus: ">=11.0.0 <14.0.0"` (lets apps on
  `win32` 5, e.g. `file_picker` / `flutter_secure_storage` 9, resolve
  without overrides) and `dio: ^5.4.0`.
- Detail view tabs are scrollable to fit the new Links tab.

## [0.1.1]

### Added

- `FerretConfig.navigatorKey` / `Ferret.navigatorKey` so apps using
  `MaterialApp.router` (or another app-owned navigator) can open the
  inspector without an Overlay-only host.
- Floating bubble: pan-only drag with edge snap, 48px size, process-local
  position memory, and long-press hide until hot reload / hot restart.

### Changed

- README documents GoRouter / shared-navigator setup and bubble behavior.

## [0.1.0]

### Added

- Initial release: Dio / http / dart:io capture, Material 3 inspector,
  call list with search/filters, detail tabs, cURL / HAR export,
  production-safe install gating.
