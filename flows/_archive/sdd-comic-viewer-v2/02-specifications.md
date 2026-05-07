# Specifications: Comic Viewer Cross-Platform Component

> Version: 1.0
> Status: APPROVED
> Last Updated: 2025-12-31
> Requirements: [01-requirements.md](01-requirements.md)

## Overview

Создаем кроссплатформенный Flutter-компонент `ComicViewer` для отображения интерактивных комиксов с:
- **Dual format support**: v1 (legacy compatibility) и v2 (extended features)
- **Scroll-driven animations**: синхронизация анимаций слоев с позицией скролла
- **Multi-layer rendering**: композиция из нескольких слоев с трансформациями
- **3D depth positioning**: z-depth для VR/dome эффектов (v2)
- **Speech bubbles**: мультиязычные текстовые баллоны как слои (v2)
- **Sound synchronization**: point/range audio triggers
- **Efficient image loading**: память-оптимизированная загрузка больших изображений
- **Language switching**: смена языка без перезагрузки
- **Download & cache management**: гибридное хранилище эпизодов

Компонент заменяет дублирующие реализации Android (Java) и iOS (Swift) единым Flutter-решением.

## Affected Systems

| System | Impact | Notes |
|--------|--------|-------|
| Comic rendering engine | **Create** | Новый Flutter package/module `comic_viewer` |
| Episode data loader | **Create** | ZIP parser, data.json decoder (v1/v2) |
| Animation system | **Create** | Scroll-based interpolation engine |
| Audio manager | **Create** | Sync audio playback с scroll position |
| Image cache | **Create** | Memory-efficient image loading |
| Storage manager | **Create** | Download/cache эпизодов |
| Legacy Android app | **Integrate** | Replace native code with Flutter component |
| Legacy iOS app | **Integrate** | Replace native code with Flutter component |

## Architecture

### High-Level Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     ComicViewerWidget                        │
│  (StatefulWidget - главный виджет компонента)               │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         ComicScrollView (CustomScrollView)          │    │
│  │  ┌──────────────────────────────────────────────┐  │    │
│  │  │  ComicLayerStack (CustomPainter/Stack)       │  │    │
│  │  │                                               │  │    │
│  │  │  ┌─────────────────────────────────────┐    │  │    │
│  │  │  │  LayerRenderer (CustomPainter)      │    │  │    │
│  │  │  │  - Renders single layer with        │    │  │    │
│  │  │  │    matrix transforms                 │    │  │    │
│  │  │  │  - Handles image/speechBubble types │    │  │    │
│  │  │  │  - Applies z-depth perspective (v2) │    │  │    │
│  │  │  └─────────────────────────────────────┘    │  │    │
│  │  │  (Multiple LayerRenderer instances)         │  │    │
│  │  └──────────────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  Controllers:                                                │
│  - ComicAnimationController (scroll → layer states)         │
│  - AudioSyncController (scroll → sound playback)            │
│  - LanguageController (language switching)                  │
└─────────────────────────────────────────────────────────────┘
         ↓ uses                    ↓ uses
┌──────────────────┐      ┌─────────────────────┐
│  ComicDataModel  │      │  ImageCacheManager  │
│  - Comics        │      │  - Tile loading     │
│  - Layer (v1/v2) │      │  - Memory mgmt      │
│  - Animation     │      │  - Async decode     │
│  - Sound         │      └─────────────────────┘
└──────────────────┘
         ↓ loaded by
┌──────────────────────────────────┐
│    EpisodeArchiveLoader          │
│  - Unzip episode archive         │
│  - Parse data.json (v1/v2)       │
│  - Extract images/sounds         │
└──────────────────────────────────┘
         ↓ uses
┌──────────────────────────────────┐
│   EpisodeStorageManager          │
│  - Download episodes             │
│  - Cache management              │
│  - Progress tracking             │
└──────────────────────────────────┘
```

### Data Flow

```
1. App requests episode
   ↓
2. EpisodeStorageManager checks cache
   ├─ Found: load from local storage
   └─ Not found: download → cache → load
   ↓
3. EpisodeArchiveLoader unzips & parses data.json
   ├─ Detect version (v1 or v2)
   ├─ Parse Comics model
   ├─ Create Layer objects
   └─ Extract animation/sound metadata
   ↓
4. ComicViewerWidget initializes
   ├─ Setup ComicAnimationController
   ├─ Setup AudioSyncController
   └─ Build layer stack
   ↓
5. User scrolls
   ↓
6. ComicAnimationController.onScroll(offset)
   ├─ Update each Layer.buildMatrixAndAlpha(offset)
   ├─ Interpolate animations (translate, rotate, scale, alpha)
   └─ Notify LayerRenderer to repaint
   ↓
7. AudioSyncController.onScroll(offset)
   ├─ Check sound animations (point/range)
   ├─ Start/stop/fade audio
   └─ Update playback state
   ↓
8. LayerRenderer.paint()
   ├─ Apply layer matrix transform
   ├─ Apply z-depth perspective (v2)
   ├─ Draw image (with tiling if large)
   └─ Draw speech bubble text overlay (v2)
```

## Data Models

### Comics (root model)

```dart
class Comics {
  final int version;           // 1 or 2
  final int width;             // Canvas width
  final int height;            // Canvas height
  final List<Layer> layers;    // Ordered layers (back to front)
  final List<Sound> sounds;    // Audio tracks

  // Runtime
  String? archivePath;         // Path to ZIP file
  int sampleSize;              // Image downsampling factor

