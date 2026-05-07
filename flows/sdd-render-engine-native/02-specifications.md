# Specifications: Native render engine plugin (tiling + layers)

> Version: 1.0  
> Status: DRAFT  
> Last Updated: 2026-05-07  
> Requirements: `01-requirements.md`

## Overview

Implement a Flutter plugin that hosts a **native render surface** on each platform. The native side renders a “comics scene” composed of multiple **layers**, where each layer is a potentially huge image provided as **512×512 tiles** and transformed/alpha-blended according to **scroll offset-driven animations**.

This spec describes behavior based on legacy implementations and defines **portable invariants** needed for reusing existing assets.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| Flutter app (`flutter_comics`) | Modify | Uses plugin widget + API to show scenes |
| Flutter plugin (new) | Create | Platform channel + platform view / texture |
| Android native | Create | Tiled View + zoom container + caching + hit-test |
| iOS native | Create | CATiledLayer-based tile view + UIScrollView orchestration |
| Content packaging | Modify/Define | Tile naming + archive layout expectations |

## Architecture

### Component Diagram

```
Flutter Widget
  ├─ provides: scene metadata (size, layers, animations, tile templates, popups)
  ├─ receives: events (tap/long-press hit, loading/errors)
  ▼
Platform Plugin
  ├─ Android: Zoom/Pan container + Layer host + TileImageView(s)
  └─ iOS: UIScrollView + tilesContainer + TileImageView(s) backed by CATiledLayer
  ▼
Tile Source (abstract)
  ├─ Android legacy: InputStream via descriptor.getImage(fileName)
  └─ iOS legacy: ArchiveManager.layer(name:) -> UIImage
```

### Data Flow (legacy-aligned)

```
scroll offset changes
  -> process animations
  -> for each layer:
       compute matrix + alpha
       apply transform to layer view
       if layer intersects "viewport + margin":
          ensure tiles decoded/cached for needed tiles
       else:
          drop decoded tiles (keep view to avoid black squares)
  -> invalidation triggers redraw
```

## Core Data Model (portable)

### Scene

- **sceneWidth**, **sceneHeight**: logical pixels of the content.
- **layers[]**: ordered back-to-front.
- **sounds[]** (optional): scroll-offset driven audio triggers (present in iOS legacy; Android in puzzle context uses separate flows).

### Layer

Each layer has:

- **images[]**: per-language `Image` entries; choose current language, fallback to first non-empty.
- **popup** (optional): a file name to show on long-press (Android/iOS legacy).
- **animations[]**: time/offset segments for:
  - translate (x,y)
  - rotate (angle, pivotX, pivotY)
  - scale (sx, sy, pivotX, pivotY)
  - alpha (0..1)

### Tile naming invariant

If an image is tiled, its filename is a template containing `{0}`, `{1}`, `{2}`:

- `{0}` = `Int(zoom * 1000)`
- `{1}` = `column` index
- `{2}` = `row` index

**Tile size** is fixed at **512×512** (both Android and iOS legacy).

## Rendering: Tiling

### Android legacy behavior (summary)

Source: `TileImageView.java`

- Determines **tile mode** by `filePath.contains("{0}")`.
- Uses `TILE_SIZE = 512`.
- Uses discrete zoom levels `ZOOM_LEVELS = [1.0, 0.5, 0.25, 0.125]` when zoom is enabled.
- Builds tile rects in *unscaled content coords*:
  - realWidth = contentWidth * zoom
  - iterate `i += TILE_SIZE`, `j += TILE_SIZE`
  - each tile rect maps back to content coords by dividing by zoom.
- Draw:
  - compute visible rect
  - optionally draw placeholder bitmap if any visible tile is missing
  - draw each visible tile bitmap with `canvas.drawBitmap(bitmap, null, tileRect, paint)`
- Loading:
  - preload bitmap rect comes from parent-visible-rect with a configurable offset
  - loads tiles intersecting preload rect, cancels others
- Hit-testing:
  - finds tile rect containing point
  - samples alpha at corresponding bitmap pixel (`Color.alpha(bitmap.getPixel(...)) > 0`)

