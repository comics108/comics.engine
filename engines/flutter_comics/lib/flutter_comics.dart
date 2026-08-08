/// Shared `.comics`/`.puzzle` data model, keyframe interpolation, and
/// `.lottie` import/export -- relocated from `apps/comics-editor` (per
/// `flows/sdd-flutter-comics`), portable, no native-core/FFI dependency.
library;

export 'src/models.dart';
export 'src/keyframe_interpolator.dart';
export 'src/lottie/lottie_mapping.dart';
export 'src/lottie/lottie_import.dart';
export 'src/lottie/lottie_export.dart';
export 'src/comics_reader.dart';
