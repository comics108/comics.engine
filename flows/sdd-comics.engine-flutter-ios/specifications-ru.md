# Спецификации: Comics Engine — Flutter / iOS (нативный рендер, тайлинг + слои)

> Версия: 1.0  
> Статус: DRAFT  
> Последнее обновление: 2026-05-08  
> Источник: извлечено из legacy-спеки `flows/sdd-render-engine-native/03-specifications-ru.md` и адаптировано под iOS
>
> Формат `.comics` (ZIP + `data.json`) — см. `../sdd-comics-format/02-specifications-ru.md`

---

## Обзор

Данная спецификация описывает iOS-реализацию рендер-движка для Flutter-плагина `flutter_comics`, который обеспечивает:

- Тайловый рендеринг очень больших изображений (512×512) через `CATiledLayer`
- Послойную композицию с трансформациями и alpha
- Scroll-driven анимации слоёв
- Viewport-aware загрузку/выгрузку тайлов (с безопасной для визуала стратегией)

---

## 1. Инварианты (нельзя менять)

| Параметр | Значение |
|----------|----------|
| TILE_SIZE | 512 px |
| Tile naming | `{0}_{1}_{2}` |
| `{0}` | `Int(zoom * 1000)` |
| Порядок трансформаций | Scale → Rotate → Translate |
| Сглаживание | \( (f-1)^3 + 1 \) |
| Выгрузка | Выгружать изображения/bitmap, **не удаляя view** (иначе “чёрные квадраты”) |

---

## 2. Архитектура (iOS)

### 2.1. UIScrollView orchestration

iOS контейнер отвечает за:

- преобразование `contentOffset` в `scrollOffset` (в координатах контента)
- вычисление `intersectRect` (viewport + margin) в нескейленных координатах
- обновление transform/alpha для каждого слоя
- включение/выключение тайлов по пересечению с `intersectRect`

### 2.2. Tile view на `CATiledLayer`

`TileImageView`:

- базируется на `CATiledLayer`
- отключает fade-анимацию
- фиксирует `contentScaleFactor` для корректной работы на retina

Legacy-паттерн:

```
class CATiledLayerNoAnim: CATiledLayer {
  override class func fadeDuration() -> CFTimeInterval { 0 }
}

override var contentScaleFactor: CGFloat {
  get { super.contentScaleFactor }
  set { super.contentScaleFactor = 1 }
}
```

---

## 3. Модель данных (портируемая)

Совпадает с Android/Unity/Web:

- `Comics { width, height, layers[], sounds[] }`
- `Layer { preview?, images[], animations[] }`
- `Image { width, height, file?, popup? }`

Выбор изображения по языку:

1. `images[languageIndex]`
2. fallback на первое непустое

---

## 4. Анимации (iOS-математика и порядок)

Совпадает с инвариантами:

- fraction по диапазону `start..end`
- cubic ease-out: \( (f-1)^3 + 1 \)
- порядок: Scale → Rotate → Translate, alpha отдельно

---

## 5. Тайловый рендеринг (iOS)

### 5.1. TILE_SIZE и расчёт “эффективного размера” в контент-координатах

- Базовый тайл: 512×512 в пикселях тайла
- В `draw(_:)` вычисляется текущий scale из CTM контекста
- Эффективный размер тайла в координатах контента = `512 / scale`

### 5.2. Viewport margin (legacy 3× viewport)

Legacy-формула (идея):

- видимый rect в нескейленных координатах
- intersectRect = 3× viewport (по ширине и высоте), центрированный вокруг текущего viewport

---

## 6. Viewport и память (iOS)

### 6.1. Принцип

```
IF layer.frame.intersects(intersectRect):
  prepareTiles()
ELSE:
  killTiles()
```

### 6.2. Критичное ограничение

Удаление tile view вызывает визуальные артефакты (“чёрные квадраты”). Поэтому:

- view слоёв **создаётся один раз и остаётся**
- выгружаются только изображения/декодированные тайлы

---

## 7. Интерфейс Flutter ↔ iOS Native

### 7.1. Решение по контенту

- Flutter передаёт путь к `.comics` архиву
- iOS распаковывает ZIP и парсит `data.json`
- тайлы берутся из `layers/` по требованию

### 7.2. Каналы

- Method channel: `flutter_comics`
- Event channel: `flutter_comics/events`
- Platform view: `flutter_comics_view`

Контракт методов/событий должен совпадать с Android-спекой (единый Dart API).

---

## Утверждение

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [conditions/clarifications]

