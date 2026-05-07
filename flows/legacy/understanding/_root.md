# Understanding: Рендер-движок комиксов (Legacy Analysis)

> Entry point for recursive understanding. Extracted from three legacy codebases.

## Project Overview

Анализ трёх legacy-реализаций рендер-движка комиксов для построения единого Flutter-плагина `flutter_comics`:

1. **legacy-bhagavadgita-render-engine-web-css** — Web/CreateJS экспорт из Adobe Animate
2. **legacy-mahabharata-render-engine-android-java** — Android-приложение на Java
3. **legacy-mahabharata-render-engine-ios-swift** — iOS-приложение на Swift

## Identified Domains

| Domain | Hypothesis | Priority | Status |
|--------|------------|----------|--------|
| render-engine | Ядро рендеринга: тайлы, слои, трансформации | HIGH | DONE |
| animation-system | Scroll-driven анимации с интерполяцией | HIGH | DONE |
| tile-management | Загрузка/выгрузка тайлов, кэширование | HIGH | DONE |
| zoom-pan-container | Контейнер zoom/pan с матричными трансформациями | MEDIUM | DONE |
| sound-system | Scroll-triggered звуки (point + range) | MEDIUM | DONE |
| hit-testing | Alpha-based hit detection для интерактивности | MEDIUM | DONE |
| data-model | Comics, Layer, Image, Animation structures | HIGH | DONE |

## Source Mapping

| Source Path | -> Domain |
|-------------|----------|
| `legacy-android/.../TileImageView.java` | render-engine, tile-management |
| `legacy-android/.../ZoomFrameLayout.java` | zoom-pan-container |
| `legacy-android/.../Layer.java` | data-model, animation-system |
| `legacy-android/.../Comics.java` | data-model |
| `legacy-android/.../visual/animation/*.java` | animation-system |
| `legacy-ios/.../TileImageView.swift` | render-engine, tile-management |
| `legacy-ios/.../ImageScrollView.swift` | zoom-pan-container, sound-system |
| `legacy-ios/.../Layer.swift` | data-model, animation-system |
| `legacy-ios/.../Comics.swift` | data-model |
| `legacy-ios/.../Animations/*.swift` | animation-system |
| `legacy-web/Anim1_HTML5 Canvas.js` | reference (web-rendering, sprite-sheets) |

## Cross-Cutting Concerns

### 1. Tile Naming Convention (ADR candidate)
- Все три реализации используют шаблон `{0}{1}{2}`
- `{0}` = zoom * 1000, `{1}` = column, `{2}` = row
- **Решение**: Сохранить для обратной совместимости

### 2. Tile Size (ADR candidate)
- Фиксированный размер 512x512 px
- **Решение**: Не менять, это влияет на все архивы контента

### 3. Animation Application Order (ADR candidate)
- Порядок: Scale → Rotate → Translate
- Критично для визуального соответствия
- **Решение**: Документировать и строго соблюдать

### 4. Cubic Easing Function (ADR candidate)
- Формула: `(fraction - 1)³ + 1`
- Используется в обеих нативных реализациях
- **Решение**: Портировать как есть

## Children Spawned

```
render-engine/
├── tiling/          # Tile rendering, CATiledLayer/Canvas
├── layers/          # Layer composition, transforms
└── viewport/        # Visible rect management, memory

animation-system/
├── interpolation/   # Cubic easing, fraction calculation
├── transforms/      # Translate, Rotate, Scale, Alpha
└── sound-triggers/  # Point sounds, Range loops

data-model/
├── comics/          # Root scene structure
├── layer/           # Layer with images and animations
└── image/           # Image metadata, popup reference
```

## Synthesis

### Ключевые выводы из анализа:

**1. Архитектурная идентичность**
Android и iOS реализации практически идентичны по архитектуре:
- Оба используют `Comics.process(scrollOffset)` для обновления состояния
- Оба используют `Layer.buildMatrixAndAlpha(scrollOffset)` для вычисления трансформаций
- Одинаковый формат данных JSON (Comics, Layer, Image, Animation)

**2. Различия в реализации**
- **Android**: View + Canvas, ручное управление тайлами, LRU bitmap cache
- **iOS**: CATiledLayer, автоматическая отрисовка, dictionary-based tile storage

**3. Web-экспорт как reference**
- CreateJS/Adobe Animate экспорт показывает timeline-based анимации
- Может служить reference для проверки визуального соответствия
- Не требует 1:1 портирования (разные парадигмы)

**4. Рекомендации для Flutter-плагина**
- Использовать Platform Views для нативного рендеринга
- Android: адаптировать `TileImageView` + `ZoomFrameLayout`
- iOS: адаптировать `TileImageView` + `ImageScrollView`
- Общий Dart API для передачи scene descriptor

## Flow Mapping

| Node | Flow Type | Flow Name | Status |
|------|-----------|-----------|--------|
| render-engine | SDD | sdd-render-engine-native | EXISTS (extended) |
| animation-system | SDD | sdd-render-engine-native | EXISTS (included) |
| data-model | SDD | sdd-render-engine-native | EXISTS (included) |

---

*Created by /legacy ENTERING phase*
*Updated: 2026-05-07*
