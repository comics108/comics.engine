# comics.engine

Набор движков для **рендеринга интерактивных архивов `.comics`** (скролл‑управляемые анимации слоёв, опциональный звук, локализация контента) в разных рантаймах:

- **Flutter**: плагин `flutter_comics` (Android/iOS/macOS/Windows/Linux/Web).
- **Web**: vanilla JS viewer (демо через `serve`).
- **Unity**: пакет для Unity 2021.3+ с sample-сценой.

## Что такое `.comics`

На практике `.comics` — это ZIP‑архив, из которого движки читают как минимум:

- **`data.json`**: описание холста (width/height), слоёв, анимаций и звуков.
- **тайлы/ресурсы**: изображения слоёв, аудио и т.п. (пути зависят от конкретного архива).

Web‑движок ожидает `data.json` внутри архива и падает с ошибкой, если его нет.

## Структура репозитория

- `engines/flutter_comics.engine/` — Flutter plugin `flutter_comics` + `example/`.
- `engines/web_comics.engine/` — web viewer (HTML + JS + CSS) + `samples/`.
- `engines/unity_comics.engine/` — Unity package (Runtime + `Samples~/BasicViewer`).
- `sample/` — пример `.comics` (большой архив для ручных тестов).
- `legacy/` — старые/исторические реализации (не основной путь).

## Быстрый старт

### Web viewer (самый быстрый способ “посмотреть”)

```bash
cd engines/web_comics.engine
npm install
npm run dev
```

Демо по умолчанию открывает `index.html` и пытается загрузить архив:

- `engines/web_comics.engine/samples/test-comics.comics`

Чтобы проверить свой файл — замените путь `archiveUrl` в `index.html` или положите свой архив в `samples/`.

### Flutter plugin (пример приложения)

```bash
cd engines/flutter_comics.engine
flutter pub get

cd example
flutter pub get
flutter run
```

Минимальные требования указаны в `pubspec.yaml` плагина:

- Dart SDK: `^3.11.5`
- Flutter: `>=3.3.0`

### Unity package

Пакет лежит в `engines/unity_comics.engine/` и рассчитан на **Unity 2021.3** (см. `package.json`).

Один из удобных вариантов подключить локально:

- В Unity: **Window → Package Manager → + → Add package from disk…**
- Выберите файл `engines/unity_comics.engine/package.json`

Демо‑материалы:

- Sample: `Samples~/BasicViewer`
- Пример архива: `Samples~/BasicViewer/Resources/test-comics.comics`

## Возможности

- **Слои**: композиция из множества слоёв с позиционированием.
- **Анимации от скролла**: `translate`, `rotate`, `scale`, `alpha` (Unity — по парсеру `ComicsParser`, web — через `AnimationProcessor`).
- **Тайловый рендеринг**: подгрузка видимой области (web/unity).
- **Звук**: привязка воспроизведения к позиции скролла (web/unity).
- **Локализация**: переключение `languageIndex` (web/unity + Flutter API на стороне движка).

## Полезные файлы

- `engines/web_comics.engine/src/comics-viewer.js` — основной entrypoint web viewer.
- `engines/unity_comics.engine/Runtime/ComicsViewer.cs` — главный компонент Unity.
- `engines/flutter_comics.engine/lib/flutter_comics.dart` — публичный API Flutter‑пакета.

## Лицензия

Смотрите лицензии в подпроектах:

- Flutter: `engines/flutter_comics.engine/LICENSE` (сейчас файл‑заглушка, требует заполнения)
- Web: `engines/web_comics.engine/package.json` (указано `MIT`)
- Unity: `engines/unity_comics.engine/package.json` (указаны ссылки на лицензии/доки)
