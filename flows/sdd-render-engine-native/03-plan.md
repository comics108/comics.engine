# Implementation Plan: Native render engine plugin (tiling + layers)

> Version: 1.0  
> Status: DRAFT  
> Last Updated: 2026-05-07  
> Specifications: `02-specifications.md`

## Summary

Build a Flutter plugin that embeds a native “comics renderer” view per platform, implementing: tiled image rendering, layer transforms driven by scroll offset, viewport-based tile lifecycle, and hit-testing hooks.

## Task Breakdown

### Phase 1: Define plugin API & content contract

#### Task 1.1: Define portable scene schema
- **Description**: Lock the data contract for scenes/layers/animations/tile templates.
- **Files**:
  - `flows/sdd-render-engine-native/02-specifications.md` - finalize interface section
  - (future) `flutter_comics_render_engine/` plugin schema files
- **Dependencies**: None
- **Verification**: Schema covers all fields needed by Android+iOS legacy behaviors.
- **Complexity**: Medium

#### Task 1.2: Decide tile source mechanism
- **Description**: Pick either “native archive reader” or “callback fetcher”.
- **Dependencies**: Task 1.1
- **Verification**: Both platforms can load tiles deterministically + cancel.
- **Complexity**: Medium

### Phase 2: Android native renderer

#### Task 2.1: Implement TileImageView-equivalent
- **Description**: Render tiles on Canvas, placeholder behavior, preload rect, cancel.
- **Dependencies**: Phase 1
- **Verification**: Smooth scroll, correct tiles drawn, no full bitmap decode.
- **Complexity**: High

#### Task 2.2: Implement Zoom/Pan container
- **Description**: Port `ZoomFrameLayout` concepts: matrix transform, pinch zoom (optional), clamp translate.
- **Dependencies**: Task 2.1
- **Verification**: Content stays within bounds; hit-testing coordinate mapping works.
- **Complexity**: High

### Phase 3: iOS native renderer

#### Task 3.1: Implement CATiledLayer-backed TileImageView
- **Description**: Port legacy `TileImageView` + optimize tile loading to avoid “load all tiles”.
- **Dependencies**: Phase 1
- **Verification**: Correct tiles appear as you scroll; memory stable.
- **Complexity**: High

#### Task 3.2: Implement ImageScrollView orchestration
- **Description**: Maintain tilesContainer, apply per-layer matrix/alpha, intersect rect logic.
- **Dependencies**: Task 3.1
- **Verification**: No black squares; tiles unload when far away.
- **Complexity**: Medium

### Phase 4: Flutter integration

#### Task 4.1: Platform view/texture integration
- **Description**: Expose native renderer in Flutter; wire method channels/events.
- **Dependencies**: Phases 2–3
- **Verification**: Flutter screen can drive scroll offset & receive hits.
- **Complexity**: High

#### Task 4.2: End-to-end sample scene
- **Description**: Load a small set of tiles + a minimal layer list.
- **Dependencies**: Task 4.1
- **Verification**: Renders on both Android and iOS.
- **Complexity**: Medium

## Dependency Graph

```
Task 1.1 ─→ Task 1.2 ─┬─→ Task 2.1 ─→ Task 2.2 ─┐
                       └─→ Task 3.1 ─→ Task 3.2 ─┼─→ Task 4.1 ─→ Task 4.2
```

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| iOS tile loading is “load all tiles” and blows memory | Med | High | Implement visible-tiles-only loader; keep CATiledLayer draw logic |
| Removing layer views causes black squares (legacy note) | High | Med | Keep views; unload tile images only |
| Zoom behavior differs between platforms | Med | Med | Define canonical zoom contract; snap-to-levels if needed |

## Rollback Strategy

- Keep plugin behind a feature flag in Flutter.
- If native renderer fails, fall back to a simpler non-zoom image display for the episode.

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [conditions/clarifications]
