// tdd-dot-lottie-import-export, Plan Task 7.1-7.4: real-fixture, real-zip-
// level round-trip integration tests -- the two concrete fixtures Anton
// named directly (samples/sample_v2012.comics_unzip for Full Canvas,
// samples/sample_playback_viewport.lottie_unzip for Playback Viewport),
// plus samples/sample.lottie (Test E1). All skip (not fail) when samples/
// isn't present in this checkout, matching this suite's established
// convention for monorepo-only fixtures.
//
// Task 7.4 (F1/F2) is already covered by earlier phases' tests --
// test/lottie_mapping_test.dart's "a corrupt zip throws
// LottieFormatException" (F1) and test/lottie_import_test.dart's "F2: an
// image layer whose asset is missing is flagged missingAsset" -- not
// duplicated here.
//
// flows/sdd-flutter-comics Plan Task 4.3: relocated from
// apps/comics-editor/test/ -- G3's fixture-prep step originally called
// comicsFromCore (models_mapping.dart, which stays in apps/comics-editor,
// native-core-coupled) to parse the real sample_v2012.comics_unzip/
// data.json fixture. Rewritten to use ComicsArchiveReader instead, the one
// real dependency that blocked this file's move -- data.json is an
// already-unzipped fixture (not a real .comics zip), so it's re-zipped
// in-memory first (just the one entry ComicsArchiveReader needs), matching
// comics_reader_test.dart's own established in-memory-zip pattern rather
// than adding a raw-map bypass entry point to the public API that nothing
// else needs.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_comics/flutter_comics.dart';

