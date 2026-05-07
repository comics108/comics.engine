# Status: sdd-render-engine-native

## Current Phase

SPLIT (deprecated)

## Phase Status

ARCHIVED — спецификации разделены на платформенные документы

## Last Updated

2026-05-08 by Claude

## Blockers

- None

## Progress

- [x] Requirements drafted
- [x] Specifications drafted
- [x] **SPLIT** → платформенные спецификации:
  - Android: `../sdd-comics-engine-flutter-android/specifications-ru.md`
  - iOS: `../sdd-comics-engine-flutter-ios/specifications-ru.md`
- [x] Implementation started (Dart API created)
- [ ] Implementation complete

## Context Notes

**Этот SDD устарел.** Спецификации были разделены на платформенные документы:

| Платформа | Новый документ |
|-----------|----------------|
| Android | `sdd-comics-engine-flutter-android/` |
| iOS | `sdd-comics-engine-flutter-ios/` |
| Web | `sdd-comics-engine-flutter-web/` |
| Unity | `sdd-comics-engine-csharp-unity/` |
| Формат `.comics` | `sdd-comics-format/` |

Оригинальные файлы в этой директории сохранены для истории, но ссылаться следует на платформенные документы.

## Legacy Context

- Extracted legacy render behavior from:
  - `legacy/legacy-bhagavadgita-render-engine-web-css/`
  - `legacy/legacy-mahabharata-render-engine-android-java/`
  - `legacy/legacy-mahabharata-render-engine-ios-swift/`
- Key shared invariant: tile size = 512, tile filename template `{0}_{1}_{2}`

## Dart API Created (in flutter_comics)

- `lib/flutter_comics.dart`
- `lib/src/models.dart`
- `lib/src/comics_viewer.dart`
- `lib/src/comics_viewer_controller.dart`

## Next Actions

1. ~~Review and approve specifications~~ → См. платформенные документы
2. Продолжить реализацию Android/iOS нативных частей
