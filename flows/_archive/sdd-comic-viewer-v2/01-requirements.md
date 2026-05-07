# Requirements: Comic Viewer Cross-Platform Component

> Version: 1.0
> Status: APPROVED
> Last Updated: 2025-12-31

## Problem Statement

Нужен кроссплатформенный компонент для отображения интерактивных комиксов с анимациями, синхронизированным звуком и многоязычной поддержкой. Сейчас существуют две legacy-реализации:
- **Android** (Java): ZoomFrameLayout + LayersView + TileImageView
- **iOS** (Swift): ImageScrollView + TileImageView + CATiledLayer

Обе реализации имеют схожую архитектуру и функциональность, но дублируют логику и требуют параллельной поддержки. Необходимо создать единый **Flutter-based компонент**, который:

1. **Обратно совместим** с legacy форматом данных (v1)
2. **Поддерживает новый формат v2** с расширенными возможностями:
   - Z-depth для 3D-позиционирования слоев
   - Поддержка купольных кинотеатров и VR
   - Интеграция с After Effects (экспорт анимаций)
   - Автоматическая отрисовка мультиязычных речевых баллонов
3. **Расширяет функциональность**, а не упрощает legacy-версии

## Legacy Feature Analysis

### Общие возможности обеих реализаций:

**Формат данных:**
- ZIP-архивы с `data.json` (метаданные) + PNG-изображения
- Comics модель: width, height, layers[], sounds[]
- Layer модель: images[] (по языку), animations[]
- Animation типы: TranslateAnim, RotateAnim, ScaleAnim, AlphaAnim
- Sound модель: file, animations[] (point/range triggers)

**Рендеринг:**
- Тайловая система (512px tiles) для больших изображений
- Многослойная композиция (LayersView/множественные TileImageView)
- Динамическая загрузка только видимых тайлов
- Матричные трансформации (translate, rotate, scale) на каждом слое

**Анимация:**
- Scroll-offset-driven анимации (синхронизация со скроллом)
- Кубическая интерполяция между ключевыми кадрами
- Одновременные анимации на одном слое
- Плавные переходы с easing

**Звук:**
- Point sounds (триггер в конкретной точке скролла)
- Range sounds (loop между start-end позициями скролла)
- Fade-in/fade-out (600ms Android, 0.6s iOS)
- Управление состоянием звука (on/off toggle)

**Мультиязычность:**
- Поддержка нескольких языков (русский, английский, хинди)
- Переключение без полной перезагрузки (smart reload)
- Язык-специфичные изображения на слоях

**Навигация:**
- Вертикальный скролл с momentum
- Pinch-to-zoom (Android), фиксированный zoom (iOS fit-to-width)
- Сохранение позиции чтения (resume from last position)
- Тап для toggle звука

**UI панели:**
- Верхняя панель: episode info, language selector
- Нижняя панель: next episode teaser, purchase button
- Анимация hide/show при скролле

## User Stories

### Primary

**Как пользователь приложения Махабхарата**
**Я хочу** просматривать интерактивные комиксы с анимациями и звуком
**Чтобы** получать иммерсивный опыт чтения визуального контента

**Как разработчик**
**Я хочу** единый кроссплатформенный компонент
**Чтобы** избежать дублирования кода и упростить поддержку

### Secondary

**Как пользователь**
**Я хочу** переключать язык контента на лету
**Чтобы** читать на удобном мне языке без перезагрузки

**Как пользователь**
**Я хочу** продолжить чтение с места, где остановился
**Чтобы** не терять прогресс между сессиями

**Как пользователь**
**Я хочу** контролировать воспроизведение звука
**Чтобы** читать в тишине, когда нужно

### New Features (V2 Format)

**Как контент-креатор**
**Я хочу** экспортировать анимации из After Effects
**Чтобы** не создавать их вручную в JSON

**Как контент-креатор**
**Я хочу** задать z-depth для слоев
**Чтобы** создавать 3D-эффект глубины для купольных кинотеатров и VR

