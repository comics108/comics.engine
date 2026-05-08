/// Information about a loaded comics scene
class ComicsInfo {
  /// Width of the scene in logical pixels
  final int width;

  /// Height of the scene in logical pixels
  final int height;

  /// Number of layers in the scene
  final int layerCount;

  /// Whether the scene contains sound triggers
  final bool hasSound;

  const ComicsInfo({
    required this.width,
    required this.height,
    required this.layerCount,
    required this.hasSound,
  });

  factory ComicsInfo.fromMap(Map<String, dynamic> map) {
    return ComicsInfo(
      width: map['width'] as int,
      height: map['height'] as int,
      layerCount: map['layerCount'] as int,
      hasSound: map['hasSound'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
      'layerCount': layerCount,
      'hasSound': hasSound,
    };
  }

  @override
  String toString() =>
      'ComicsInfo(width: $width, height: $height, layers: $layerCount, hasSound: $hasSound)';
}

/// Result of a hit-test operation
class HitTestResult {
  /// Index of the layer that was hit (back-to-front order)
  final int layerIndex;

  /// Path to popup image if the layer has one
  final String? popupPath;

  /// Whether a non-transparent pixel was hit
  final bool isHit;

  const HitTestResult({
    required this.layerIndex,
    this.popupPath,
    required this.isHit,
  });

  factory HitTestResult.fromMap(Map<String, dynamic> map) {
    return HitTestResult(
      layerIndex: map['layerIndex'] as int,
      popupPath: map['popupPath'] as String?,
      isHit: map['isHit'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'layerIndex': layerIndex,
      'popupPath': popupPath,
      'isHit': isHit,
    };
  }

  @override
  String toString() =>
      'HitTestResult(layer: $layerIndex, popup: $popupPath, isHit: $isHit)';
}

/// Event emitted when scroll position changes
class ScrollEvent {
  /// Current scroll offset in logical pixels
  final int offset;

  /// Maximum scroll offset
  final int maxOffset;

  const ScrollEvent({
    required this.offset,
    required this.maxOffset,
  });

  factory ScrollEvent.fromMap(Map<String, dynamic> map) {
    return ScrollEvent(
      offset: map['offset'] as int,
      maxOffset: map['maxOffset'] as int,
    );
  }

  /// Progress from 0.0 to 1.0
  double get progress => maxOffset > 0 ? offset / maxOffset : 0.0;

  @override
  String toString() => 'ScrollEvent(offset: $offset, max: $maxOffset)';
}

/// Event emitted when a layer is tapped
class LayerTapEvent {
  /// Index of the tapped layer
  final int layerIndex;

  /// Path to popup image if available
  final String? popupPath;

  const LayerTapEvent({
    required this.layerIndex,
    this.popupPath,
  });

  factory LayerTapEvent.fromMap(Map<String, dynamic> map) {
    return LayerTapEvent(
      layerIndex: map['layerIndex'] as int,
      popupPath: map['popupPath'] as String?,
    );
  }

  /// Whether this layer has a popup
  bool get hasPopup => popupPath != null && popupPath!.isNotEmpty;

  @override
  String toString() => 'LayerTapEvent(layer: $layerIndex, popup: $popupPath)';
}

/// Configuration for loading a comics scene
class ComicsConfig {
  /// Path to the .comics archive file
  final String archivePath;

  /// Language index for localized layers (0-based)
  final int languageIndex;

  /// Initial scroll offset
  final int initialScrollOffset;

  /// Whether zoom is enabled
  final bool zoomEnabled;

  /// Whether sound is enabled
  final bool soundEnabled;

  const ComicsConfig({
    required this.archivePath,
    this.languageIndex = 0,
    this.initialScrollOffset = 0,
    this.zoomEnabled = false,
    this.soundEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'archivePath': archivePath,
      'languageIndex': languageIndex,
      'initialScrollOffset': initialScrollOffset,
      'zoomEnabled': zoomEnabled,
      'soundEnabled': soundEnabled,
    };
  }
}
