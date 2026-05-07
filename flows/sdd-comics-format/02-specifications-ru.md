# Спецификации: Формат `.comics` (ZIP + `data.json`) — v1

> Версия: 1.0  
> Статус: DRAFT  
> Последнее обновление: 2026-05-08  
> Требования: `01-requirements.md`

---

## 1. Контейнер и структура архива

### 1.1. Контейнер

`.comics` — это **ZIP-архив**.

### 1.2. Минимальная структура (v1)

```
episode.comics
├── data.json
├── layers/
│   ├── <files referenced by data.json>
│   └── ...
└── sounds/              (опционально)
    ├── <files referenced by data.json>
    └── ...
```

Требования к путям:

- пути внутри `data.json` задаются относительно корня ZIP
- рекомендуется использовать только подкаталоги `layers/` и `sounds/`

---

## 2. Инварианты совместимости (v1)

| Инвариант | Значение |
|----------|----------|
| TILE_SIZE | 512 px |
| Tile naming placeholders | `{0}`, `{1}`, `{2}` |
| `{0}` | `Int(zoom * 1000)` |
| `{1}` | column index |
| `{2}` | row index |
| Animation order | Scale → Rotate → Translate (alpha отдельно) |
| Easing | \( (f-1)^3 + 1 \) |

---

## 3. `data.json` (v1)

### 3.1. Корневой объект

| Поле | Тип | Обяз. | Описание |
|------|-----|-------|----------|
| `version` | Int | нет | Версия формата. Если отсутствует — считать `1`. |
| `width` | Int | да | Логическая ширина сцены |
| `height` | Int | да | Логическая высота сцены |
| `layers` | Layer[] | да | Слои back-to-front |
| `sounds` | Sound[] | нет | Звуковые дорожки/триггеры |

### 3.2. Layer

| Поле | Тип | Обяз. | Описание |
|------|-----|-------|----------|
| `preview` | Bool | нет | preview слой |
| `images` | Image[] | да | изображения (мульти-язык) |
| `animations` | Anim[] | нет | сегменты анимаций |

### 3.3. Image

| Поле | Тип | Обяз. | Описание |
|------|-----|-------|----------|
| `width` | Int | да | ширина изображения слоя |
| `height` | Int | да | высота изображения слоя |
| `file` | String | нет | путь или шаблон тайлов |
| `popup` | String | нет | popup-ресурс для long-press |

tileMode (конвенция):

```
tileMode = file.contains("{0}")
```

### 3.4. Anim (слой)

Базовые поля:

| Поле | Тип | Описание |
|------|-----|----------|
| `type` | String | `translate` \| `rotate` \| `scale` \| `alpha` |
| `start` | Int | начало диапазона scrollOffset |
| `end` | Int | конец диапазона scrollOffset |

Поля по типам:

- `translate`: `x:Int`, `y:Int`
- `rotate`: `angle:Float`, `pivotX:Float` (0..1), `pivotY:Float` (0..1)
- `scale`: `scaleX:Float`, `scaleY:Float`, `pivotX:Float` (0..1), `pivotY:Float` (0..1)
- `alpha`: `alpha:Float` (0..1)

---

## 4. Tile naming (v1)

Если `image.file` — шаблон тайлов, он обязан содержать `{0}`, `{1}`, `{2}`.

Подстановка:

```
fileName =
  template.replace("{0}", Int(zoom * 1000))
          .replace("{1}", col)
          .replace("{2}", row)
```

Пример:

- `layers/background_{0}_{1}_{2}.png`
- zoom=1.0, col=2, row=3 → `layers/background_1000_2_3.png`

---

## 5. Animation math (v1)

Fraction:

```
scrollObject = scrollOffset - endAnim.start
animHeight = endAnim.end - endAnim.start
fraction = animHeight == 0 ? 1 : clamp(scrollObject / animHeight, 0, 1)
```

Easing:

```
easeOutCubic(f) = (f - 1)³ + 1
```

Порядок применения:

1. Scale
2. Rotate
3. Translate
4. Alpha

---

## 6. Sound (v1, опционально)

### 6.1. Sound

| Поле | Тип | Описание |
|------|-----|----------|
| `file` | String | путь к аудио-файлу (обычно `sounds/...`) |
| `animations` | SoundAnim[] | триггеры по scrollOffset |

### 6.2. SoundAnim

| Поле | Тип | Описание |
|------|-----|----------|
| `type` | String | `sound` |
| `start` | Int | начало |
| `end` | Int | конец |

Семантика:

- **Point sound**: `start == end` → проиграть один раз при достижении offset
- **Range sound**: `start < end` → loop пока scroll внутри диапазона

---

## 7. Error handling (парсер формата)

Рекомендации для всех движков:

- отсутствует `data.json` → ошибка “Invalid comics archive”, без краша
- `data.json` не парсится → ошибка с деталями, без краша
- отсутствует ресурс слоя/тайла/звука → placeholder/skip + лог (не блокировать рендер)

---

## 8. Расширения формата (v2 placeholder)

Формат допускает расширение через `version >= 2`. Поля v2 (например `zDepth`, `speechBubble`) должны игнорироваться движками, которые не поддерживают v2, но **не должны ломать** парсинг v1 полей.

---

## Утверждение

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [conditions/clarifications]

