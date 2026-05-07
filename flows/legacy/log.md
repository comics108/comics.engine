# Legacy Analysis Log

## Session History

### 2026-05-07 - Depth 0 (Root Analysis)

**Mode**: BFS
**Target**:
- `legacy/legacy-bhagavadgita-render-engine-web-css/`
- `legacy/legacy-mahabharata-render-engine-android-java/`
- `legacy/legacy-mahabharata-render-engine-ios-swift/`

**Analyzed**:

#### Web CSS (Bhagavadgita)
- `Anim1_HTML5 Canvas.js`: CreateJS/Adobe Animate export
  - Timeline-based animations (24 fps)
  - Sprite sheet metadata with atlas references
  - Tween-based transformations (scale, rotate, translate)
  - Stage dimensions: 1080x1440 px
  - Reference implementation for visual verification

#### Android Java (Mahabharata)
- `TileImageView.java`: Тайловый рендеринг
  - TILE_SIZE = 512 px
  - ZOOM_LEVELS = [1.0, 0.5, 0.25, 0.125]
  - Template: `{0}{1}{2}` (zoom*1000, col, row)
  - Hit-testing via alpha channel sampling
  - LRU bitmap cache via CacheManager

- `ZoomFrameLayout.java`: Zoom/Pan контейнер
  - Matrix-based transformations
  - GestureDetector + ScaleGestureDetector
  - FitMode: VERTICAL/HORIZONTAL
  - Fling animation support

- `Layer.java`: Модель слоя
  - Sorted animation lists (translate, rotate, scale, alpha)
  - `buildMatrixAndAlpha(scrollOffset)` method
  - Inverse matrix for hit-testing

- `Comics.java`: Корневая модель
  - `process(scrollOffset)` orchestration
  - Sound management
  - Sample size calculation

- Animation classes (`TranslateAnim`, `RotateAnim`, `ScaleAnim`, `AlphaAnim`):
  - Cubic easing: `(f-1)³+1`
  - Linear interpolation between keyframes
  - Pivot-based rotate/scale

#### iOS Swift (Mahabharata)
- `TileImageView.swift`: CATiledLayer-based rendering
  - `CATiledLayerNoAnim` with fadeDuration=0
  - contentScaleFactor forced to 1 for retina
  - Tile name generation identical to Android

- `ImageScrollView.swift`: UIScrollView container
  - 3x viewport for preload margin
  - `prepareTiles()` / `killTiles()` lifecycle
  - Sound playback via SoundManager
  - Point sounds (single trigger) vs Range sounds (loop)

- `Layer.swift`: Layer model (identical structure to Android)
  - CATransform3D-based matrix
  - Same animation interpolation logic

- `Comics.swift`: Scene model
  - Identical API to Android version

**Created**:
- Detailed Russian specifications were split:
  - Android: `../sdd-comics-engine-flutter-android/specifications-ru.md`
  - iOS: `../sdd-comics-engine-flutter-ios/specifications-ru.md`
  - Web: `../sdd-comics-engine-flutter-web/specifications-ru.md`
  - Unity: `../sdd-comics-engine-csharp-unity/specifications-ru.md`
  - Format: `../sdd-comics-format/02-specifications-ru.md`
- Created `flows/legacy/understanding/_root.md`: Root analysis document

**ADR Candidates Identified**:
1. ADR-001: Tile Naming Convention (`{0}{1}{2}`)
2. ADR-002: Tile Size (512x512 px)
3. ADR-003: Animation Application Order (Scale → Rotate → Translate)
4. ADR-004: Cubic Easing Function (`(f-1)³+1`)

**Key Findings**:
- Android and iOS implementations are architecturally identical
- Same JSON data format for content (Comics, Layer, Image, Animation)
- Web export serves as visual reference, not direct port target
- Critical invariants:
  - Tile size must remain 512 for content compatibility
  - Tile naming must use `{0}{1}{2}` pattern
  - Animation order must be Scale → Rotate → Translate
  - Cubic easing must use `(f-1)³+1` formula

**Next depth**:
- [COMPLETE] No further depth needed for render engine specification
- Ready for implementation phase

---

*Append new entries at the top.*
