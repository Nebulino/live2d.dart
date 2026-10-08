# Changelog

All notable changes to this project will be documented in this file.

## [1.0.1] - 2026-10-08

### Changed
- Relicensed the package under the **MIT License** (was Nebulino Public License).
- Added automated publishing to pub.dev via GitHub Actions (OIDC) with a
  release gate on the `publish` branch.

## [1.0.0] - 2026-10-08

### Added
- **`Live2DViewer` widget**: Interactive Flutter widget to render Live2D Cubism models seamlessly over a transparent background via WebGL and WebView.
- **`Live2DController`**: High-level reactive controller (`ValueNotifier<Live2DState>`) for model loading, motion playback, expressions, hit area events, scaling, positioning, and direct parameter tuning.
- **`Live2DAssetServer`**: Built-in zero-config loopback HTTP server that enables loading models directly from Flutter `rootBundle` assets or local filesystem files without CORS or sandbox restrictions.
- Support for both **Live2D Cubism 4/5** (`.model3.json`, `.moc3`) and **Live2D Cubism 2.1** (`.model.json`, `.moc`).
- Built-in pointer tracking (`lookAt` & auto-interaction) and hit-area event detection (`onHit`).
- Cross-platform support across Android, iOS, macOS, Windows, and Web.
- **`DefaultParameterID`**: Comprehensive constants for standard Live2D model parameter and hit area IDs.
- Full sample demonstration application in `example/`.