  Comics({
    required this.version,
    required this.width,
    required this.height,
    required this.layers,
    required this.sounds,
  });

  factory Comics.fromJson(Map<String, dynamic> json) {
    int version = json['version'] ?? 1;  // Default to v1
    return Comics(
      version: version,
      width: json['width'],
      height: json['height'],
      layers: (json['layers'] as List)
          .map((l) => Layer.fromJson(l, version))
          .toList(),
      sounds: (json['sounds'] as List)
          .map((s) => Sound.fromJson(s))
          .toList(),
    );
  }

  void process(int scrollOffset) {
    for (var layer in layers) {
      layer.buildMatrixAndAlpha(scrollOffset);
    }
  }
}
```

### Layer (base class for v1/v2)

```dart
enum LayerType { image, speechBubble }

class Layer {
  final String id;
  final LayerType type;

  // V1 & V2 common
  final List<LayerImage> images;      // Multi-language images
  final List<Animation> animations;   // Transform animations

  // V2 only
  final double zDepth;                // 0 = screen plane, +depth = farther
  final SpeechBubble? bubble;         // For type == speechBubble

  // Runtime state
  Matrix4 matrix = Matrix4.identity();
  double alpha = 1.0;
  Matrix4? inverseMatrix;

  Layer({
    required this.id,
    this.type = LayerType.image,
    required this.images,
    required this.animations,
    this.zDepth = 0.0,
    this.bubble,
  });

  factory Layer.fromJson(Map<String, dynamic> json, int version) {
    LayerType type = LayerType.image;
    double zDepth = 0.0;
    SpeechBubble? bubble;

    if (version >= 2) {
      String typeStr = json['type'] ?? 'image';
      type = typeStr == 'speechBubble'
          ? LayerType.speechBubble
          : LayerType.image;
      zDepth = (json['zDepth'] ?? 0.0).toDouble();

      if (type == LayerType.speechBubble && json['bubble'] != null) {
        bubble = SpeechBubble.fromJson(json['bubble']);
      }
    }

    return Layer(
      id: json['id'] ?? '',
      type: type,
      images: (json['images'] as List)
          .map((i) => LayerImage.fromJson(i))
          .toList(),
      animations: (json['animations'] as List)
          .map((a) => Animation.fromJson(a))
          .toList(),
      zDepth: zDepth,
      bubble: bubble,
    );
  }

  LayerImage? getImage(String language) {
    // V1: images array has language-specific images
    // V2: same, but speechBubbles use backgroundImage
    return images.firstWhere(
      (img) => img.language == language,
      orElse: () => images.first,
    );
  }

  void buildMatrixAndAlpha(int scrollOffset) {
    // Find active animations at scrollOffset
    // Interpolate between prev and current animation states
    // Build transform matrix: translate → rotate → scale
    // Calculate alpha from alpha animations
    // Cache inverse matrix for hit detection

    matrix = Matrix4.identity();
    alpha = 1.0;

    // Group animations by type
    var translates = animations.whereType<TranslateAnimation>();
    var rotates = animations.whereType<RotateAnimation>();
    var scales = animations.whereType<ScaleAnimation>();
    var alphas = animations.whereType<AlphaAnimation>();

    // Apply translate
    var translate = _interpolateAnimation<TranslateAnimation>(
      translates.toList(),
      scrollOffset
    );
    if (translate != null) {
      matrix.translate(translate.x.toDouble(), translate.y.toDouble());
    }

    // Apply rotate
    var rotate = _interpolateAnimation<RotateAnimation>(
      rotates.toList(),
      scrollOffset
    );
    if (rotate != null) {
      matrix.translate(rotate.pivotX, rotate.pivotY);
      matrix.rotateZ(rotate.angle * (3.14159 / 180)); // deg to rad
      matrix.translate(-rotate.pivotX, -rotate.pivotY);
    }

    // Apply scale
    var scale = _interpolateAnimation<ScaleAnimation>(
      scales.toList(),
      scrollOffset
    );
    if (scale != null) {
      matrix.translate(scale.pivotX, scale.pivotY);
      matrix.scale(scale.scaleX, scale.scaleY);
      matrix.translate(-scale.pivotX, -scale.pivotY);
    }

    // Apply alpha
    var alphaAnim = _interpolateAnimation<AlphaAnimation>(
      alphas.toList(),
      scrollOffset
    );
    if (alphaAnim != null) {
      alpha = alphaAnim.alpha;
    }

    // Cache inverse for hit detection
    inverseMatrix = Matrix4.inverted(matrix);
  }

  T? _interpolateAnimation<T extends Animation>(
    List<T> anims,
    int scrollOffset
  ) {
    // Find animations bracketing scrollOffset
    // Use cubic easing: f(t) = (t-1)³ + 1
    // Interpolate values between prev and current
    // Return interpolated animation state
    // (Implementation details in Animation class)
    return null; // Placeholder
  }
}
```

### LayerImage

```dart
class LayerImage {
  final String language;  // 'ru', 'en', 'hi', etc.
  final String file;      // Path in ZIP: 'layers/bg_ru.png'
  final int width;
  final int height;
  final String? popup;    // Optional popup reference (future)

  LayerImage({
    required this.language,
    required this.file,
    required this.width,
    required this.height,
    this.popup,
  });

