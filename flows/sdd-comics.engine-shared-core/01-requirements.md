# Requirements: Comics Engine Shared Core

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-05-08

## Problem Statement

The comics.engine (`unity_comics.engine`) is currently tightly coupled to `ZipArchiveProvider` for loading `.comics` archives at runtime. The comics.editor needs to preview documents during editing, but the editor works with **unpacked folders** (temp workspace), not archives.

Current architecture:
```
ComicsViewer → ZipArchiveProvider → .comics archive
```

Required architecture:
```
ComicsViewer → IComicsSource ← ZipArchiveSource (runtime)
                            ← FolderSource (editor)
```

## User Stories

**As a** editor developer
**I want** to use the same animation/rendering engine for preview
**So that** WYSIWYG matches runtime playback exactly

**As a** engine maintainer
**I want** a single AnimationProcessor/TileRenderer implementation
**So that** bug fixes apply to both runtime and editor

**As a** QA engineer
**I want** "Preview as Player" mode in editor
**So that** I can validate documents before publishing

## Acceptance Criteria

### Must Have

1. **Given** an abstraction `IComicsSource`
   **When** runtime loads archive
   **Then** `ZipArchiveSource` provides data.json and tile textures from ZIP

2. **Given** `FolderSource` implementation
   **When** editor preview renders
   **Then** data.json and tiles load from unpacked temp folder

3. **Given** both sources implement same interface
   **When** AnimationProcessor.Process(scroll) is called
   **Then** identical transform matrices are computed

4. **Given** TileRenderer with either source
   **When** viewport changes
   **Then** tiles load/unload with same naming convention `{zoom*1000}_{col}_{row}`

### Should Have

- Shared `ComicsCore` assembly usable in both Editor and Runtime contexts
- No runtime dependencies on Editor-only APIs

### Won't Have (This Iteration)

- Sound playback in editor preview (separate SDD)
- Selection/hit-testing (handled by editor-specific code)

## Constraints

- Maintain 100% backward compatibility with existing .comics files
- No changes to invariants: TILE_SIZE=512, transform order Scale→Rotate→Translate, easing `(f-1)³+1`
- Editor preview must work in Unity Editor context (EditorWindow)
- Runtime viewer must work in standalone builds

## Dependencies

- ADR-006: Transform Composition Order (defines invariants)
- sdd-comics.engine-csharp-unity: Existing runtime implementation
- sdd-comics.editor-canvas-preview-transforms: Will consume shared core

## Open Questions

- [ ] Should shared core be separate assembly (asmdef) or namespace within engine?
- [ ] Memory management: Who owns Texture2D instances (source or renderer)?

## References

- `app/unity_comics.engine/Runtime/ComicsViewer.cs` - current implementation
- `app/unity_comics.engine/Runtime/IO/ZipArchiveProvider.cs` - current archive loading
- `flows/sdd-comics.engine-csharp-unity/specifications-ru.md` - engine specs

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
