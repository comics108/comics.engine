import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:archive/archive.dart';

import 'models.dart';
import 'read_file.dart';

/// flows/sdd-flutter-comics Plan Task 4.1: a real, portable `.comics`/
/// `.puzzle` ZIP+JSON reader for the FULL model -- generalized from
/// `flutter_comics_viewer`'s own `DartComicsViewerBackend.load()` (real,
/// already-working ZIP-open logic: find `data.json`, decode, walk
/// `raw['layers']`), reusing the SAME per-field JSON parsing algorithm
/// `apps/comics-editor/lib/src/bridge/models_mapping.dart`'s
/// `comicsFromCore` already implements for the native-core-fed path --
/// adapted here to work directly off a freshly-unzipped raw map instead of
/// the native core's, since that file stays in `apps/comics-editor`
/// (`dart:io`/native-core-coupled, per Specifications) and can't be
/// imported backwards into this shared, portable library.
///
/// Read-only, per Specifications' resolved Open Question -- no current
/// consumer needs standalone Dart-side `.comics` ZIP *writing*.
class ComicsArchiveReader {
  ComicsArchiveReader._();

  /// Opens a `.comics`/`.puzzle` ZIP from [bytes], decodes `data.json`, and
  /// returns a fully-populated [ComicsDoc] -- every field [models.dart]
  /// defines, not the subset `DartComicsViewerBackend`'s own deleted
  /// minimal model used to handle. [name] is used only for `.puzzle` vs.
  /// `.comics` [DocType] detection (mirrors `comicsFromCore`'s own
  /// filename sniff) -- raw zip bytes carry no filename of their own, so a
  /// caller that has one (e.g. [readFile]) should pass it; omitted, this
  /// defaults to [DocType.comics], matching every file whose real name
  /// isn't known.
  static Future<ComicsDoc> readBytes(Uint8List bytes, {String name = ''}) async {
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Exception catch (e) {
      throw FormatException('not a valid zip archive: $e');
    }
    final dataEntry = archive.findFile('data.json');
    if (dataEntry == null) {
      throw const FormatException('Archive has no data.json');
    }
    var text = utf8.decode(dataEntry.content as List<int>);
    if (text.startsWith('﻿')) text = text.substring(1); // real files carry a BOM
    final raw = jsonDecode(text);
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('data.json must contain an object');
    }
    return _docFromJson(raw, name);
  }

  /// Convenience wrapper for platforms with real filesystem access (mirrors
  /// `DartComicsViewerBackend`'s existing `readViewerPath` usage) --
  /// Web-safe via [readFileBytes]'s conditional-import shim.
  static Future<ComicsDoc> readFile(String path) async {
    final bytes = await readFileBytes(path);
    final name = path.split('/').last.split(r'\').last;
    return readBytes(bytes, name: name);
  }
}

double _asDouble(dynamic value, [double fallback = 0]) =>
    value is num ? value.toDouble() : fallback;

int _asInt(dynamic value, [int fallback = 0]) => value is num ? value.round() : fallback;

const _typePrefix = 'Comics.Editor.Models.';
const _typeSuffix = ', Comics.Editor';

AnimType? _animTypeFromDollarType(String? dollarType) {
  if (dollarType == null) return null;
  switch (dollarType) {
    case '${_typePrefix}TranslateAnim$_typeSuffix':
      return AnimType.translate;
    case '${_typePrefix}RotateAnim$_typeSuffix':
      return AnimType.rotate;
    case '${_typePrefix}ScaleAnim$_typeSuffix':
      return AnimType.scale;
    case '${_typePrefix}AlphaAnim$_typeSuffix':
      return AnimType.alpha;
    case '${_typePrefix}SoundAnim$_typeSuffix':
      return AnimType.sound;
  }
  return null;
}

ScrollType _asScrollType(dynamic value) => switch (value) {
      'horizontal' => ScrollType.horizontal,
      _ => ScrollType.vertical,
    };

PreferredOrientation _asPreferredOrientation(dynamic value) => switch (value) {
      'landscape' => PreferredOrientation.landscape,
      'auto' => PreferredOrientation.auto,
      _ => PreferredOrientation.portrait,
    };

LayerMask? _maskFromJson(dynamic value) {
  if (value is! Map) return null;
  final shape = value['shape'] as String?;
  if (shape == null) return null;
  Rect? rect;
  final rectJson = value['rect'] as Map?;
  if (rectJson != null) {
    rect = Rect.fromLTWH(
      _asDouble(rectJson['x']),
      _asDouble(rectJson['y']),
      _asDouble(rectJson['w']),
      _asDouble(rectJson['h']),
    );
  }
  List<Offset>? points;
  final pointsJson = value['points'] as List?;
  if (pointsJson != null) {
    points = [
      for (final p in pointsJson) Offset(_asDouble((p as Map)['x']), _asDouble(p['y'])),
    ];
  }
  return LayerMask(shape: shape, rect: rect, points: points, maskFile: value['maskFile'] as String?);
}

