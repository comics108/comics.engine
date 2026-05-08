# Plan: Comics Engine Shared Core

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-05-08

## Phase 1: Interface Extraction

### Task 1.1: Create IComicsSource interface
- [x] Create `Runtime/Core/IComicsSource.cs`
- [x] Define methods: `LoadData()`, `LoadTile()`, `LoadSound()`
- [x] Define properties: `IsReadOnly`
- [x] Define lifecycle: `Invalidate()`, `Dispose()`

### Task 1.2: Extract common types
- [x] Ensure `Comics`, `Layer`, `Anim` models are source-agnostic
- [x] Move `ComicsParser` to `Core/` namespace

## Phase 2: ZipArchiveSource Implementation

### Task 2.1: Refactor ZipArchiveProvider
- [x] Rename `ZipArchiveProvider` → `ZipArchiveSource`
- [x] Implement `IComicsSource` interface
- [x] Mark `IsReadOnly = true`
- [x] Keep existing extraction logic

### Task 2.2: Update ComicsViewer
- [x] Add `Initialize(IComicsSource source)` method
- [x] Refactor `LoadArchive()` to use new `Initialize()`
- [x] Update `TileRenderer` to accept `IComicsSource`

### Task 2.3: Validate runtime path
- [ ] Test existing .comics files still load
- [ ] Verify tile loading unchanged
- [ ] Verify animation processing unchanged

## Phase 3: FolderSource Implementation

### Task 3.1: Create FolderSource
- [x] Create `Runtime/IO/FolderSource.cs`
- [x] Implement `LoadData()` from folder path
- [x] Implement `LoadTile()` with Editor fallback
- [x] Implement `Invalidate()` for cache clearing

### Task 3.2: Add LoadFolder to ComicsViewer
- [x] Add `LoadFolder(string path)` method
- [x] Create FolderSource and call Initialize()
- [x] Add `RefreshFromSource()` for editor updates

### Task 3.3: Validate editor path
- [ ] Create test folder with data.json + tiles
- [ ] Verify loading matches archive loading
- [ ] Verify invalidation triggers reload

## Phase 4: TileRenderer Updates

### Task 4.1: Source-agnostic tile loading
- [x] Update `TileRenderer` constructor to take `IComicsSource`
- [x] Replace direct file access with `_source.LoadTile()`
- [x] Add `InvalidateCache()` method

### Task 4.2: Cache management
- [x] Update `TileCache` to support invalidation
- [ ] Test memory cleanup on source change

## Phase 5: Assembly Organization

### Task 5.1: Assembly definitions
- [x] Verify `Comics.Engine.asmdef` structure
- [x] Ensure Editor code can reference Runtime
- [x] No Runtime dependencies on Editor APIs

### Task 5.2: Namespace cleanup
- [x] `Comics.Engine.Core` - interfaces, shared types
- [x] `Comics.Engine.IO` - source implementations
- [x] `Comics.Engine.Rendering` - TileRenderer, TileCache

## Verification Checklist

- [ ] Runtime: `.comics` archive loads and plays correctly
- [ ] Runtime: All animations render with correct transforms
- [ ] Editor: Folder source loads same data as archive source
- [ ] Editor: Invalidation triggers proper refresh
- [x] Both: TILE_SIZE=512 invariant maintained
- [x] Both: Transform order Scale→Rotate→Translate maintained
- [x] Both: Easing `(f-1)³+1` unchanged

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Breaking runtime | Test existing .comics files before merge |
| Memory leaks | Ensure Dispose() cleans up textures |
| Editor-only APIs in Runtime | Use #if UNITY_EDITOR guards |

## Estimated Phases

1. Interface Extraction - Foundation
2. ZipArchiveSource - Backward compatibility
3. FolderSource - New capability
4. TileRenderer - Integration
5. Assembly - Cleanup

---

## Approval

- [x] Plan reviewed by: Anton
- [x] Plan approved on: 2026-05-08
