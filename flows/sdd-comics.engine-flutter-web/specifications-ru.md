# Спецификации: Comics Engine — Flutter Web / Web (JS+CSS, тайлинг + слои)

> Версия: 1.0  
> Статус: DRAFT  
> Последнее обновление: 2026-05-08  
> Источник: извлечено из `flows/sdd-render-csharp-and-web-css/specifications.md` (+ web reference из legacy-части `flows/sdd-render-engine-native/03-specifications-ru.md`)
>
> Формат `.comics` (ZIP + `data.json`) — см. `../sdd-comics-format/02-specifications-ru.md`

---

## Обзор

Веб-движок отображает `.comics` архивы в браузере, сохраняя ключевые инварианты анимаций/тайлинга:

- Scroll-driven анимации слоёв (как в native)
- Тайловый рендеринг 512×512
- Минимальный JS + упор на CSS/DOM
- Распаковка ZIP на клиенте (например, `fflate`)

---

## 1. Инварианты (нельзя менять)

| Параметр | Значение |
|----------|----------|
| TILE_SIZE | 512 px |
| Tile naming | `{0}_{1}_{2}` |
| `{0}` | `Int(zoom * 1000)` |
| Порядок трансформаций | Scale → Rotate → Translate |
| Сглаживание | \( (f-1)^3 + 1 \) |

---

## 2. Архитектура Web

```
<div class="comics-viewer">   // overflow-y: scroll
  <div class="comics-content">  // height по comics.height * scale
    <div class="comics-layer">  // absolute, transform/opacity на scroll
      <div class="comics-tile"> // tiles (background-image из ZIP)
```

Основные части:

- `comics-engine.js` — парсинг `data.json`, подготовка анимаций, обработка scroll, загрузка тайлов.
- `comics-viewer.css` — слои/тайлы, GPU hints, скролл.
- ZIP распаковка — `fflate` или аналог.

---

## 3. CSS (база)

Ключевые требования:

- `.comics-viewer`: `overflow-y: scroll`, `-webkit-overflow-scrolling: touch`
- `.comics-layer`: `position: absolute`, `will-change: transform, opacity`, `transform-origin: top left`
- `.comics-tile`: `position: absolute`, `width/height: 512px`, `content-visibility: auto`

---

## 4. JavaScript Engine (контракт поведения)

### 4.1. Загрузка

1. Fetch `.comics` (ZIP)
2. `unzipSync` → словарь файлов
3. `data.json` → `comics`
4. `prepare` (разнести анимации по типам, отсортировать)
5. Initial render

### 4.2. Scroll handler

- На scroll:
  - `scrollOffset = round(scrollTop / scale)`
  - `processAnimations(scrollOffset)`
  - `updateLayerTransforms()`
  - `updateVisibleTiles()`
  - notify callbacks (`onScroll(offset, max)`)

### 4.3. Tile loading

- Тайлы загружаются только для viewport + margin (минимум 1 экран)
- Кэш тайлов хранит object URLs / decoded resources
- Для отсутствующих тайлов: placeholder или skip (зависит от продукта; важно не падать)

---

## 5. Hit-testing (Web)

Минимальный контракт:

- тест слоёв back-to-front
- преобразовать координаты экрана в координаты контента
- применить inverse transform слоя и проверить bounds

Опционально (дороже): пиксельный alpha hit-test через offscreen canvas.

---

## 6. Формат данных (`data.json`) — общий

Web-движок должен читать тот же формат, что и native/unity:

- `width`, `height`
- `layers[]` с `images[]` и `animations[]`
- `sounds[]` (опционально)

---

## Утверждение

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [conditions/clarifications]

