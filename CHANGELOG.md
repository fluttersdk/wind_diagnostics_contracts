# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0-alpha.1]

### Added

- Initial release: `WindDebugResolver` abstract contract + `WindDebugRegistry` static registry for cross-package wind state lookup without compile-time coupling. Used by `fluttersdk_wind` to expose runtime widget state and by `fluttersdk_dusk` (or any other debug-tooling package) to consume that state via the neutral bridge.
