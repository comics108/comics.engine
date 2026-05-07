# Implementation Plan: Comic Viewer Cross-Platform Component

> Version: 1.0
> Status: APPROVED
> Last Updated: 2025-12-31
> Specifications: [02-specifications.md](02-specifications.md)

## Summary

Implementing Flutter-based comic viewer component in 4 major phases:

1. **Foundation** (Data Models & Core Infrastructure) - 8 tasks
2. **Rendering System** (Widgets & Painters) - 10 tasks
3. **Storage & Audio** (Archive Management & Sound Sync) - 6 tasks
4. **Polish & Integration** (Testing, Optimization, V2 Features) - 8 tasks

**Total**: 32 atomic tasks across 4 phases

**Approach**:
- Build V1 support first (legacy compatibility)
- Add V2 features incrementally on top of V1 foundation
- Test each task individually before moving forward (CLAUDE.md protocol)
- Create standalone Flutter package: `comic_viewer`

**Key Dependencies**:
- Flutter 3.24+
- Packages: archive, audioplayers, path_provider, sqflite, dio

---

## Task Breakdown

### Phase 1: Foundation (Data Models & Core Infrastructure)

#### Task 1.1: Create Flutter Package Structure

- **Description**: Initialize `comic_viewer` Flutter package with proper directory structure and pubspec.yaml
- **Files**:
  - `comic_viewer/pubspec.yaml` - Create
  - `comic_viewer/lib/comic_viewer.dart` - Create (main export file)
  - `comic_viewer/lib/src/models/` - Create (directory for data models)
  - `comic_viewer/lib/src/widgets/` - Create (directory for widgets)
  - `comic_viewer/lib/src/utils/` - Create (directory for utilities)
  - `comic_viewer/lib/src/controllers/` - Create (directory for controllers)
  - `comic_viewer/test/` - Create (directory for tests)
  - `comic_viewer/example/` - Create (example app)
- **Dependencies**: None
- **Verification**:
  - Run `flutter create --template=package comic_viewer`
  - Run `flutter pub get` successfully
  - Import package in example app
- **Complexity**: Low

#### Task 1.2: Implement Animation Base Classes

- **Description**: Create base `Animation` class and concrete animation types (TranslateAnimation, RotateAnimation, ScaleAnimation, AlphaAnimation, SoundAnimation)
- **Files**:
  - `lib/src/models/animation.dart` - Create
  - `lib/src/models/animations/translate_animation.dart` - Create
  - `lib/src/models/animations/rotate_animation.dart` - Create
  - `lib/src/models/animations/scale_animation.dart` - Create
  - `lib/src/models/animations/alpha_animation.dart` - Create
  - `lib/src/models/animations/sound_animation.dart` - Create
  - `test/models/animation_test.dart` - Create
- **Dependencies**: Task 1.1
- **Verification**:
  - Create test animations from JSON
  - Verify `getFraction()` cubic easing calculation
  - Test `isActive()` for scroll offset ranges
  - Run unit tests: `flutter test test/models/animation_test.dart`
- **Complexity**: Medium

#### Task 1.3: Implement LayerImage Model

- **Description**: Create LayerImage class to represent language-specific images
- **Files**:
  - `lib/src/models/layer_image.dart` - Create
  - `test/models/layer_image_test.dart` - Create
- **Dependencies**: Task 1.1
- **Verification**:
  - Parse LayerImage from JSON (v1 format)
  - Verify language, file, width, height fields
  - Test optional popup field
  - Run unit tests
- **Complexity**: Low

#### Task 1.4: Implement SpeechBubble Model (V2)

- **Description**: Create SpeechBubble class for V2 format with multi-language text
- **Files**:
  - `lib/src/models/speech_bubble.dart` - Create
  - `test/models/speech_bubble_test.dart` - Create