  factory LayerImage.fromJson(Map<String, dynamic> json) {
    // V1 format: {lang: 'ru', file: '...', width: ..., height: ...}
    return LayerImage(
      language: json['lang'] ?? 'ru',
      file: json['file'],
      width: json['width'],
      height: json['height'],
      popup: json['popup'],
    );
  }
}
```

### SpeechBubble (V2 only)

```dart
class SpeechBubble {
  final String backgroundImage;           // Path to bubble shape PNG
  final Map<String, String> text;         // {ru: '...', en: '...', hi: '...'}
  final TextStyle textStyle;
  final Offset position;                  // Position within layer
  final double width;                     // Text container width

  SpeechBubble({
    required this.backgroundImage,
    required this.text,
    required this.textStyle,
    required this.position,
    required this.width,
  });

  factory SpeechBubble.fromJson(Map<String, dynamic> json) {
    return SpeechBubble(
      backgroundImage: json['backgroundImage'],
      text: Map<String, String>.from(json['text']),
      textStyle: _parseTextStyle(json['textStyle']),
      position: Offset(
        (json['position']['x'] as num).toDouble(),
        (json['position']['y'] as num).toDouble(),
      ),
      width: (json['width'] as num).toDouble(),
    );
  }

  static TextStyle _parseTextStyle(Map<String, dynamic> json) {
    return TextStyle(
      fontFamily: json['font'],
      fontSize: (json['size'] as num).toDouble(),
      color: _parseColor(json['color']),
    );
  }

  static Color _parseColor(String hex) {
    // Parse '#RRGGBB' or '#AARRGGBB'
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  String getText(String language) {
    return text[language] ?? text['ru'] ?? text.values.first;
  }
}
```

### Animation (base class)

```dart
abstract class Animation {
  final int start;      // Scroll offset where animation starts
  final int end;        // Scroll offset where animation ends

  Animation({required this.start, required this.end});

  bool get isPoint => start == end;

  bool isActive(int scrollOffset) {
    return scrollOffset >= start && scrollOffset <= end;
  }

  double getFraction(int scrollOffset) {
    if (start == end) return 1.0;
    double t = (scrollOffset - start) / (end - start);
    t = t.clamp(0.0, 1.0);
    // Cubic easing: f(t) = (t-1)³ + 1
    return (t - 1) * (t - 1) * (t - 1) + 1;
  }

  factory Animation.fromJson(Map<String, dynamic> json) {
    String type = json['type'];
    switch (type) {
      case 'translate':
        return TranslateAnimation.fromJson(json);
      case 'rotate':
        return RotateAnimation.fromJson(json);
      case 'scale':
        return ScaleAnimation.fromJson(json);
      case 'alpha':
        return AlphaAnimation.fromJson(json);
      case 'sound':
        return SoundAnimation.fromJson(json);
      default:
        throw Exception('Unknown animation type: $type');
    }
  }
}

class TranslateAnimation extends Animation {
  final int x;
  final int y;

  TranslateAnimation({
    required int start,
    required int end,
    required this.x,
    required this.y,
  }) : super(start: start, end: end);

  factory TranslateAnimation.fromJson(Map<String, dynamic> json) {
    return TranslateAnimation(
      start: json['start'],
      end: json['end'],
      x: json['x'] ?? 0,
      y: json['y'] ?? 0,
    );
  }
}

class RotateAnimation extends Animation {
  final double angle;    // Degrees
  final double pivotX;
  final double pivotY;

  RotateAnimation({
    required int start,
    required int end,
    required this.angle,
    required this.pivotX,
    required this.pivotY,
  }) : super(start: start, end: end);

