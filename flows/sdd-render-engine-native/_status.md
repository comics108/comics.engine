# Status: sdd-render-engine-native

## Current Phase

SPECIFICATIONS

## Phase Status

READY FOR REVIEW

## Last Updated

2026-05-07 by Claude Opus 4.5

## Blockers

- None

## Progress

- [x] Requirements drafted
- [ ] Requirements approved
- [x] Specifications drafted (with Flutter API)
- [ ] Specifications approved
- [x] Plan drafted
- [ ] Plan approved
- [x] Implementation started (Dart API created)
- [ ] Implementation complete
- [ ] Documentation drafted
- [ ] Documentation approved

## Context Notes

- Extracted legacy render behavior from:
  - `legacy/legacy-bhagavadgita-render-engine-web-css/` (CreateJS/Adobe Animate canvas export)
  - `legacy/legacy-mahabharata-render-engine-android-java/` (View+Canvas tiling + zoom/pan)
  - `legacy/legacy-mahabharata-render-engine-ios-swift/` (CATiledLayer tiling + UIScrollView zoom)
- Key shared invariant across Android+iOS: **tile size = 512** and **tile filename template uses `{0}{1}{2}`** where `{0}=zoom*1000`, `{1}=col`, `{2}=row`.
- **Decision**: `.comics` archive path передаётся целиком в нативную часть

## Dart API Created

- `lib/flutter_comics.dart` — main export
- `lib/src/models.dart` — ComicsInfo, HitTestResult, ScrollEvent, LayerTapEvent, ComicsConfig
- `lib/src/comics_viewer.dart` — ComicsViewer widget
- `lib/src/comics_viewer_controller.dart` — ComicsViewerController

## Next Actions

1. Review and approve specifications (`02-specifications.md`)
2. Adapt native code (fix package names, remove legacy dependencies)
3. Implement Platform View factories (Android + iOS)
4. Wire up Method Channel handlers