- **Dependencies**: Task 1.1
- **Verification**:
  - Parse SpeechBubble from JSON (v2 format)
  - Verify text map (multi-language), textStyle, backgroundImage
  - Test `getText(language)` with fallbacks (ru → first available)
  - Parse color from hex strings (#RGB, #RRGGBB, #AARRGGBB)
  - Run unit tests
- **Complexity**: Medium

#### Task 1.5: Implement Layer Model (V1 & V2)

- **Description**: Create Layer class supporting both v1 (image only) and v2 (image + speechBubble types) with animations
- **Files**:
  - `lib/src/models/layer.dart` - Create
  - `test/models/layer_test.dart` - Create
- **Dependencies**: Task 1.2, Task 1.3, Task 1.4
- **Verification**:
  - Parse v1 layer (type defaults to "image", zDepth = 0)
  - Parse v2 layer with type="image" or "speechBubble"
  - Verify zDepth field (v2 only)
  - Test `getImage(language)` language selection
  - Test `buildMatrixAndAlpha(scrollOffset)` matrix calculation
  - Verify animations are interpolated correctly
  - Verify matrix order: translate → rotate → scale
  - Test inverse matrix calculation
  - Run unit tests
- **Complexity**: High

#### Task 1.6: Implement Sound Model

- **Description**: Create Sound class with sound animations (point/range triggers)
- **Files**:
  - `lib/src/models/sound.dart` - Create
  - `test/models/sound_test.dart` - Create
- **Dependencies**: Task 1.2 (for SoundAnimation)
- **Verification**:
  - Parse Sound from JSON
  - Verify file path and animations array
  - Test SoundAnimation.isPointSound and isRangeSound
  - Run unit tests
- **Complexity**: Low

#### Task 1.7: Implement Comics Root Model

- **Description**: Create Comics class as root model, with version detection (v1/v2) and scroll processing
- **Files**:
  - `lib/src/models/comics.dart` - Create
  - `test/models/comics_test.dart` - Create
- **Dependencies**: Task 1.5, Task 1.6
- **Verification**:
  - Parse Comics from JSON (v1 and v2)
  - Version defaults to 1 if not present
  - Test `process(scrollOffset)` calls all layer.buildMatrixAndAlpha()
  - Verify width, height, layers, sounds parsing
  - Load real v1 data.json from legacy Android/iOS
  - Run unit tests with both v1 and v2 fixtures
- **Complexity**: Medium

#### Task 1.8: Create Test Fixtures

- **Description**: Create sample data.json files (v1 and v2) with images for testing
- **Files**:
  - `test/fixtures/v1_sample.json` - Create
  - `test/fixtures/v2_sample.json` - Create
  - `test/fixtures/v1_sample.zip` - Create (with dummy PNGs)
  - `test/fixtures/v2_sample.zip` - Create (with dummy PNGs)
- **Dependencies**: Task 1.7
- **Verification**:
  - Comics.fromJson() parses both fixtures without errors
  - Verify all field types match specifications
  - ZIP files extractable with archive package
- **Complexity**: Low

---

### Phase 2: Rendering System (Widgets & Painters)

#### Task 2.1: Implement ImageCacheManager

- **Description**: Create singleton ImageCacheManager for async image loading with LRU caching
- **Files**:
  - `lib/src/utils/image_cache_manager.dart` - Create
  - `test/utils/image_cache_manager_test.dart` - Create
- **Dependencies**: Task 1.1
- **Verification**:
  - Load image from bytes (PNG decode)
  - Cache images with max size limit (50 images)
  - Test LRU eviction when cache full
  - Test `getOptimalTileSize()` based on devicePixelRatio (512/1024/2048)
  - Test multi-size tile loading with fallback
  - Mock async loading and verify futures
  - Run unit tests
- **Complexity**: High

#### Task 2.2: Implement ComicAnimationController

- **Description**: Create ChangeNotifier controller that processes scroll updates and triggers layer animations
- **Files**:
  - `lib/src/controllers/comic_animation_controller.dart` - Create
  - `test/controllers/comic_animation_controller_test.dart` - Create
- **Dependencies**: Task 1.7
- **Verification**:
  - Initialize with Comics instance
  - Call `update(scrollOffset)` and verify comics.process() called
  - Verify notifyListeners() fires on scroll change
  - Test that identical scroll offset doesn't trigger update
  - Run unit tests
- **Complexity**: Low

#### Task 2.3: Implement AudioSyncController

- **Description**: Create controller for sound playback synchronized with scroll position
- **Files**:
  - `lib/src/controllers/audio_sync_controller.dart` - Create
  - `test/controllers/audio_sync_controller_test.dart` - Create
- **Dependencies**: Task 1.6
- **Verification**:
  - Initialize with Sound list
  - Test point sound triggering (once when crossing threshold)
  - Test range sound looping (start/stop at range boundaries)
  - Test fade-out effect (600ms duration)
  - Mock AudioPlayer and verify play/stop/setVolume calls
  - Test enabled/disabled state
  - Run unit tests (use mockito for AudioPlayer)
- **Complexity**: High

#### Task 2.4: Implement Simple Perspective Mode (3D)

- **Description**: Create utility functions for simple scale-based perspective (mobile)
- **Files**:
  - `lib/src/utils/perspective_renderer.dart` - Create
  - `test/utils/perspective_renderer_test.dart` - Create
- **Dependencies**: Task 1.1
- **Verification**:
  - Test `applySimplePerspective(canvas, size, zDepth)`
  - Verify scale = 1 / (1 + zDepth/1000)
  - Test centering transform (translate to center, scale, translate back)
  - Mock Canvas and verify translate/scale calls
  - Run unit tests
- **Complexity**: Medium

#### Task 2.5: Implement Advanced Perspective Mode (3D)

- **Description**: Create utility for full perspective matrix with vanishing point (VR/dome)
- **Files**:
  - `lib/src/utils/perspective_renderer.dart` - Modify (add advanced mode)
  - `test/utils/perspective_renderer_test.dart` - Modify
- **Dependencies**: Task 2.4
- **Verification**:
  - Test `applyAdvancedPerspective(canvas, size, zDepth)`
  - Verify Matrix4 with perspective entry (3,2) = -0.001
  - Test z-translation
  - Mock Canvas.transform() and verify matrix values
  - Run unit tests
- **Complexity**: High

#### Task 2.6: Implement ComicLayersPainter (CustomPainter)

- **Description**: Create CustomPainter that renders all layers with transforms, z-depth, and alpha
- **Files**:
  - `lib/src/widgets/comic_layers_painter.dart` - Create
  - `test/widgets/comic_layers_painter_test.dart` - Create
- **Dependencies**: Task 2.1, Task 2.4, Task 2.5, Task 1.7
- **Verification**:
  - Test paint() method with mock canvas
  - Verify layers sorted by zDepth (v2)
  - Test matrix transform application for each layer
  - Test z-depth perspective mode selection (simple vs advanced)
  - Test alpha blending (Paint.color with alpha)
  - Test image loading from ImageCacheManager
  - Verify placeholder rendering when image not loaded
  - Test shouldRepaint() logic (language change, comics change)
  - Run widget tests
- **Complexity**: High

#### Task 2.7: Implement Speech Bubble Text Rendering

- **Description**: Add speech bubble text overlay rendering to ComicLayersPainter
- **Files**:
  - `lib/src/widgets/comic_layers_painter.dart` - Modify
  - `test/widgets/comic_layers_painter_test.dart` - Modify
- **Dependencies**: Task 2.6, Task 1.4
- **Verification**:
  - Test `_drawSpeechBubbleLayer()` method
  - Verify background image drawn first
  - Test TextPainter with multi-language text
  - Verify textStyle application (font, size, color, bold, align)
  - Test text layout with maxWidth (bubble.width)
  - Test text painting at bubble.position
  - Test alpha application to text color
  - Run widget tests
- **Complexity**: Medium

#### Task 2.8: Implement ComicViewerWidget (Main Widget)

- **Description**: Create main StatefulWidget that combines ScrollView, painter, and controllers
- **Files**:
  - `lib/src/widgets/comic_viewer_widget.dart` - Create
  - `test/widgets/comic_viewer_widget_test.dart` - Create
- **Dependencies**: Task 2.2, Task 2.3, Task 2.6
- **Verification**:
  - Test widget initialization with Comics instance
  - Test ScrollController setup with initialScrollOffset
  - Test scroll listener triggers animation and audio updates
  - Test language switching (setState rebuilds with new language)
  - Test dispose() cleans up controllers
  - Verify AnimatedBuilder rebuilds on animation updates
  - Test soundEnabled parameter
  - Run widget tests
- **Complexity**: Medium

#### Task 2.9: Create Example App

- **Description**: Build example Flutter app demonstrating comic viewer with test episodes
- **Files**:
  - `example/lib/main.dart` - Create
  - `example/assets/test_episode_v1.zip` - Create
  - `example/assets/test_episode_v2.zip` - Create
- **Dependencies**: Task 2.8, Task 1.8
- **Verification**:
  - Load v1 episode and render in ComicViewerWidget
  - Load v2 episode with speechBubbles and zDepth
  - Test scroll animations work smoothly
  - Test language switching button
  - Test sound toggle
  - Manual testing on Android/iOS emulator
- **Complexity**: Low

#### Task 2.10: Performance Optimization (Rendering)

- **Description**: Optimize rendering pipeline for 60fps on mid-range devices
- **Files**:
  - `lib/src/widgets/comic_layers_painter.dart` - Modify
  - `lib/src/utils/image_cache_manager.dart` - Modify
- **Dependencies**: Task 2.9 (need working example to profile)
- **Verification**:
  - Profile with Flutter DevTools
  - Ensure paint() < 16ms per frame (60fps)
  - Test with 10+ layers and complex animations
  - Verify image loading doesn't block UI thread
  - Test on physical mid-range Android device (benchmark score ~5000)
  - Measure memory usage < 100MB for typical episode
- **Complexity**: Medium

---

### Phase 3: Storage & Audio (Archive Management & Sound Sync)

#### Task 3.1: Implement EpisodeArchiveLoader

- **Description**: Create loader for extracting and parsing ZIP archives with episode data
- **Files**:
  - `lib/src/utils/episode_archive_loader.dart` - Create
  - `test/utils/episode_archive_loader_test.dart` - Create
- **Dependencies**: Task 1.7
- **Verification**:
  - Test ZIP extraction with `archive` package
  - Test `loadEpisode(archivePath)` returns Comics instance
  - Test `extractFile(filename)` for data.json, layers, sounds
  - Verify archive caching (_currentArchive)
  - Test error handling for missing files, corrupted ZIP
  - Run unit tests with test fixtures
- **Complexity**: Medium

#### Task 3.2: Implement EpisodeStorageManager

- **Description**: Create storage manager for download/cache/delete episodes with sqflite metadata
- **Files**:
  - `lib/src/utils/episode_storage_manager.dart` - Create
  - `test/utils/episode_storage_manager_test.dart` - Create
- **Dependencies**: Task 1.1
- **Verification**:
  - Test database initialization (episodes table)
  - Test `downloadEpisode()` with progress callback (use dio)
  - Test `getEpisodePath()` retrieves cached episode
  - Test `deleteEpisode()` removes file and DB entry
  - Test `getCachedEpisodes()` returns all cached
  - Mock HTTP requests for testing
  - Run integration tests with temp directory
- **Complexity**: High

#### Task 3.3: Implement Audio Playback Integration

- **Description**: Integrate audioplayers package with AudioSyncController
- **Files**:
  - `lib/src/controllers/audio_sync_controller.dart` - Modify
  - `test/controllers/audio_sync_controller_test.dart` - Modify
- **Dependencies**: Task 2.3, Task 3.1
- **Verification**:
  - Test `_initializePlayers()` creates AudioPlayer instances
  - Test loading sound files from archive via EpisodeArchiveLoader
  - Test actual audio playback on device (manual)
  - Test looping for range sounds
  - Test fade-out volume animation
  - Test pause/resume/dispose lifecycle
  - Run integration tests with real audio files
- **Complexity**: Medium

#### Task 3.4: Implement Storage UI Components

- **Description**: Create UI widgets for episode download management
- **Files**:
  - `lib/src/widgets/episode_download_button.dart` - Create
  - `lib/src/widgets/episode_cache_manager_ui.dart` - Create
  - `example/lib/download_screen.dart` - Create
- **Dependencies**: Task 3.2
- **Verification**:
  - Test download button shows progress indicator
  - Test cache manager UI lists cached episodes
  - Test delete episode from UI
  - Test download cancellation
  - Manual UI testing in example app
- **Complexity**: Low

#### Task 3.5: End-to-End Integration Test

- **Description**: Create integration test for full flow: download → load → render → animate → audio
- **Files**:
  - `test/integration/comic_viewer_integration_test.dart` - Create
- **Dependencies**: Task 3.3, Task 2.8, Task 3.2
- **Verification**:
  - Download test episode
  - Load from cache
  - Render in ComicViewerWidget
  - Scroll through and verify animations play
  - Verify audio triggers
  - Test language switch
  - Test episode deletion
  - Run: `flutter test test/integration/`
- **Complexity**: High

#### Task 3.6: Error Handling & Edge Cases

- **Description**: Implement comprehensive error handling for all edge cases from specifications
- **Files**:
  - All existing files - Modify (add try/catch, error states)
  - `lib/src/utils/error_handler.dart` - Create (centralized errors)
  - `test/error_handling_test.dart` - Create
- **Dependencies**: Task 3.5 (need full system to test errors)
- **Verification**:
  - Test all 15+ edge cases from specifications (section "Edge Cases & Error Handling")
  - Missing data.json → show error
  - Corrupted JSON → show error with details
  - Unknown version → attempt v2 parse, warn
  - Missing layer image → show placeholder
  - Unsupported animation → skip, log
  - Large memory → evict cache
  - Download failure → retry 3x
  - Disk full → clear error
  - Language unavailable → fallback
  - Audio file missing → skip sound
  - Run error scenario tests
- **Complexity**: High

---

### Phase 4: Polish & Integration (Testing, Optimization, V2 Features)

#### Task 4.1: Comprehensive Unit Test Coverage

- **Description**: Achieve >80% code coverage with unit tests
- **Files**:
  - All test files - Expand
- **Dependencies**: All previous tasks
- **Verification**:
  - Run `flutter test --coverage`
  - Generate coverage report: `genhtml coverage/lcov.info -o coverage/html`
  - Review coverage report, add tests for uncovered code
  - Target: >80% coverage for lib/ directory
- **Complexity**: Medium

#### Task 4.2: Create Content Pipeline Tool (Tile Generator)

- **Description**: Build CLI tool to pre-generate tiles at multiple sizes from source images
- **Files**:
  - `tools/tile_generator.dart` - Create
  - `tools/README.md` - Create
- **Dependencies**: Task 1.1
- **Verification**:
  - Input: Large PNG (e.g., 2048x8000)
  - Output: Tiles at 512/1024/2048 sizes
  - Naming: `tile_{scale}_{size}_{col}_{row}.png`
  - Test with sample image
  - Verify tiles loadable in example app
- **Complexity**: Medium

#### Task 4.3: Performance Benchmarking

- **Description**: Create automated benchmarks for key operations
- **Files**:
  - `test/benchmarks/rendering_benchmark.dart` - Create
  - `test/benchmarks/parsing_benchmark.dart` - Create
  - `test/benchmarks/image_loading_benchmark.dart` - Create
- **Dependencies**: Task 2.10
- **Verification**:
  - Benchmark data.json parsing time (target: <50ms)
  - Benchmark layer transform calculation (target: <1ms per layer)
  - Benchmark image decode (varies by size)
  - Benchmark paint() duration (target: <16ms for 60fps)
  - Run on reference device, compare to targets
- **Complexity**: Low

#### Task 4.4: Accessibility Support

- **Description**: Add accessibility features (screen reader, semantic labels)
- **Files**:
  - `lib/src/widgets/comic_viewer_widget.dart` - Modify
  - `test/widgets/accessibility_test.dart` - Create
- **Dependencies**: Task 2.8
- **Verification**:
  - Add Semantics widgets with labels
  - Test with TalkBack (Android) and VoiceOver (iOS)
  - Announce page changes during scroll
  - Test with Flutter accessibility testing tools
- **Complexity**: Low

#### Task 4.5: Documentation

- **Description**: Write comprehensive API documentation and usage guide
- **Files**:
  - `README.md` - Create
  - `doc/api.md` - Create
  - `doc/usage_guide.md` - Create
  - `doc/v2_format_spec.md` - Create
  - `CHANGELOG.md` - Create
- **Dependencies**: All previous tasks
- **Verification**:
  - README with quick start example
  - API documentation for all public classes
  - Usage guide with code samples
  - V2 format specification for content creators
  - Run dartdoc, verify generated docs
- **Complexity**: Low

#### Task 4.6: Package Publishing Preparation

- **Description**: Prepare package for pub.dev publishing
- **Files**:
  - `pubspec.yaml` - Modify (add metadata, version, description)
  - `LICENSE` - Create (choose license)
  - `CONTRIBUTING.md` - Create
  - `.github/workflows/ci.yml` - Create (GitHub Actions)
- **Dependencies**: Task 4.1, Task 4.5
- **Verification**:
  - Run `flutter pub publish --dry-run`
  - Fix any pub.dev warnings
  - Verify package score (https://pub.dev/help/scoring)
  - Test CI pipeline runs successfully
- **Complexity**: Low

#### Task 4.7: After Effects Export Tool (V2)

- **Description**: Create ExtendScript tool for exporting AE compositions to v2 format
- **Files**:
  - `tools/ae-to-mahabharata-v2/main.jsx` - Create (ExtendScript)
  - `tools/ae-to-mahabharata-v2/exporter.jsx` - Create
  - `tools/ae-to-mahabharata-v2/README.md` - Create
- **Dependencies**: Task 1.4 (SpeechBubble model), Task 1.7 (v2 Comics format)
- **Verification**:
  - Test with sample AE composition (3+ layers, 2+ animations)
  - Export generates valid data.json (v2 format)
  - Verify position → TranslateAnimation
  - Verify rotation → RotateAnimation
  - Verify scale → ScaleAnimation
  - Verify opacity → AlphaAnimation
  - Verify 3D layer z-position → zDepth
  - Verify text layer → SpeechBubble
  - Test expression baking (simple expressions only)
  - Load exported episode in ComicViewer, verify rendering
- **Complexity**: High

#### Task 4.8: V2 Feature Demo

- **Description**: Create showcase episode using V2 features (zDepth, speechBubbles, AE export)
- **Files**:
  - `example/assets/showcase_v2_episode.zip` - Create
  - `example/lib/showcase_screen.dart` - Create
- **Dependencies**: Task 4.7
- **Verification**:
  - Create AE composition with:
    - 5+ layers with varying zDepth
    - Animated transforms (translate, rotate, scale)
    - 3+ speech bubbles (multi-language)
    - Scroll-driven animations
  - Export with AE tool
  - Load in example app
  - Verify 3D perspective rendering (simple & advanced modes)
  - Verify speech bubble text overlay
  - Verify smooth animations
  - Record demo video for documentation
- **Complexity**: Medium

---

## Dependency Graph

```
Phase 1: Foundation
===================
1.1 Package Structure
  ├─→ 1.2 Animation Classes
  ├─→ 1.3 LayerImage
  ├─→ 1.4 SpeechBubble (V2)
  └─→ 1.6 Sound Model

1.2, 1.3, 1.4 ─→ 1.5 Layer Model
1.5, 1.6 ─→ 1.7 Comics Model
1.7 ─→ 1.8 Test Fixtures

Phase 2: Rendering
===================
1.1 ─→ 2.1 ImageCacheManager
1.7 ─→ 2.2 ComicAnimationController
1.6 ─→ 2.3 AudioSyncController
1.1 ─→ 2.4 Simple Perspective
2.4 ─→ 2.5 Advanced Perspective
2.1, 2.4, 2.5, 1.7 ─→ 2.6 ComicLayersPainter
2.6, 1.4 ─→ 2.7 Speech Bubble Rendering
2.2, 2.3, 2.6 ─→ 2.8 ComicViewerWidget
2.8, 1.8 ─→ 2.9 Example App
2.9 ─→ 2.10 Performance Optimization

Phase 3: Storage & Audio
=========================
1.7 ─→ 3.1 EpisodeArchiveLoader
1.1 ─→ 3.2 EpisodeStorageManager
2.3, 3.1 ─→ 3.3 Audio Integration
3.2 ─→ 3.4 Storage UI
3.3, 2.8, 3.2 ─→ 3.5 E2E Integration Test
3.5 ─→ 3.6 Error Handling

Phase 4: Polish & V2
====================
All ─→ 4.1 Unit Test Coverage
1.1 ─→ 4.2 Tile Generator Tool
2.10 ─→ 4.3 Performance Benchmarks
2.8 ─→ 4.4 Accessibility
All ─→ 4.5 Documentation
4.1, 4.5 ─→ 4.6 Package Publishing
1.4, 1.7 ─→ 4.7 After Effects Tool
4.7 ─→ 4.8 V2 Feature Demo
```

---

## File Change Summary

### New Files Created (~50 files)

| File | Action | Purpose |
|------|--------|---------|
| `comic_viewer/pubspec.yaml` | Create | Package configuration with dependencies |
| `lib/comic_viewer.dart` | Create | Main export file |
| `lib/src/models/animation.dart` | Create | Base animation class |
| `lib/src/models/animations/*.dart` | Create | Concrete animation types (5 files) |
| `lib/src/models/layer_image.dart` | Create | Language-specific image model |
| `lib/src/models/speech_bubble.dart` | Create | V2 speech bubble model |
| `lib/src/models/layer.dart` | Create | Layer with transforms & animations |
| `lib/src/models/sound.dart` | Create | Audio track model |
| `lib/src/models/comics.dart` | Create | Root comics model |
| `lib/src/widgets/comic_viewer_widget.dart` | Create | Main viewer widget |
| `lib/src/widgets/comic_layers_painter.dart` | Create | CustomPainter for rendering |
| `lib/src/widgets/episode_download_button.dart` | Create | Download UI |
| `lib/src/widgets/episode_cache_manager_ui.dart` | Create | Cache management UI |
| `lib/src/controllers/comic_animation_controller.dart` | Create | Animation state controller |
| `lib/src/controllers/audio_sync_controller.dart` | Create | Audio sync controller |
| `lib/src/utils/image_cache_manager.dart` | Create | Image caching singleton |
| `lib/src/utils/episode_archive_loader.dart` | Create | ZIP extraction & parsing |
| `lib/src/utils/episode_storage_manager.dart` | Create | Download & cache manager |
| `lib/src/utils/perspective_renderer.dart` | Create | 3D perspective utilities |
| `lib/src/utils/error_handler.dart` | Create | Centralized error handling |
| `test/models/*.dart` | Create | Unit tests for models (~8 files) |
| `test/widgets/*.dart` | Create | Widget tests (~5 files) |
| `test/controllers/*.dart` | Create | Controller tests (~2 files) |
| `test/utils/*.dart` | Create | Utility tests (~5 files) |
| `test/integration/*.dart` | Create | Integration tests |
| `test/fixtures/*.json` | Create | Test data (v1/v2) |
| `test/fixtures/*.zip` | Create | Test episode archives |
| `example/lib/main.dart` | Create | Example app |
| `example/assets/*.zip` | Create | Sample episodes |
| `tools/tile_generator.dart` | Create | CLI tool for tile generation |
| `tools/ae-to-mahabharata-v2/*.jsx` | Create | After Effects export tool (~3 files) |
| `README.md` | Create | Package documentation |
| `doc/*.md` | Create | API & usage docs (~3 files) |
| `CHANGELOG.md` | Create | Version history |
| `LICENSE` | Create | Open source license |

### No Files Modified or Deleted
(All new implementation in standalone package)

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Performance issues on low-end devices** | Medium | High | Profile early (Task 2.10), optimize rendering, reduce layer count for low-end devices |
| **Memory overflow with large images** | Medium | High | Strict LRU cache limits, tile-based loading, monitor memory in tests |
| **Audio sync drift during scroll** | Low | Medium | Test extensively with different scroll speeds, adjust trigger thresholds |
| **V1 legacy format parsing breaks** | Low | High | Extensive testing with real legacy episodes, regression tests |
| **After Effects export produces invalid JSON** | Medium | Medium | Validate output in tool, comprehensive schema validation, error handling |
| **Platform-specific rendering differences** | Medium | Medium | Test on both Android & iOS, use platform-agnostic Canvas APIs |
| **ZIP extraction performance** | Low | Low | Profile with large archives, consider streaming extraction if needed |
| **Multi-language text overflow** | Medium | Low | Auto-truncate or wrap text, test with long strings in all languages |
| **3D perspective calculations incorrect** | Low | Medium | Unit test matrix math, visual verification in example app |
| **Dependency version conflicts** | Low | Low | Pin dependency versions, test with `flutter pub upgrade` |

---

## Rollback Strategy

If implementation fails or needs to be reverted:

### During Development (Per Task)
1. Each task is atomic and testable
2. Use git branches per task: `task-1.1-package-structure`
3. Merge only after tests pass
4. Can revert individual task without affecting others

### After Package Release
1. Publish new patch version with fix
2. Mark broken version as "discontinued" on pub.dev
3. For major breaking changes:
   - Create migration guide
   - Deprecate old APIs gradually (2+ versions)
   - Provide codemod scripts if possible

### In Host App (Legacy Android/iOS)
1. Keep legacy Java/Swift implementations until Flutter package proven stable
2. Use feature flag to A/B test Flutter vs native
3. Quick rollback by disabling feature flag
4. Gradual rollout: 10% → 50% → 100% users

---

## Checkpoints

### After Phase 1 (Foundation)
- [ ] All models parse v1 and v2 JSON correctly
- [ ] Animation interpolation produces expected values
- [ ] Test fixtures load without errors
- [ ] Unit tests: 30+ passing
- [ ] No compilation warnings

### After Phase 2 (Rendering)
- [ ] Example app renders test episode smoothly
- [ ] Scroll animations play correctly
- [ ] Language switching works without reload
- [ ] Simple & advanced 3D modes render differently
- [ ] Speech bubbles display with correct text
- [ ] Frame rate: 60fps on mid-range device
- [ ] Unit + widget tests: 60+ passing

### After Phase 3 (Storage & Audio)
- [ ] Episode download works with progress
- [ ] Cache storage persists across app restarts
- [ ] Audio triggers on scroll (point & range)
- [ ] Audio fades in/out smoothly
- [ ] End-to-end test passes
- [ ] All edge cases handled gracefully
- [ ] Integration tests: 10+ passing

### After Phase 4 (Polish & V2)
- [ ] Code coverage >80%
- [ ] Tile generator produces valid tiles
- [ ] Performance benchmarks meet targets
- [ ] Accessibility works with screen readers
- [ ] Documentation complete and accurate
- [ ] After Effects tool exports valid v2 format
- [ ] V2 demo episode showcases all features
- [ ] Package ready for pub.dev: pub points >130/140

---

## Open Implementation Questions

- [ ] **Tile size auto-detection**: Should we benchmark device and cache the preferred size, or detect on every load?
  - **Decision during**: Task 2.1
  - **Options**: Static detection (once per app launch) vs dynamic (per image)

- [ ] **Audio mixing strategy**: If multiple range sounds overlap, play all or prioritize?
  - **Decision during**: Task 2.3
  - **Options**: Mix all (may be loud), priority system, volume ducking

- [ ] **Cache eviction policy**: LRU or LFU (Least Frequently Used)?
  - **Decision during**: Task 2.1
  - **Options**: LRU (simpler), LFU (better for frequently accessed episodes)

- [ ] **Error UI patterns**: Toast messages, SnackBars, or dedicated error widgets?
  - **Decision during**: Task 3.6
  - **Options**: Prefer non-intrusive (SnackBar), allow host app customization

- [ ] **V2 backward compatibility**: Should v2 viewer still render v1 perfectly, or optimize for v2?
  - **Decision during**: Task 1.7
  - **Current approach**: Treat v1 as subset of v2 (zDepth=0, type=image)

- [ ] **After Effects easing export**: Map AE easing to Flutter Curves or bake as keyframes?
  - **Decision during**: Task 4.7
  - **Options**: Map to Curves (cleaner), bake (more accurate)

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2025-12-31
- [x] Notes: Plan approved, ready for implementation. Starting with Phase 1: Foundation (8 tasks)