**Как контент-креатор**
**Я хочу** автоматически генерировать речевые баллоны на разных языках
**Чтобы** не создавать отдельные изображения для каждого языка

**Как пользователь VR/dome**
**Я хочу** видеть слои на разной глубине
**Чтобы** получить объемный 3D-эффект

## Acceptance Criteria

### Must Have (V1 Legacy Compatibility)

1. **Given** ZIP-архив эпизода с legacy-форматом data.json (v1)
   **When** компонент загружает и отображает комикс
   **Then** все слои корректно рендерятся с тайловой системой (обратная совместимость)

2. **Given** комикс с scroll-based анимациями (translate, rotate, scale, alpha)
   **When** пользователь скроллит контент
   **Then** анимации воспроизводятся синхронно с позицией скролла с кубической интерполяцией

3. **Given** комикс со звуковыми анимациями
   **When** пользователь скроллит через триггерные точки
   **Then** звуки воспроизводятся (point) или зацикливаются (range) корректно с fade-эффектами

4. **Given** многоязычный контент
   **When** пользователь переключает язык
   **Then** слои обновляются без полной перезагрузки и потери позиции

5. **Given** большие изображения (например, 2048x8000px)
   **When** компонент рендерит контент на Flutter
   **Then** используется эффективная система загрузки (тайлы или альтернатива) с минимальным memory footprint

### Must Have (V2 New Format)

6. **Given** ZIP-архив с форматом v2 (с z-depth в data.json)
   **When** компонент загружает комикс
   **Then** слои рендерятся на разной глубине для 3D-эффекта

7. **Given** комикс с речевыми баллонами в формате v2
   **When** пользователь переключает язык
   **Then** текст в баллонах автоматически обновляется без смены изображения

8. **Given** After Effects композиция экспортирована в формат v2
   **When** компонент загружает анимации
   **Then** все keyframes, easing, и эффекты корректно воспроизводятся

### Should Have

9. **Given** пользователь читает эпизод
   **When** он покидает экран и возвращается
   **Then** позиция скролла сохраняется и восстанавливается

10. **Given** звук воспроизводится
    **When** пользователь тапает по экрану
    **Then** звук включается/выключается с визуальной индикацией

11. **Given** комикс отображается
    **When** пользователь скроллит вверх/вниз
    **Then** верхняя/нижняя панели анимированно скрываются/показываются

12. **Given** формат v2 с z-depth
    **When** контент отображается в VR/dome режиме
    **Then** слои позиционируются в 3D-пространстве согласно z-depth значениям

### Won't Have (This Iteration)

- Pinch-to-zoom для мобильных устройств (будет фиксированный fit-to-width)
- Horizontal scrolling (только вертикальный скролл)
- Interactive popups/hotspots (отложено)
- Analytics integration (добавим позже)
- Preview layers (отложено)
- Полноценный After Effects plugin для экспорта (пока ручная конвертация/скрипт)
- Автоматический перевод текста баллонов (только подстановка готовых переводов)

## Constraints

- **Technical**:
  - **Flutter** как основная платформа разработки
  - Полная обратная совместимость с legacy форматом данных v1 (ZIP + data.json)
  - Поддержка нового формата v2 с расширениями (z-depth, speech bubbles, AE integration)
  - Работа на Android и iOS (mobile), потенциально VR/dome platforms

- **Performance**:
  - Плавный скролл (60fps) даже с большим количеством слоев
  - Минимальное потребление памяти (эффективная загрузка изображений)
  - Асинхронная загрузка изображений без блокировки UI
  - Для v2: рендеринг 3D-трансформаций без деградации производительности

- **Platform**:
  - Android 8.0+ (API 26+)
  - iOS 13+
  - Flutter 3.x (stable channel)
  - Потенциально: Quest/VR platforms (будущая итерация)

