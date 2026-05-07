# Спецификации: Comics Engine — Flutter / Android (нативный рендер, тайлинг + слои)

> Версия: 1.0  
> Статус: DRAFT  
> Последнее обновление: 2026-05-08  
> Источник: извлечено из legacy-спеки `flows/sdd-render-engine-native/03-specifications-ru.md` и адаптировано под Android
>
> Формат `.comics` (ZIP + `data.json`) — см. `../sdd-comics-format/02-specifications-ru.md`

---

## Обзор

Данная спецификация описывает Android-реализацию рендер-движка для Flutter-плагина `flutter_comics`, который обеспечивает:

- Тайловый рендеринг очень больших изображений (512×512)
- Послойную композицию с трансформациями (translate/rotate/scale) и alpha
- Scroll-driven анимации слоёв
- Viewport-aware загрузку/выгрузку тайлов + LRU кэш
- Hit-testing по альфа-каналу

---

## 1. Инварианты (нельзя менять)

| Параметр | Значение |
|----------|----------|
| TILE_SIZE | 512 px |
| Tile naming | `{0}_{1}_{2}` |
| `{0}` | `Int(zoom * 1000)` (например, 1.0 → 1000) |
| Порядок трансформаций | Scale → Rotate → Translate |
| Сглаживание | \( (f-1)^3 + 1 \) |
| Выгрузка | Выгружать bitmap-данные, **не удаляя view** (иначе артефакты) |

---

## 2. Архитектура (Android)

### 2.1. Контейнер зума/пана

Android-контейнер отвечает за:

- FitMode (vertical/horizontal) и `minScale`
- Жесты зума/пана
- Текущий scroll offset (X/Y) и “расширенные” границы для preload

Рекомендуемые обязанности:

- `ComicsContainerView` (на базе legacy `ZoomFrameLayout`) — контролирует scale/scroll и сообщает дочерним `ZoomableView` об обновлениях.

### 2.2. Хост слоёв и тайловые view

- `LayersView` (host) содержит по одному `TileImageView` на слой.
- `TileImageView` отвечает за:
  - определение tileMode (`file.contains("{0}")`)
  - выбор zoom level
  - вычисление видимых тайлов
  - запрос/кеширование bitmap
  - отрисовку тайлов в `Canvas`
  - hit-test по альфа-каналу

---

## 3. Модель данных (портируемая)

### 3.1. Scene (Comics)

| Поле | Тип | Описание |
|------|-----|----------|
| `width` | Int | Логическая ширина контента |
| `height` | Int | Логическая высота контента |
| `layers` | Layer[] | Слои, back-to-front |
| `sounds` | Sound[] | (опционально) звуки, привязанные к offset |

### 3.2. Layer

| Поле | Тип | Описание |
|------|-----|----------|
| `preview` | Bool? | preview слой |
| `images` | Image[] | изображения по языкам |
| `animations` | LayerAnim[] | сегменты анимаций |

Выбор изображения по языку:

1. Берётся `images[languageIndex]`
2. Если пусто — fallback на первое непустое

### 3.3. Image

| Поле | Тип | Описание |
|------|-----|----------|
| `width` | Int | Ширина |
| `height` | Int | Высота |
| `file` | String? | файл/шаблон тайлов (`layers/{0}_{1}_{2}.png`) |
| `popup` | String? | popup (long-press) |

tileMode:

```
tileMode = file.contains("{0}")
```

---

## 4. Анимации (Android-математика и порядок)

### 4.1. Fraction

```
scrollObject = scrollOffset - endAnim.start
animHeight = endAnim.end - endAnim.start
fraction = animHeight == 0 ? 1 : clamp(scrollObject / animHeight, 0, 1)
```

### 4.2. Cubic ease-out

```
transformToCubic(fraction) = (fraction - 1)³ + 1
```

### 4.3. Порядок применения

1. Scale
2. Rotate
3. Translate
4. Alpha (отдельно от матрицы)

---

## 5. Тайловый рендеринг (Android)

### 5.1. Zoom levels

Дискретные уровни (legacy):

- `ZOOM_LEVELS = [1.0, 0.5, 0.25, 0.125]`

Выбор:

```
if (!tileMode) return NO_TILES;
if (!zoomEnabled) return ZOOM_LEVELS[0];

for level in ZOOM_LEVELS:
  if (scale >= min(level, 0.8)) return level
return last(ZOOM_LEVELS)
```

### 5.2. Формат имени тайла

```
template.replace("{0}", zoom * 1000)
        .replace("{1}", column)
        .replace("{2}", row)
```

Пример:

- `layers/background_{0}_{1}_{2}.png`
- zoom=1.0, col=2, row=3 → `layers/background_1000_2_3.png`

### 5.3. Placeholder

Если хотя бы один видимый тайл отсутствует в кэше:

```
placeholderFileName = template
  .replace("{0}", "ph")
  .replace("{1}", "0")
  .replace("{2}", "0")
```

### 5.4. Вычисление тайлов (сетка)

Вычисление множества тайлов для `zoomLevel` (legacy-алгоритм):

```
realWidth  = contentWidth  * zoomLevel
realHeight = contentHeight * zoomLevel

for i in 0..realWidth step TILE_SIZE:
  for j in 0..realHeight step TILE_SIZE:
    tiles.add(Tile(col, row, zoomLevel))
```

Rect тайла в координатах контента:

```
rectX = column * TILE_SIZE / zoomLevel
rectY = row    * TILE_SIZE / zoomLevel
rectW = min(TILE_SIZE, contentWidth  * zoomLevel - TILE_SIZE * column) / zoomLevel
rectH = min(TILE_SIZE, contentHeight * zoomLevel - TILE_SIZE * row)    / zoomLevel
```

---

## 6. Viewport, память, кэш (Android)

### 6.1. Принцип

- Тайлы грузятся только для видимой области + margin
- При выходе слоя из viewport — тайлы выгружаются, view остаётся

### 6.2. Кэширование

Ключ кэша (legacy):

```
key = descriptorName + "_" + fileName
```

Требование для плагина:

- ключ \( (contentId, fileName) \) или эквивалент, чтобы исключить коллизии между разными архивами/сценами
- LRU eviction при давлении памяти
- дедупликация запросов по ключу

---

## 7. Hit-testing (Android)

Принцип:

1. Проверить bounds view
2. Найти тайл под точкой
3. Получить bitmap из кэша
4. Преобразовать координаты в локальные
5. Проверить alpha > 0

---

## 8. Интерфейс Flutter ↔ Android Native

### 8.1. Решение по контенту

- Flutter передаёт путь к `.comics` архиву
- Native распаковывает ZIP и парсит `data.json`
- Native подгружает тайлы из `layers/` по мере необходимости

### 8.2. Каналы

- Method channel: `flutter_comics`
- Event channel: `flutter_comics/events`
- Platform view: `flutter_comics_view`

Методы/события должны быть совместимы с общей спецификацией API (см. iOS/Web/Unity документы для тех же контрактов).

---

## Утверждение

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [conditions/clarifications]