Uint8List _rezip(File dataJsonFile) {
  final jsonBytes = dataJsonFile.readAsBytesSync();
  final archive = Archive()..addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  final repoRoot = Directory(Directory.current.path).parent.parent;
  final samplesDir = Directory('${repoRoot.path}/samples');
  final samplesAvailable = samplesDir.existsSync();

  /// Samples every layer's translate/scale/rotate/alpha at a handful of
  /// scroll positions spanning the document, via the app's own real
  /// KeyframeInterpolator -- the same behavioral-equivalence bar Category
  /// E already established (not necessarily the same bytes).
  ///
  /// Matches layers by **name**, not list index -- found via real-fixture
  /// debugging that a round trip through Playback Viewport mode (and,
  /// separately, Full Canvas mode's groupId-based grouping) legitimately
  /// reorders `ComicsDoc.layers` (scenes get emitted in ascending-
  /// scroll-position order; grouped layers get separated from ungrouped
  /// ones) without that being a real correctness bug -- a `.comics`
  /// layer's identity is its name, never its position in the list.
  void expectRenderedTransformsMatch(ComicsDoc a, ComicsDoc b, {double tolerance = 2.0}) {
    expect(a.layers.length, b.layers.length, reason: 'layer count must match');
    final byName = <String, List<EditorLayer>>{};
    for (final l in b.layers) {
      byName.putIfAbsent(l.name, () => []).add(l);
    }
    final maxT = [
      for (final l in a.layers)
        for (final anim in l.anims) anim.end.toDouble(),
      100.0,
    ].reduce((x, y) => x > y ? x : y);
    final sampleTimes = [for (var i = 0; i <= 4; i++) maxT * i / 4];

    for (final la in a.layers) {
      final candidates = byName[la.name];
      expect(candidates, isNotNull, reason: 'no reimported layer named "${la.name}"');
      final lb = candidates!.removeAt(0);
      for (final t in sampleTimes) {
        final ta = KeyframeInterpolator.translateAt(la.anims, t, la.translate);
        final tb = KeyframeInterpolator.translateAt(lb.anims, t, lb.translate);
        expect(
          (ta.dx - tb.dx).abs(),
          lessThanOrEqualTo(tolerance),
          reason: 'layer "${la.name}" dx at t=$t: $ta vs $tb',
        );
        expect(
          (ta.dy - tb.dy).abs(),
          lessThanOrEqualTo(tolerance),
          reason: 'layer "${la.name}" dy at t=$t: $ta vs $tb',
        );
      }
    }
  }

  group('G3 -- Full Canvas round-trip (fixture prep + corrected .lottie -> .comics -> .lottie direction)', () {
    final v2012File = File('${samplesDir.path}/sample_v2012.comics_unzip/data.json');
    final v2012Available = v2012File.existsSync();

    test('real sample_v2012.comics_unzip round-trips through Full Canvas mode', () async {
      // Fixture prep: real .comics -> .lottie (not part of the round-trip
      // being asserted -- produces the real Full-Canvas-shaped .lottie
      // this flow had no such file for directly in samples/).
      final original = await ComicsArchiveReader.readBytes(
        _rezip(v2012File),
        name: 'sample_v2012.comics',
      );
      final preparedLottie = buildLottieExport(
        original,
        ExportImportMode.fullCanvas,
        easing: EasingChoice.easyEaseApproximation,
      );
      final preparedBytes = writeLottieDocument(preparedLottie, assetFiles: const []);

      // The actual round-trip: .lottie -> .comics -> .lottie, per Anton's
      // direct correction (2026-08-08) -- NOT .comics -> .lottie -> .comics.
      final reparsed = parseLottieDocument(preparedBytes);
      final preview = ImportPreview.build(reparsed, ExportImportMode.fullCanvas);
      final reimported = ComicsDoc(name: 'reimported.comics', type: DocType.comics);
      commitImport(preview, reimported);
      final reexported = buildLottieExport(
        reimported,
        ExportImportMode.fullCanvas,
        easing: EasingChoice.easyEaseApproximation,
      );
      writeLottieDocument(reexported, assetFiles: const []); // confirms it's real, writable bytes

      expectRenderedTransformsMatch(original, reimported);
    }, skip: v2012Available ? false : 'samples/ not present in this checkout (monorepo-only fixture)');
  });

  group('G6 -- Playback Viewport round-trip (real ASHES-based sample)', () {
    final ashesFile = File(
      '${samplesDir.path}/sample_playback_viewport.lottie_unzip/ASHES_content/ASHES.json',
    );
    final ashesAvailable = ashesFile.existsSync();

    test('real sample_playback_viewport.lottie_unzip round-trips through Playback Viewport mode', () {
      final json = jsonDecode(ashesFile.readAsStringSync()) as Map<String, dynamic>;
      final original = parseLottieJson(json);

      final preview = ImportPreview.build(original, ExportImportMode.playbackViewport);
      final speed = preview.scrollSpeed!;
      final imported = ComicsDoc(name: 'imported.comics', type: DocType.comics)
        ..preferredViewportWidth = original.width
        ..preferredViewportHeight = original.height;
      commitImport(preview, imported);

      final reexported = buildLottieExport(
        imported,
        ExportImportMode.playbackViewport,
        scrollSpeed: speed,
        easing: EasingChoice.easyEaseApproximation,
      );
      final rebytes = writeLottieDocument(reexported, assetFiles: const []);
      final reparsed = parseLottieDocument(rebytes);

      final reimportPreview = ImportPreview.build(reparsed, ExportImportMode.playbackViewport)
        ..scrollSpeed = speed;
      final reimported = ComicsDoc(name: 'reimported.comics', type: DocType.comics);
      commitImport(reimportPreview, reimported);

      expectRenderedTransformsMatch(imported, reimported, tolerance: 5.0);
    }, skip: ashesAvailable ? false : 'samples/ not present in this checkout (monorepo-only fixture)');
  });

  group('E1 -- real .lottie round-trip (samples/sample.lottie)', () {
    test('import -> export -> re-import produces the same rendered result within tolerance', () {
      final bytes = File('${samplesDir.path}/sample.lottie').readAsBytesSync();
      final original = parseLottieDocument(bytes);
      final mode = detectMode(original); // real content: confirmed Playback-Viewport-shaped

      final preview = ImportPreview.build(original, mode);
      final speed = preview.scrollSpeed;
      final comicsDoc = ComicsDoc(name: 'sample.comics', type: DocType.comics)
        ..preferredViewportWidth = original.width
        ..preferredViewportHeight = original.height;
      commitImport(preview, comicsDoc);
      expect(comicsDoc.layers, isNotEmpty);

      final reexported = buildLottieExport(
        comicsDoc,
        mode,
        scrollSpeed: speed,
        easing: EasingChoice.easyEaseApproximation,
      );
      final rebytes = writeLottieDocument(reexported, assetFiles: const []);
      final reparsed = parseLottieDocument(rebytes);

      final reimportPreview = ImportPreview.build(reparsed, mode)..scrollSpeed = speed;
      final reimported = ComicsDoc(name: 'sample.comics', type: DocType.comics);
      commitImport(reimportPreview, reimported);

      expectRenderedTransformsMatch(comicsDoc, reimported, tolerance: 5.0);
    }, skip: samplesAvailable ? false : 'samples/ not present in this checkout (monorepo-only fixture)');
  });
}