### iOS legacy behavior (summary)

Sources: `TileImageView.swift`, `ImageScrollView.swift`

- `TileImageView` is backed by a `CATiledLayer` subclass with `fadeDuration=0`.
- Forces `contentScaleFactor = 1` to avoid loading wrong tile sizes on retina.
- In `draw(_:)`:
  - derive current **scale** from `UIGraphicsGetCurrentContext().ctm.a`
  - compute “effective tile size in content coords” by dividing 512 by scale
  - compute rows/cols intersecting draw rect, draw `UIImage` tiles into tile rect
- Tile loading:
  - `prepareTiles()` (currently) loads **all tiles** once via `ArchiveManager.layer(name:)` and then `setNeedsDisplay()`
  - `killTiles()` clears tile dictionary (but view remains)
- Orchestration:
  - `ImageScrollView` fixes zoom scale for comics mode to `screenWidth / comics.width`
  - Computes intersect rect as **3× viewport** in unscaled coords
  - For each layer:
    - `tile.transform = layer.matrix`
    - `tile.alpha = layer.alpha`
    - if intersects: `prepareTiles()` else `killTiles()`
  - Note: comments warn removing tile views causes “black squares”, hence keep views but drop images.

### Spec’d behavior (portable, for plugin)

1. **Tile size**: fixed to 512×512.
2. **Tile naming**: `{0}=zoom*1000`, `{1}=col`, `{2}=row`.
3. **Viewport margin**:
   - default margin = 1× viewport on each side (iOS uses 3× total width/height region).
   - implementation may differ per platform but must satisfy “near-viewport tiles kept, far tiles dropped”.
4. **Keep layer surfaces** while unloading tile bitmaps to avoid visual artifacts (match iOS constraint).

## Rendering: Layer transforms & animation

Android and iOS share the same conceptual model:

- Animations are sorted by offset range so that for a given scroll offset the engine finds the active segment and interpolates from previous to current.
- Per scroll offset:
  - reset matrix to identity
  - apply scale, rotate, translate in a defined order
  - compute alpha
  - compute inverse matrix (for hit-test mapping) as needed

The plugin should preserve this contract and allow the content pipeline to define animations identically for both platforms.

## Caching & memory

### Android legacy

- In-memory LRU bitmap cache is used via `CacheManager.getBitmapCache()`.
- Cache key is `descriptorName + "_" + fileName`.
- Requests are deduped by key.

### iOS legacy

- In `TileImageView` tiles are held in a dictionary `[String: UIImage]`.
- `killTiles()` releases those references.

### Spec’d caching behavior

- Provide an in-memory cache on each platform keyed by `(contentId, fileName)` (same idea as Android key).
- Tile loading must be cancellable (Android legacy supports cancel per tile).
- The plugin must allow controlling cache size / memory pressure response.

## Interfaces (Flutter ↔ native)

This spec defines minimal required concepts; concrete channel names can be chosen during implementation.

### Input to native

- scene descriptor:
  - scene size
  - layers ordered
  - per layer: image template + size + animations + popup id
  - current language
  - content location (archive path / resolver)
- runtime controls:
  - set scroll offset
  - set zoom enabled / scale
  - request hit-test at point

### Output to Flutter

- events:
  - layer hit (id + popup reference)
  - tile load errors (optional)

## Testing Strategy (for plugin build)

- **Golden behavior**: verify tile filename generation for representative zoom/row/col.
- **Viewport logic**: verify that intersect region triggers load/unload transitions.
- **Animation math**: verify matrix+alpha for known animation segments at boundary offsets.
- **Hit-test**: verify alpha sampling mapping.

## Open Design Questions

- Should iOS continue to use CATiledLayer, or switch to Android-like explicit visible-rect tile set computation for consistent control (at cost of more code)?
- Should the plugin expose a “tile source” callback API to Flutter (Dart -> native) or keep tile IO fully native (archive extracted by native)?

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [conditions/clarifications]
