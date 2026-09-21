# Changelog

All notable changes to this project will be documented in this file.

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
