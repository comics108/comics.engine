# Requirements: Native render engine plugin (tiling + layers)

> Version: 1.0  
> Status: DRAFT  
> Last Updated: 2026-05-07

## Problem Statement

`flutter_comics` needs a **native-backed render engine** (Android+iOS) that reproduces the legacy behavior of:

- **Mahabharata Android (Java)**: zoom/pan container + tiled bitmap rendering + layer transforms + hit-testing support.
- **Mahabharata iOS (Swift)**: UIScrollView-based zoom + CATiledLayer rendering + layer transforms + “load tiles only near viewport” memory behavior.
- **Bhagavadgita web (CreateJS export)**: reference for timeline/asset-manifest style rendering (not 1:1 required in v1, but informs asset packaging + animation expectations).

The engine will be shipped as a **Flutter plugin** with **native implementations**.

## User Stories

### Primary

**As a** Flutter screen showing a comics episode  
**I want** to display a very large composited scene (many layers, very tall) efficiently  
**So that** it scrolls smoothly, supports zoom/pan (when enabled), and doesn’t OOM.

### Secondary

**As a** product owner  
**I want** the same content package (tiles + metadata) to work on Android and iOS  
**So that** we can ship consistent episodes and reduce pipeline complexity.

**As a** user  
**I want** taps/long-presses on layers to trigger actions (e.g. popup)  
**So that** interactive comics remain interactive.

## Acceptance Criteria

### Must Have

1. **Tiled image rendering**  
   **Given** an image whose file template contains `{0}{1}{2}` (см. формат `.comics`)  
   **When** the user scrolls/zooms  
   **Then** the engine requests and renders 512×512 tiles for the visible region (plus a preload margin), using the `.comics` tile invariants.

2. **Layer transforms and alpha driven by scroll offset**  
   **Given** a list of layers with animation tracks (translate/rotate/scale/alpha)  
   **When** scroll offset changes  
   **Then** each layer’s transform matrix and alpha are recomputed and applied before rendering.

3. **Viewport-based tile lifecycle**  
   **Given** large scenes  
   **When** a layer is far outside the viewport (with margin)  
   **Then** its decoded tile bitmaps are released / not held, while keeping the layer surface to avoid “black squares” (legacy iOS note).

4. **Deterministic caching key**  
   **Given** a descriptor/name + tile filename  
   **When** tiles are cached in memory  
   **Then** the key is stable across runs (Android: `descriptorName + "_" + fileName`).

5. **Hit-testing hooks**  
   **Given** a tap location  
   **When** hit-test is requested  
   **Then** the engine can determine whether a non-transparent pixel was hit within the relevant tile (Android legacy uses alpha sampling).

### Should Have

- **Placeholder tile rendering** when some tiles are missing (Android draws placeholder if any visible tile is missing).
- **Zoom enable/disable** per scene (Android supports fixed zoom and a zoom-enabled mode).

### Won't Have (This Iteration)

- Full CreateJS timeline reproduction in native (web export is treated as reference for asset packaging; native v1 focuses on “comics render engine”).
- GPU render backend (Metal/OpenGL). Legacy implementations are CPU/UIImage/Canvas based.

## Constraints

- **Platform**: Android + iOS native, exposed to Flutter via plugin channels.
- **Performance**: must support very large content (height >> screen) without decoding full bitmaps.
- **Memory**: must avoid holding decoded tiles for offscreen regions.
- **Compatibility**: must align with the canonical `.comics` format invariants to reuse existing archives. See: `../sdd-comics-format/02-specifications-ru.md`.

## Open Questions

- [ ] Canonical zoom levels: Android uses discrete levels \([1, 0.5, 0.25, 0.125]\); iOS derives scale from `CGContext` and uses CATiledLayer. Should Flutter API expose *discrete* zoom levels or *continuous*?
- [ ] Content source abstraction: legacy iOS loads tiles via `ArchiveManager.layer(name:)`; Android decodes from `descriptor.getImage(fileName)`. Should plugin standardize on “archive URL + manifest” or “stream provider callback”?
- [ ] Layer ordering guarantees: iOS notes it “should keep order of subviews same as comics.layers”. Define as strict requirement?

## References (legacy sources)

- Android tiling view: `legacy/legacy-mahabharata-render-engine-android-java/app/src/main/java/com/fulldome/mahabharata/controls/TileImageView.java`
- Android zoom container: `legacy/legacy-mahabharata-render-engine-android-java/app/src/main/java/com/fulldome/mahabharata/controls/ZoomFrameLayout.java`
- Android layer model: `legacy/legacy-mahabharata-render-engine-android-java/app/src/main/java/com/fulldome/mahabharata/model/visual/Layer.java`
- iOS tiling view: `legacy/legacy-mahabharata-render-engine-ios-swift/Mahabharata/Views/Tiles/TileImageView.swift`
- iOS scroll container: `legacy/legacy-mahabharata-render-engine-ios-swift/Mahabharata/Views/Tiles/ImageScrollView.swift`
- iOS layer model: `legacy/legacy-mahabharata-render-engine-ios-swift/Mahabharata/Model/DataClasses/Visual/Layer.swift`
- Web reference export: `legacy/legacy-bhagavadgita-render-engine-web-css/Anim1_HTML5 Canvas.html` and `Anim1_HTML5 Canvas.js`

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [conditions/clarifications]