- **Dependencies**:
  - Flutter package для ZIP-архивов (archive, flutter_archive)
  - Flutter audio playback (audioplayers, just_audio)
  - Custom rendering для 3D z-depth (Canvas/CustomPainter с perspective transform)
  - Формат v2: After Effects export ExtendScript (отдельный инструмент)
  - Storage management: path_provider, sqflite (для кэша метаданных)
  - Download manager: dio или http с progress tracking

## Open Questions

- [x] **Какую технологию использовать?** → **Flutter**
- [x] **Совместимость с legacy форматом?** → **Да, полная обратная совместимость v1 + новый формат v2**
- [x] **Упрощать анимации?** → **Нет, расширять функциональность (After Effects, z-depth, речевые баллоны)**
- [x] **Zoom levels?** → **Fit-to-width (как iOS) для мобильных, возможно расширение для VR/dome**
- [x] **Хранение ZIP-архивов** → **Гибридный подход (download + cache)**: скачивание эпизодов, локальное хранение с возможностью управления кэшем
- [x] **V2 формат - структура data.json** → **Расширенный data.json с полем "version": 2**, добавить поля:
  - `layer.zDepth` (число для 3D-глубины)
  - `layer.type` ("image" | "speechBubble")
  - `layer.bubble` (для speechBubble: text {lang}, textStyle, backgroundImage, position)
- [x] **After Effects экспорт** → **Кастомный ExtendScript** для экспорта keyframes, transforms, easing в формат v2 JSON
- [x] **Речевые баллоны** → **Часть layer-системы** с type="speechBubble", текст в data.json как `{ru: "...", en: "...", hi: "..."}`, рендеринг text overlay поверх backgroundImage
- [x] **3D рендеринг для z-depth** → Отложено на фазу спецификаций (рассмотреть flutter_gl, custom shader, или Canvas с perspective transform)
- [x] **Приоритет v1 vs v2** → **Поддержка обоих с самого начала**, v1 как legacy/fallback формат
- [ ] **Размер bundle/APK/IPA**: Есть ли ограничения? (можно уточнить позже)
- [ ] **RTL-языки**: Нужна ли поддержка (арабский, иврит)? (можно добавить после v1/v2)
- [x] **Целевая версия Flutter** → **Flutter 3.24+ (latest stable)**

## References

- Legacy Android: `legacy-mahabharata-android/app/src/main/java/com/fulldome/mahabharata/`
- Legacy iOS: `legacy-mahabharata-ios/Mahabharata/`
- Analysis documents from exploration agents (af6fc7d, ad82c83)

---

## Design Decisions Summary

### ✅ Ключевые решения:
1. **Tech Stack**: Flutter 3.24+
2. **Storage**: Гибридный (download + cache с управлением)
3. **Format**:
   - V1 legacy (обратная совместимость)
   - V2 extended (version: 2, zDepth, speechBubble layers)
4. **After Effects**: Кастомный ExtendScript экспорт
5. **Speech Bubbles**: Layer с type="speechBubble", мультиязычный text в JSON, text overlay рендеринг
6. **Development**: Поддержка v1 и v2 одновременно с самого начала

### 📋 V2 Data Format Sketch:
```json
{
  "version": 2,
  "width": 2048,
  "height": 8000,
  "layers": [
    {
      "id": "bg",
      "type": "image",
      "file": "layers/bg.png",
      "zDepth": 0,
      "animations": [...]
    },
    {
      "id": "bubble-1",
      "type": "speechBubble",
      "zDepth": 100,
      "bubble": {
        "backgroundImage": "layers/bubble.png",
        "text": {"ru": "Привет!", "en": "Hello!", "hi": "नमस्ते!"},
        "textStyle": {"font": "Roboto", "size": 24, "color": "#000"},
        "position": {"x": 500, "y": 1200},
        "width": 400
      },
      "animations": [...]
    }
  ],
  "sounds": [...]
}
```

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2025-12-31
- [x] Notes: All key decisions finalized, ready for SPECIFICATIONS phase