TextRegion? _textRegionFromJson(dynamic value) {
  if (value is! Map) return null;
  final shape = value['shape'] as String?;
  if (shape == null) return null;
  Rect? rect;
  final rectJson = value['rect'] as Map?;
  if (rectJson != null) {
    rect = Rect.fromLTWH(
      _asDouble(rectJson['x']),
      _asDouble(rectJson['y']),
      _asDouble(rectJson['w']),
      _asDouble(rectJson['h']),
    );
  }
  List<Offset>? points;
  final pointsJson = value['points'] as List?;
  if (pointsJson != null) {
    points = [
      for (final p in pointsJson) Offset(_asDouble((p as Map)['x']), _asDouble(p['y'])),
    ];
  }
  return TextRegion(
    shape: shape,
    rect: rect,
    points: points,
    maskFile: value['maskFile'] as String?,
    isHandLettered: value['isHandLettered'] as bool?,
  );
}

Anim _animFromJson(Map<String, dynamic> json, {AnimType fallback = AnimType.translate}) {
  final type = _animTypeFromDollarType(json[r'$type'] as String?) ?? fallback;
  final anim = Anim(type, start: _asInt(json['start']), end: _asInt(json['end']));
  anim.x = _asDouble(json['x']);
  anim.y = _asDouble(json['y']);
  anim.angle = _asDouble(json['angle']);
  anim.scaleX = _asDouble(json['scaleX'], 1);
  anim.scaleY = _asDouble(json['scaleY'], 1);
  anim.pivotX = _asDouble(json['pivotX']);
  anim.pivotY = _asDouble(json['pivotY']);
  anim.alpha = _asDouble(json['alpha'], 1);
  anim.basis = json['basis'] == 'time' ? AnimBasis.time : AnimBasis.scroll;
  anim.loop = json['loop'] as bool? ?? true;
  return anim;
}

ComicsDoc _docFromJson(Map<String, dynamic> raw, String name) {
  final isPuzzle = name.endsWith('.puzzle');
  final doc = ComicsDoc(
    name: name,
    type: isPuzzle ? DocType.puzzle : DocType.comics,
    width: _asInt(raw['width'], 1080),
    height: _asInt(raw['height'], 2160),
  )
    ..scrollType = _asScrollType(raw['scrollType'])
    ..preferredOrientation = _asPreferredOrientation(raw['preferredOrientation'])
    ..preferredViewportWidth = _asInt(raw['preferredViewportWidth'], 720)
    ..preferredViewportHeight = _asInt(raw['preferredViewportHeight'], 1600);

  for (final layerJson in (raw['layers'] as List? ?? const [])) {
    final layer = layerJson as Map<String, dynamic>;
    final images = (layer['images'] as List? ?? const []);
    final firstFile =
        images.isNotEmpty ? ((images.first as Map<String, dynamic>)['file'] as String? ?? '') : '';
    final uiLayer = EditorLayer(firstFile.isEmpty ? 'layer' : firstFile, id: layer['id'] as String?)
      ..preview = layer['preview'] == true
      ..kind = layer['kind'] as String?
      ..style = layer['style'] as String?
      ..parentId = layer['parentId'] as String?
      ..solidColor = layer['solidColor'] as String?
      ..mask = _maskFromJson(layer['mask'])
      ..groupId = layer['groupId'] as String?
      ..textRegion = _textRegionFromJson(layer['textRegion']);
    final translations = layer['translations'] as Map?;
    if (translations != null) {
      translations.forEach((key, value) {
        uiLayer.translations[key as String] = value as String? ?? '';
      });
    }
    uiLayer.images.clear();
    for (final imageJson in images) {
      final image = imageJson as Map<String, dynamic>;
      uiLayer.images.add(
        LayerImage(file: image['file'] as String? ?? '', popup: image['popup'] as String? ?? ''),
      );
    }
    while (uiLayer.images.length < kLangs.length) {
      uiLayer.images.add(LayerImage());
    }
    uiLayer.anims.clear();
    for (final animJson in (layer['animations'] as List? ?? const [])) {
      uiLayer.anims.add(_animFromJson(animJson as Map<String, dynamic>));
    }
    for (final anim in uiLayer.anims) {
      if (anim.type == AnimType.translate) {
        uiLayer.translate = Offset(anim.x, anim.y);
        break;
      }
    }
    doc.layers.add(uiLayer);
  }

  for (final soundJson in (raw['sounds'] as List? ?? const [])) {
    final sound = soundJson as Map<String, dynamic>;
    final uiSound = EditorSound(sound['file'] as String? ?? '');
    uiSound.anims.clear();
    for (final animJson in (sound['animations'] as List? ?? const [])) {
      uiSound.anims.add(_animFromJson(animJson as Map<String, dynamic>, fallback: AnimType.sound));
    }
    doc.sounds.add(uiSound);
  }

  return doc;
}