  factory RotateAnimation.fromJson(Map<String, dynamic> json) {
    return RotateAnimation(
      start: json['start'],
      end: json['end'],
      angle: (json['angle'] as num).toDouble(),
      pivotX: (json['pivotX'] as num?)?.toDouble() ?? 0.0,
      pivotY: (json['pivotY'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ScaleAnimation extends Animation {
  final double scaleX;
  final double scaleY;
  final double pivotX;
  final double pivotY;

  ScaleAnimation({
    required int start,
    required int end,
    required this.scaleX,
    required this.scaleY,
    required this.pivotX,
    required this.pivotY,
  }) : super(start: start, end: end);

  factory ScaleAnimation.fromJson(Map<String, dynamic> json) {
    return ScaleAnimation(
      start: json['start'],
      end: json['end'],
      scaleX: (json['scaleX'] as num?)?.toDouble() ?? 1.0,
      scaleY: (json['scaleY'] as num?)?.toDouble() ?? 1.0,
      pivotX: (json['pivotX'] as num?)?.toDouble() ?? 0.0,
      pivotY: (json['pivotY'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AlphaAnimation extends Animation {
  final double alpha;    // 0.0 - 1.0

  AlphaAnimation({
    required int start,
    required int end,
    required this.alpha,
  }) : super(start: start, end: end);

  factory AlphaAnimation.fromJson(Map<String, dynamic> json) {
    return AlphaAnimation(
      start: json['start'],
      end: json['end'],
      alpha: (json['alpha'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
```

### Sound

```dart
class Sound {
  final String file;                     // Path in ZIP: 'sounds/bg_music.mp3'
  final List<SoundAnimation> animations; // Playback triggers

  // Runtime
  AudioPlayer? player;
  bool isPlaying = false;

  Sound({
    required this.file,
    required this.animations,
  });

  factory Sound.fromJson(Map<String, dynamic> json) {
    return Sound(
      file: json['file'],
      animations: (json['animations'] as List)
          .map((a) => SoundAnimation.fromJson(a))
          .toList(),
    );
  }
}

class SoundAnimation extends Animation {
  final bool loop;       // For range animations

  SoundAnimation({
    required int start,
    required int end,
    this.loop = false,
  }) : super(start: start, end: end);

  factory SoundAnimation.fromJson(Map<String, dynamic> json) {
    return SoundAnimation(
      start: json['start'],
      end: json['end'],
      loop: json['loop'] ?? false,
    );
  }

  bool get isPointSound => isPoint;
  bool get isRangeSound => !isPoint;
}
```

## Widget Architecture

### ComicViewerWidget (main component)

```dart
class ComicViewerWidget extends StatefulWidget {
  final Comics comics;
  final String initialLanguage;
  final double? initialScrollOffset;
  final VoidCallback? onScrollChanged;
  final bool soundEnabled;

  const ComicViewerWidget({
    Key? key,
    required this.comics,
    this.initialLanguage = 'ru',
    this.initialScrollOffset,
    this.onScrollChanged,
    this.soundEnabled = true,
  }) : super(key: key);

  @override
  State<ComicViewerWidget> createState() => _ComicViewerWidgetState();
}

class _ComicViewerWidgetState extends State<ComicViewerWidget> {
  late ScrollController _scrollController;
  late ComicAnimationController _animationController;
  late AudioSyncController _audioController;
  late String _currentLanguage;

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.initialLanguage;
    _scrollController = ScrollController(
      initialScrollOffset: widget.initialScrollOffset ?? 0.0,
    );
    _animationController = ComicAnimationController(widget.comics);
    _audioController = AudioSyncController(
      widget.comics.sounds,
      enabled: widget.soundEnabled,
    );

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    double offset = _scrollController.offset;
    _animationController.update(offset.toInt());
    _audioController.update(offset.toInt());
    widget.onScrollChanged?.call();
  }

  void changeLanguage(String language) {
    setState(() {
      _currentLanguage = language;
      // Layers will rebuild with new language images
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: widget.comics.height.toDouble(),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: ComicLayersPainter(
                comics: widget.comics,
                language: _currentLanguage,
              ),
              size: Size(
                MediaQuery.of(context).size.width,
                widget.comics.height.toDouble(),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    _audioController.dispose();
    super.dispose();
  }
}
```

### ComicAnimationController

```dart
class ComicAnimationController extends ChangeNotifier {
  final Comics comics;
  int _currentScrollOffset = 0;

  ComicAnimationController(this.comics);

  void update(int scrollOffset) {
    if (_currentScrollOffset != scrollOffset) {
      _currentScrollOffset = scrollOffset;
      comics.process(scrollOffset);
      notifyListeners();
    }
  }

  int get scrollOffset => _currentScrollOffset;
}
```

### AudioSyncController

```dart
class AudioSyncController {
  final List<Sound> sounds;
  final bool enabled;

  int _currentScrollOffset = 0;
  final Set<int> _triggeredPointSounds = {};
  final Map<int, bool> _activeRangeSounds = {};

  AudioSyncController(this.sounds, {this.enabled = true}) {
    _initializePlayers();
  }

  void _initializePlayers() async {
    // Create AudioPlayer instances for each sound
    // Load sound files from archive
  }

  void update(int scrollOffset) {
    if (!enabled) return;

    for (int i = 0; i < sounds.length; i++) {
      Sound sound = sounds[i];

      for (SoundAnimation anim in sound.animations) {
        if (anim.isPointSound) {
          _handlePointSound(i, sound, anim, scrollOffset);
        } else {
          _handleRangeSound(i, sound, anim, scrollOffset);
        }
      }
    }

    _currentScrollOffset = scrollOffset;
  }

  void _handlePointSound(int index, Sound sound, SoundAnimation anim, int offset) {
    // Trigger once when crossing the point
    bool justCrossed = _currentScrollOffset < anim.start && offset >= anim.start;
    String key = '$index-${anim.start}';

    if (justCrossed && !_triggeredPointSounds.contains(key)) {
      sound.player?.play();
      _triggeredPointSounds.add(key);
    }
  }

  void _handleRangeSound(int index, Sound sound, SoundAnimation anim, int offset) {
    bool inRange = offset >= anim.start && offset <= anim.end;
    bool wasPlaying = _activeRangeSounds[index] ?? false;

    if (inRange && !wasPlaying) {
      // Start playing with fade-in
      sound.player?.play();
      if (anim.loop) {
        sound.player?.setLoopMode(LoopMode.one);
      }
      _activeRangeSounds[index] = true;

    } else if (!inRange && wasPlaying) {
      // Stop with fade-out
      _fadeOut(sound.player, duration: Duration(milliseconds: 600));
      _activeRangeSounds[index] = false;
    }
  }

  void _fadeOut(AudioPlayer? player, {required Duration duration}) async {
    // Gradual volume decrease over duration
    if (player == null) return;

    const steps = 10;
    final stepDuration = duration.inMilliseconds ~/ steps;

    for (int i = steps; i >= 0; i--) {
      await Future.delayed(Duration(milliseconds: stepDuration));
      await player.setVolume(i / steps);
    }

    await player.stop();
    await player.setVolume(1.0);
  }

  void dispose() {
    for (var sound in sounds) {
      sound.player?.dispose();
    }
  }
}
```

### ComicLayersPainter (CustomPainter)

```dart
class ComicLayersPainter extends CustomPainter {
  final Comics comics;
  final String language;

  ComicLayersPainter({
    required this.comics,
    required this.language,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Sort layers by zDepth (v2) or render in order (v1)
    List<Layer> sortedLayers = comics.version >= 2
        ? [...comics.layers]..sort((a, b) => a.zDepth.compareTo(b.zDepth))
        : comics.layers;

    for (Layer layer in sortedLayers) {
      _paintLayer(canvas, size, layer);
    }
  }

  void _paintLayer(Canvas canvas, Size size, Layer layer) {
    canvas.save();

    // Apply layer matrix transform
    canvas.transform(layer.matrix.storage);

    // Apply z-depth perspective (v2)
    if (comics.version >= 2 && layer.zDepth != 0) {
      _applyPerspective(canvas, size, layer.zDepth);
    }

    // Get image for current language
    LayerImage? image = layer.getImage(language);
    if (image == null) return;

    // Draw layer based on type
    if (layer.type == LayerType.image) {
      _drawImageLayer(canvas, image, layer.alpha);
    } else if (layer.type == LayerType.speechBubble && layer.bubble != null) {
      _drawSpeechBubbleLayer(canvas, image, layer.bubble!, layer.alpha);
    }

    canvas.restore();
  }

  void _applyPerspective(Canvas canvas, Size size, double zDepth) {
    // Simple perspective transform based on z-depth
    // Farther objects (positive zDepth) appear smaller and centered
    // Scale factor: s = 1 / (1 + zDepth/1000)

    double scale = 1.0 / (1.0 + zDepth / 1000.0);
    double centerX = size.width / 2;
    double centerY = size.height / 2;

    canvas.translate(centerX, centerY);
    canvas.scale(scale, scale);
    canvas.translate(-centerX, -centerY);
  }

  void _drawImageLayer(Canvas canvas, LayerImage image, double alpha) {
    // Load cached image (or placeholder if loading)
    ui.Image? loadedImage = ImageCacheManager.instance.getImage(image.file);

    if (loadedImage != null) {
      Paint paint = Paint()..color = Color.fromRGBO(255, 255, 255, alpha);
      canvas.drawImage(loadedImage, Offset.zero, paint);
    } else {
      // Draw placeholder or trigger async load
      ImageCacheManager.instance.loadImage(image.file);
    }
  }

  void _drawSpeechBubbleLayer(
    Canvas canvas,
    LayerImage backgroundImage,
    SpeechBubble bubble,
    double alpha,
  ) {
    // Draw background bubble shape
    _drawImageLayer(canvas, backgroundImage, alpha);

    // Draw text overlay
    String text = bubble.getText(language);
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: bubble.textStyle.copyWith(
          color: bubble.textStyle.color?.withOpacity(alpha),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: bubble.width);
    textPainter.paint(canvas, bubble.position);
  }

  @override
  bool shouldRepaint(ComicLayersPainter oldDelegate) {
    return oldDelegate.language != language ||
           oldDelegate.comics != comics;
  }
}
```

## Rendering Strategy

### Image Loading & Tiling

**Challenge**: Flutter не имеет встроенного CATiledLayer. Нужна альтернатива для эффективной загрузки больших изображений.

**Solution**: Гибридный подход

1. **Small images (< 2048x2048)**: Load full image, no tiling
2. **Large images (>= 2048px)**:
   - Pre-generate tiles at build time (512x512 or 1024x1024)
   - Store tiles in ZIP: `layers/{layerId}/tile_{scale}_{col}_{row}.png`
   - Load only visible tiles based on viewport
   - Use `CustomPaint` with manual tile rendering

**Tile Naming Convention** (compatible with legacy):
```
layers/layer-bg/tile_1000_0_0.png  // scale=1.0, column=0, row=0
layers/layer-bg/tile_1000_0_1.png
layers/layer-bg/tile_500_0_0.png   // scale=0.5 for lower quality
```

**ImageCacheManager** (Singleton):

```dart
class ImageCacheManager {
  static final ImageCacheManager instance = ImageCacheManager._();
  ImageCacheManager._();

  final Map<String, ui.Image> _cache = {};
  final Map<String, Future<ui.Image>> _loading = {};
  final int _maxCacheSize = 50; // Max images in memory

  ui.Image? getImage(String path) {
    return _cache[path];
  }

  Future<ui.Image> loadImage(String path) async {
    if (_cache.containsKey(path)) {
      return _cache[path]!;
    }

    if (_loading.containsKey(path)) {
      return _loading[path]!;
    }

    Future<ui.Image> loadFuture = _loadImageFromArchive(path);
    _loading[path] = loadFuture;

    ui.Image image = await loadFuture;
    _cache[path] = image;
    _loading.remove(path);

    _evictIfNeeded();

    return image;
  }

  Future<ui.Image> _loadImageFromArchive(String path) async {
    // Load from ZIP archive
    // Decode PNG/JPEG bytes to ui.Image
    // Use compute() for decoding to avoid blocking UI

    Uint8List bytes = await EpisodeArchiveLoader.instance.extractFile(path);
    return await _decodeImage(bytes);
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  void _evictIfNeeded() {
    if (_cache.length > _maxCacheSize) {
      // Remove oldest entries (simple LRU)
      _cache.remove(_cache.keys.first);
    }
  }

  void clear() {
    _cache.clear();
    _loading.clear();
  }
}
```

## Storage & Archive Management

### EpisodeStorageManager

```dart
class EpisodeStorageManager {
  static final EpisodeStorageManager instance = EpisodeStorageManager._();
  EpisodeStorageManager._();

  late Directory _cacheDir;
  late Database _db; // sqflite for metadata

  Future<void> initialize() async {
    _cacheDir = await getApplicationDocumentsDirectory();
    _db = await _openDatabase();
  }

  Future<Database> _openDatabase() async {
    String path = join(_cacheDir.path, 'episodes.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE episodes (
            id TEXT PRIMARY KEY,
            downloadUrl TEXT,
            localPath TEXT,
            downloadedAt INTEGER,
            size INTEGER,
            version INTEGER
          )
        ''');
      },
    );
  }

  Future<String?> getEpisodePath(String episodeId) async {
    List<Map> results = await _db.query(
      'episodes',
      where: 'id = ?',
      whereArgs: [episodeId],
    );

    if (results.isNotEmpty) {
      return results.first['localPath'] as String;
    }
    return null;
  }

  Future<String> downloadEpisode(
    String episodeId,
    String downloadUrl,
    {Function(double progress)? onProgress}
  ) async {
    String savePath = join(_cacheDir.path, 'episodes', '$episodeId.zip');

    // Download with dio
    Dio dio = Dio();
    await dio.download(
      downloadUrl,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          onProgress?.call(received / total);
        }
      },
    );

    // Save metadata
    await _db.insert(
      'episodes',
      {
        'id': episodeId,
        'downloadUrl': downloadUrl,
        'localPath': savePath,
        'downloadedAt': DateTime.now().millisecondsSinceEpoch,
        'size': await File(savePath).length(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return savePath;
  }

  Future<void> deleteEpisode(String episodeId) async {
    String? path = await getEpisodePath(episodeId);
    if (path != null) {
      await File(path).delete();
      await _db.delete('episodes', where: 'id = ?', whereArgs: [episodeId]);
    }
  }

  Future<List<Map<String, dynamic>>> getCachedEpisodes() async {
    return await _db.query('episodes', orderBy: 'downloadedAt DESC');
  }
}
```

### EpisodeArchiveLoader

```dart
class EpisodeArchiveLoader {
  static final EpisodeArchiveLoader instance = EpisodeArchiveLoader._();
  EpisodeArchiveLoader._();

  Archive? _currentArchive;
  String? _currentArchivePath;

  Future<Comics> loadEpisode(String archivePath) async {
    if (_currentArchivePath != archivePath) {
      await _loadArchive(archivePath);
    }

    // Extract and parse data.json
    Uint8List dataJsonBytes = await extractFile('data.json');
    String dataJsonString = utf8.decode(dataJsonBytes);
    Map<String, dynamic> dataJson = jsonDecode(dataJsonString);

    // Create Comics model
    Comics comics = Comics.fromJson(dataJson);
    comics.archivePath = archivePath;

    return comics;
  }

  Future<void> _loadArchive(String path) async {
    File file = File(path);
    Uint8List bytes = await file.readAsBytes();
    _currentArchive = ZipDecoder().decodeBytes(bytes);
    _currentArchivePath = path;
  }

  Future<Uint8List> extractFile(String filename) async {
    if (_currentArchive == null) {
      throw Exception('No archive loaded');
    }

    ArchiveFile? file = _currentArchive!.findFile(filename);
    if (file == null) {
      throw Exception('File not found in archive: $filename');
    }

    return file.content as Uint8List;
  }

  void close() {
    _currentArchive = null;
    _currentArchivePath = null;
  }
}
```

## Edge Cases & Error Handling

| Case | Trigger | Expected Behavior |
|------|---------|-------------------|
| **Missing data.json** | ZIP doesn't contain data.json | Show error: "Invalid episode file", don't crash |
| **Corrupted JSON** | data.json parse fails | Show error with details, log for debugging |
| **Unknown version** | version field is 3+ | Attempt to parse as v2, warn about unsupported features |
| **Missing layer image** | Image file not in ZIP | Show placeholder (colored rect), log warning |
| **Unsupported animation** | Unknown animation type | Skip animation, log warning, continue rendering |
| **Large memory usage** | Too many images cached | Evict old images (LRU), limit cache to 50MB |
| **Download failure** | Network error during download | Retry 3 times, show error if all fail, allow manual retry |
| **Disk full** | No space for download | Show clear error: "Not enough storage space" |
| **Language not available** | User selects language not in layer.images | Fall back to first available language (usually 'ru') |
| **Speech bubble missing text** | bubble.text doesn't have current language | Fall back to 'ru', then first available |
| **Audio file missing** | Sound file not in ZIP | Skip sound, log warning, don't block rendering |
| **Audio playback fails** | Codec not supported | Log error, continue without sound |
| **Zero-height comics** | height == 0 in data.json | Use default height (8000px), log warning |
| **Negative zDepth** | Layer has negative zDepth | Clamp to 0, log warning |
| **Scroll out of bounds** | User scrolls beyond content | Clamp scroll position, no crash |
| **Concurrent language switch** | Language changes during render | Cancel old render, start new with new language |

## Dependencies

### Flutter Packages

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Archive handling
  archive: ^3.4.0              # ZIP extraction

  # Audio playback
  audioplayers: ^5.2.0         # Cross-platform audio

  # Storage
  path_provider: ^2.1.0        # Get app directories
  sqflite: ^2.3.0              # Local database for cache metadata

  # Network
  dio: ^5.4.0                  # HTTP with progress tracking

  # Utilities
  path: ^1.8.3                 # Path manipulation

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0              # Testing
  flutter_lints: ^3.0.0        # Linting
```

### External Dependencies

- **After Effects ExtendScript**: Separate tool for exporting v2 format
  - Repository: TBD (new project)
  - Exports keyframes, transforms, easing from AE comp
  - Generates v2 data.json with zDepth, speechBubbles

## Testing Strategy

### Unit Tests

- [ ] Comics.fromJson() - v1 and v2 parsing
- [ ] Layer.buildMatrixAndAlpha() - animation interpolation
- [ ] Animation easing function - cubic interpolation correctness
- [ ] SpeechBubble.getText() - language fallback logic
- [ ] ImageCacheManager - cache eviction, loading
- [ ] AudioSyncController - point/range sound triggering
- [ ] EpisodeStorageManager - download, cache, delete

### Integration Tests

- [ ] Load v1 episode → verify all layers render
- [ ] Load v2 episode with zDepth → verify depth sorting
- [ ] Load v2 with speech bubbles → verify text overlay
- [ ] Scroll through episode → verify animations play smoothly
- [ ] Switch language → verify layers update without reload
- [ ] Play audio → verify point/range sounds trigger correctly
- [ ] Download episode → verify progress tracking and cache storage
- [ ] Offline playback → verify cached episode loads without network

### Manual Verification

- [ ] Visual: Render matches legacy Android/iOS output
- [ ] Performance: 60fps scroll on mid-range devices
- [ ] Memory: <100MB usage for typical episode
- [ ] Audio: Sounds fade smoothly, no crackling
- [ ] Language: All 3 languages (ru, en, hi) display correctly
- [ ] Speech bubbles: Text renders centered, readable
- [ ] 3D depth: Farther layers appear smaller (VR mode)

## Migration / Rollout

### Phase 1: Standalone Package
- Create `comic_viewer` Flutter package
- Implement core rendering (v1 support only)
- Test with legacy episodes

### Phase 2: V2 Format Support
- Add zDepth rendering
- Add speech bubble system
- Create After Effects export tool

### Phase 3: Integration
- Integrate into Android app (FlutterView)
- Integrate into iOS app (FlutterViewController)
- A/B test: legacy vs Flutter component

### Phase 4: Full Migration
- Replace all legacy code
- Remove Java/Swift implementations
- Ship unified app

### Data Migration
- No migration needed (ZIP format unchanged)
- V2 episodes will coexist with v1
- Legacy apps ignore v2 fields (graceful degradation)

## Design Decisions (Finalized)

### ✅ 1. Tiling Strategy
**Decision**: Поддержка нескольких размеров тайлов с автоматическим выбором
- **Tile sizes**: 512x512, 1024x1024, 2048x2048 (custom для retina/high-DPI)
- **Selection logic**:
  ```dart
  int getTileSize(double devicePixelRatio) {
    if (devicePixelRatio >= 3.0) return 2048; // Retina displays
    if (devicePixelRatio >= 2.0) return 1024; // High-DPI
    return 512;                                 // Standard
  }
  ```
- **Naming convention**: `tile_{scale}_{size}_{col}_{row}.png`
  - Example: `tile_1000_1024_0_0.png` (scale 1.0, size 1024x1024)
- **Fallback**: If custom size not available, use next smaller size
- **Build-time generation**: Content pipeline pre-generates all tile sizes

**Rationale**: Максимальная гибкость для разных устройств, оптимальная производительность

### ✅ 2. 3D Rendering (z-depth)
**Decision**: Adaptive approach с двумя режимами
- **Simple mode** (default, mobile):
  ```dart
  // Scale-based perspective
  double scale = 1.0 / (1.0 + zDepth / 1000.0);
  canvas.scale(scale, scale);
  ```
  - Pros: Fast, low CPU usage, 60fps on mid-range devices
  - Cons: Not geometrically accurate, no vanishing point

- **Advanced mode** (VR/dome, high-end devices):
  ```dart
  // Full perspective matrix with vanishing point
  Matrix4 perspective = Matrix4.identity()
    ..setEntry(3, 2, -0.001)  // Perspective strength
    ..translate(0.0, 0.0, -zDepth);
  canvas.transform(perspective.storage);
  ```
  - Pros: Realistic 3D, proper vanishing point, immersive for VR/dome
  - Cons: Higher CPU cost, may drop to 30fps on low-end devices

- **Mode selection**:
  ```dart
  enum PerspectiveMode { simple, advanced }

  PerspectiveMode getMode(DeviceInfo device) {
    if (device.isVR || device.isDome) return PerspectiveMode.advanced;
    if (device.benchmarkScore > 8000) return PerspectiveMode.advanced;
    return PerspectiveMode.simple;
  }
  ```

**Rationale**: Balance между производительностью и качеством, адаптация к платформе

### ✅ 3. After Effects Export Scope
**Decision**: Export только для V2 формата
- **V1 format**: **Deprecated, read-only**
  - No new content creation
  - Legacy episodes continue to work
  - No After Effects export support

- **V2 format**: **Full After Effects integration**
  - **Supported AE properties**:
    - ✅ Position (keyframes → TranslateAnimation)
    - ✅ Rotation (keyframes → RotateAnimation)
    - ✅ Scale (keyframes → ScaleAnimation)
    - ✅ Opacity (keyframes → AlphaAnimation)
    - ✅ Easing curves (AE easing → cubic/custom easing functions)
    - ✅ Layer parenting (transform hierarchy)
    - ✅ 3D layers (z-position → zDepth)
    - ✅ Text layers (→ SpeechBubble with auto-layout)
    - ✅ Expressions (simple math expressions → baked keyframes)

  - **NOT supported** (future/advanced):
    - ❌ Effects (blur, glow, etc.) - requires shader support
    - ❌ Masks/mattes - complex to render in Flutter
    - ❌ Shape layers - would need vector rendering
    - ❌ 3D cameras - VR/dome only feature

- **ExtendScript tool**: `ae-to-mahabharata-v2` (new repository)
  - Input: After Effects composition
  - Output: `data.json` (v2 format) + exported PNG layers
  - Bakes expressions to keyframes at specified FPS
  - Auto-detects text layers → converts to speechBubbles

**Rationale**: Focus на v2, избегаем поддержки legacy, упрощаем миграцию

---

## Updated Architecture Notes

### Tile Loading with Multi-Size Support

```dart
class ImageCacheManager {
  // Enhanced to support multiple tile sizes

  Future<ui.Image> loadTile({
    required String layerId,
    required int scale,    // 1000 for 1.0x
    required int col,
    required int row,
    int? preferredSize,    // null = auto-detect
  }) async {
    int tileSize = preferredSize ?? _getOptimalTileSize();

    // Try preferred size first
    String path = 'layers/$layerId/tile_${scale}_${tileSize}_${col}_${row}.png';

    try {
      return await loadImage(path);
    } catch (e) {
      // Fallback to smaller tile sizes
      for (int size in [2048, 1024, 512]) {
        if (size >= tileSize) continue;

        String fallbackPath = 'layers/$layerId/tile_${scale}_${size}_${col}_${row}.png';
        try {
          return await loadImage(fallbackPath);
        } catch (_) {
          continue;
        }
      }

      throw Exception('No tiles found for layer $layerId');
    }
  }

  int _getOptimalTileSize() {
    double dpr = WidgetsBinding.instance.window.devicePixelRatio;
    if (dpr >= 3.0) return 2048;
    if (dpr >= 2.0) return 1024;
    return 512;
  }
}
```

### Adaptive 3D Rendering

```dart
class ComicLayersPainter extends CustomPainter {
  final PerspectiveMode perspectiveMode;

  void _applyPerspective(Canvas canvas, Size size, double zDepth) {
    if (perspectiveMode == PerspectiveMode.simple) {
      _applySimplePerspective(canvas, size, zDepth);
    } else {
      _applyAdvancedPerspective(canvas, size, zDepth);
    }
  }

  void _applySimplePerspective(Canvas canvas, Size size, double zDepth) {
    double scale = 1.0 / (1.0 + zDepth / 1000.0);
    double centerX = size.width / 2;
    double centerY = size.height / 2;

    canvas.translate(centerX, centerY);
    canvas.scale(scale, scale);
    canvas.translate(-centerX, -centerY);
  }

  void _applyAdvancedPerspective(Canvas canvas, Size size, double zDepth) {
    // Full perspective matrix
    Matrix4 perspective = Matrix4.identity();

    // Set perspective strength (field of view)
    perspective.setEntry(3, 2, -0.001);

    // Translate in Z
    perspective.translate(0.0, 0.0, -zDepth);

    // Apply to canvas
    canvas.transform(perspective.storage);
  }
}
```

### V2 Format Example (with AE export)

```json
{
  "version": 2,
  "width": 2048,
  "height": 8000,
  "meta": {
    "createdWith": "ae-to-mahabharata-v2",
    "aeCompName": "Episode_01_Scene_05",
    "exportDate": "2025-12-31T10:30:00Z"
  },
  "layers": [
    {
      "id": "layer-bg",
      "type": "image",
      "file": "layers/bg.png",
      "zDepth": 0,
      "animations": []
    },
    {
      "id": "layer-character",
      "type": "image",
      "file": "layers/character.png",
      "zDepth": 150,
      "parent": null,
      "animations": [
        {
          "type": "translate",
          "start": 0,
          "end": 1000,
          "x": 100,
          "y": -200,
          "easing": "easeOutCubic"
        },
        {
          "type": "scale",
          "start": 500,
          "end": 1500,
          "scaleX": 1.2,
          "scaleY": 1.2,
          "pivotX": 512,
          "pivotY": 256,
          "easing": "easeInOutQuad"
        }
      ]
    },
    {
      "id": "bubble-speech-01",
      "type": "speechBubble",
      "zDepth": 200,
      "bubble": {
        "backgroundImage": "layers/bubble_01.png",
        "text": {
          "ru": "Приветствую тебя, воин!",
          "en": "Greetings, warrior!",
          "hi": "नमस्ते योद्धा!"
        },
        "textStyle": {
          "font": "Roboto",
          "size": 28,
          "color": "#2C3E50",
          "bold": true,
          "align": "center"
        },
        "position": {"x": 100, "y": 50},
        "width": 600,
        "autoLayout": true
      },
      "animations": [
        {
          "type": "alpha",
          "start": 800,
          "end": 1000,
          "alpha": 1.0,
          "easing": "easeIn"
        }
      ]
    }
  ],
  "sounds": [
    {
      "file": "sounds/ambient_wind.mp3",
      "animations": [
        {
          "type": "sound",
          "start": 0,
          "end": 8000,
          "loop": true
        }
      ]
    }
  ]
}
```

---

## Next Steps

All design questions resolved. Ready to proceed to PLAN phase once specifications approved.

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2025-12-31
- [x] Notes: All design decisions finalized
  - Multi-size tiling (512/1024/2048) with device-adaptive selection
  - Dual perspective modes (simple for mobile, advanced for VR/dome)
  - After Effects export for V2 only (V1 deprecated, read-only)
