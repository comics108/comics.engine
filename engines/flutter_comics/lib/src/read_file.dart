import 'dart:typed_data';

import 'read_file_stub.dart' if (dart.library.io) 'read_file_io.dart' as implementation;

/// Web-safe conditional-import shim, mirroring `flutter_comics_viewer`'s own
/// `source_bytes.dart`/`source_bytes_io.dart`/`source_bytes_stub.dart`
/// pattern exactly -- `dart:io` isn't available on Web, so
/// [ComicsArchiveReader.readFile] (a real filesystem convenience, per
/// Specifications) needs this indirection to stay usable from this
/// otherwise-portable library on every platform.
Future<Uint8List> readFileBytes(String path) => implementation.readFileBytes(path);
