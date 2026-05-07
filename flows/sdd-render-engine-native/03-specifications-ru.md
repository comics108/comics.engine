# Спецификации: Нативный рендер-движок плагина (тайлинг + слои)

> Версия: 1.0
> Статус: DRAFT
> Последнее обновление: 2026-05-07
> Требования: `01-requirements.md`
> Извлечено из: legacy-bhagavadgita-render-engine-web-css, legacy-mahabharata-render-engine-android-java, legacy-mahabharata-render-engine-ios-swift

---

## Обзор

Данная спецификация описывает рендер-движок для Flutter-плагина `flutter_comics`, который реализует **нативный рендеринг комиксов** на Android и iOS. Движок обеспечивает:

- Тайловый рендеринг очень больших изображений (512x512 px тайлы)
- Послойную композицию с трансформациями (translate, rotate, scale, alpha)
- Scroll-driven анимации слоёв
- Управление памятью через viewport-aware загрузку/выгрузку тайлов
- Hit-testing по альфа-каналу для интерактивности

---

## 1. Архитектура системы

### 1.1. Компонентная диаграмма

```
┌─────────────────────────────────────────────────────────────────┐
│                    Flutter App (bhagavadgita_comics)            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  ComicsViewerWidget                                       │  │
│  │  - Передаёт метаданные сцены в плагин                     │  │
│  │  - Получает события (tap, long-press, ошибки загрузки)   │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ Platform Channel
┌─────────────────────────────────────────────────────────────────┐
│                    Flutter Plugin (flutter_comics)              │
│  ┌───────────────────────┬───────────────────────────────────┐  │
│  │   Android Native      │       iOS Native                  │  │
│  │   ────────────────    │       ──────────                  │  │
│  │   ZoomFrameLayout     │       UIScrollView                │  │
│  │        │              │            │                      │  │
│  │        ▼              │            ▼                      │  │
│  │   LayersView          │       tilesContainer (UIView)     │  │
│  │   (FrameLayout)       │            │                      │  │
│  │        │              │            ▼                      │  │
│  │        ▼              │       TileImageView[]             │  │
│  │   TileImageView[]     │       (CATiledLayer)              │  │
│  │   (View + Canvas)     │                                   │  │
│  └───────────────────────┴───────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Tile Source (абстракция)                     │
│  - Android: descriptor.getImage(fileName) → InputStream        │
│  - iOS: ArchiveManager.layer(name:) → UIImage                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2. Поток данных

```
Изменение scroll offset
    │
    ▼
Обработка анимаций (Comics.process / comics.process)
    │
    ▼
Для каждого слоя:
    ├── Вычисление матрицы трансформации + alpha
    ├── Применение трансформации к view слоя
    │
    ├── IF слой пересекает "viewport + margin":
    │       Загрузка тайлов для видимой области
    │
    └── ELSE:
            Выгрузка тайлов (но сохранение view во избежание артефактов)
    │
    ▼
Invalidation → перерисовка
```

---

## 2. Модель данных

### 2.1. Comics (Сцена)

| Поле | Тип | Описание |
|------|-----|----------|
| `width` | Int | Логическая ширина контента в пикселях |
| `height` | Int | Логическая высота контента в пикселях |
| `layers` | Layer[] | Массив слоёв, отсортированных back-to-front |
| `sounds` | Sound[] | Массив звуков, привязанных к scroll offset |

**Android** (`Comics.java`):
```java
public class Comics {
    private int width;
    private int height;
    private ArrayList<Layer> layers;
    private ArrayList<Sound> sounds;

    public void process(int scrollOffset) {
        for (Layer layer : getLayers())
            layer.buildMatrixAndAlpha(scrollOffset);
        // + обработка звуков
    }
}
```

**iOS** (`Comics.swift`):
```swift
class Comics: Codable {
    let width: Int
    let height: Int
    let layers: [Layer]
    let sounds: [Sound]

    func process(scrollOffset: Int) {
        for layer in self.layers {
            layer.buildMatrixAndAlpha(scrollOffset: scrollOffset)
        }
    }
}
```

### 2.2. Layer (Слой)

| Поле | Тип | Описание |
|------|-----|----------|
| `preview` | Bool? | Флаг preview-слоя |
| `images` | Image[] | Массив изображений по языкам (индекс = ordinal языка) |
| `animations` | LayerAnim[] | Массив анимаций (сортируются по start при prepare) |

**Выбор изображения по языку:**
1. Берётся `images[currentLanguage.ordinal]`
2. Если пустое — fallback на первое непустое из массива

**Трансформации (transient):**
- `translates: TranslateAnim[]`
- `rotates: RotateAnim[]`
- `scales: ScaleAnim[]`
- `alphas: AlphaAnim[]`

### 2.3. Image (Изображение слоя)

| Поле | Тип | Описание |
|------|-----|----------|
| `width` | Int | Ширина изображения |
| `height` | Int | Высота изображения |
| `file` | String? | Путь к файлу/шаблону тайлов (например: `layers/{0}_{1}_{2}.png`) |
| `popup` | String? | Путь к popup-изображению для long-press |

**Определение tileMode:**
```
tileMode = file.contains("{0}")
```

### 2.4. Sound (Звук)

| Поле | Тип | Описание |
|------|-----|----------|
| `file` | String? | Путь к звуковому файлу |
| `animations` | SoundAnim[] | Массив триггеров по scroll offset |

**Типы звуковых анимаций:**
- **Point sound** (`start == end`): воспроизводится один раз при достижении offset
- **Range sound** (`start < end`): loop пока scroll внутри диапазона

---

## 3. Система анимаций

### 3.1. Базовый класс Anim

| Поле | Тип | Описание |
|------|-----|----------|
| `start` | Int | Начальный scroll offset |
| `end` | Int | Конечный scroll offset |
| `type` | AnimType | Тип анимации: translate, rotate, scale, alpha, sound |

### 3.2. Типы анимаций слоёв (LayerAnim)

#### TranslateAnim
| Поле | Тип | Описание |
|------|-----|----------|
| `x` | Int | Смещение по X |
| `y` | Int | Смещение по Y |

**Применение:**
```
matrix.postTranslate(x, y)
```

#### RotateAnim
| Поле | Тип | Описание |
|------|-----|----------|
| `angle` | Float | Угол поворота (0-360 градусов) |
| `pivotX` | Float | Точка поворота X (0.0-1.0 от ширины) |
| `pivotY` | Float | Точка поворота Y (0.0-1.0 от высоты) |

**Применение:**
```
matrix.postTranslate(-width * pivotX, -height * pivotY)
matrix.postRotate(angle)
matrix.postTranslate(width * pivotX, height * pivotY)
```

#### ScaleAnim
| Поле | Тип | Описание |
|------|-----|----------|
| `scaleX` | Float | Масштаб по X |
| `scaleY` | Float | Масштаб по Y |
| `pivotX` | Float | Точка масштабирования X (0.0-1.0) |
| `pivotY` | Float | Точка масштабирования Y (0.0-1.0) |

**Применение:**
```
matrix.postTranslate(-width * pivotX, -height * pivotY)
matrix.postScale(scaleX, scaleY)
matrix.postTranslate(width * pivotX, height * pivotY)
```

#### AlphaAnim
| Поле | Тип | Описание |
|------|-----|----------|
| `alpha` | Float | Прозрачность (0.0-1.0) |

### 3.3. Алгоритм интерполяции

**Вычисление fraction:**
```
scrollObject = scrollOffset - endAnim.start
animHeight = endAnim.end - endAnim.start
fraction = animHeight == 0 ? 1 : clamp(scrollObject / animHeight, 0, 1)
```

**Кубическая функция сглаживания (ease-out):**
```
transformToCubic(fraction) = (fraction - 1)³ + 1
```

**Порядок применения анимаций:**
1. Scale
2. Rotate
3. Translate
4. Alpha (отдельно от матрицы)

### 3.4. Значения по умолчанию

| Тип | Значения по умолчанию |
|-----|----------------------|
| Translate | x=0, y=0 |
| Rotate | angle=0, pivotX=0.5, pivotY=0.5 |
| Scale | scaleX=1, scaleY=1, pivotX=0.5, pivotY=0.5 |
| Alpha | alpha=1.0 |

---

## 4. Тайловый рендеринг

### 4.1. Константы

| Параметр | Значение |
|----------|----------|
| TILE_SIZE | 512 px |
| ZOOM_LEVELS (Android) | [1.0, 0.5, 0.25, 0.125] |

### 4.2. Формат имени тайла

```
template.replace("{0}", zoom * 1000)
        .replace("{1}", column)
        .replace("{2}", row)
```

**Пример:**
- Шаблон: `layers/background_{0}_{1}_{2}.png`
- zoom=1.0, col=2, row=3 → `layers/background_1000_2_3.png`
- zoom=0.5, col=1, row=2 → `layers/background_500_1_2.png`

### 4.3. Placeholder (Android)

Если хотя бы один видимый тайл отсутствует в кэше:
```
placeholderFileName = template
    .replace("{0}", "ph")
    .replace("{1}", "0")
    .replace("{2}", "0")
```

### 4.4. Вычисление тайлов (Android)

```java
private Set<Tile> buildTiles(float zoomLevel) {
    Set<Tile> tiles = new HashSet<>();
    int realWidth = (int) (contentRect.width() * zoomLevel);
    int realHeight = (int) (contentRect.height() * zoomLevel);

    int column = 0;
    for (int i = 0; i < realWidth; i += TILE_SIZE) {
        int row = 0;
        for (int j = 0; j < realHeight; j += TILE_SIZE) {
            tiles.add(new Tile(column, row, zoomLevel));
            row++;
        }
        column++;
    }
    return tiles;
}
```

**Rect тайла в координатах контента:**
```
rectX = column * TILE_SIZE / zoomLevel
rectY = row * TILE_SIZE / zoomLevel
rectW = min(TILE_SIZE, contentWidth * zoomLevel - TILE_SIZE * column) / zoomLevel
rectH = min(TILE_SIZE, contentHeight * zoomLevel - TILE_SIZE * row) / zoomLevel
```

### 4.5. CATiledLayer (iOS)

```swift
class CATiledLayerNoAnim: CATiledLayer {
    override class func fadeDuration() -> CFTimeInterval {
        return 0  // Отключение fade-анимации
    }
}

// Фиксация contentScaleFactor для корректной работы на retina
override var contentScaleFactor: CGFloat {
    get { return super.contentScaleFactor }
    set { super.contentScaleFactor = 1 }
}
```

### 4.6. Выбор zoom level (Android)

```java
private float selectZoom() {
    if (!tileMode) return NO_TILES;
    if (!zoomEnabled) return ZOOM_LEVELS[0];

    for (float level : ZOOM_LEVELS) {
        if (scale >= Math.min(level, 0.8f))
            return level;
    }
    return ZOOM_LEVELS[ZOOM_LEVELS.length - 1];
}
```

---

## 5. Управление viewport и памятью

### 5.1. Viewport margin (iOS)

```swift
// 3x viewport для preload
let visibleRectHeight = scrollView.frame.size.height / self.zoomScale
let visibleRectWidth = scrollView.frame.size.width / self.zoomScale

let intersectRect = CGRect(
    x: -visibleRectWidth,
    y: scrollView.contentOffset.y / self.zoomScale - visibleRectHeight,
    width: visibleRectWidth * 3,
    height: visibleRectHeight * 3
)
```

### 5.2. Логика загрузки/выгрузки тайлов

```
IF layer.frame.intersects(intersectRect):
    tile.prepareTiles()  // Загрузить тайлы
ELSE:
    tile.killTiles()     // Выгрузить тайлы, но НЕ удалять view
```

**ВАЖНО:** Удаление view вызывает артефакты ("чёрные квадраты"). Всегда сохранять view, выгружая только bitmap-данные.

### 5.3. Кэширование (Android)

```java
// Ключ кэша
String key = descriptorName + "_" + fileName;

// Получение из кэша
Bitmap bitmap = CacheManager.getBitmapCache().get(
    ImageManager.buildKey(descriptor, tile.getFileName())
);
```

---

## 6. Hit-testing (Android)

```java
public boolean isHit(float[] point) {
    // 1. Проверка границ view
    if (point[0] < 0 || point[1] < 0 ||
        point[0] > getWidth() || point[1] > getHeight())
        return false;

    // 2. Найти тайл под точкой
    Tile hitTile = findTileAt(point);
    if (hitTile == null) return false;

    // 3. Получить bitmap тайла
    Bitmap bitmap = getFromCache(hitTile);
    if (bitmap == null) return false;

    // 4. Преобразовать координаты в локальные
    int localX = (point[0] - hitTile.left) * zoomLevel;
    int localY = (point[1] - hitTile.top) * zoomLevel;

    // 5. Проверить alpha
    return Color.alpha(bitmap.getPixel(localX, localY)) > 0;
}
```

---

## 7. Zoom/Pan контейнер (Android)

### 7.1. ZoomFrameLayout

| Функция | Описание |
|---------|----------|
| `setContentSize(w, h)` | Установка размера контента |
| `scale(factor, pivotX, pivotY)` | Масштабирование |
| `translate(transX, transY)` | Перемещение |
| `getCurrentScrollX/Y()` | Текущий scroll offset |

### 7.2. FitMode

- `VERTICAL`: `minScale = viewRect.height / contentRect.height`
- `HORIZONTAL`: `minScale = viewRect.width / contentRect.width`

### 7.3. ZoomableView interface

```java
interface ZoomableView {
    void onUpdate(float scale, int scrollX, int scrollY,
                  int extendedX, int extendedY);
}
```

---

## 8. Web-экспорт (Bhagavadgita reference)

### 8.1. CreateJS/Adobe Animate

Веб-экспорт использует **CreateJS** библиотеку с timeline-based анимацией:

```javascript
lib.properties = {
    width: 1080,
    height: 1440,
    fps: 24,
    manifest: [
        {src: "images/_383_8.png?...", id: "_383_8"},
        {src: "images/Anim1_HTML5 Canvas_atlas_1.png?...", id: "..."}
    ]
};
```

### 8.2. Sprite Sheet Metadata

```javascript
lib.ssMetadata = [
    {name: "atlas_1", frames: [[x,y,w,h], ...]},
    ...
];
```

### 8.3. Timeline Tweens

```javascript
// Пример tween с трансформациями
this.timeline.addTween(
    cjs.Tween.get(this.instance)
        .wait(256)
        .to({scaleX:1, scaleY:1, x:-253.5, y:1761}, 69)
        .to({startPosition:0}, 58)
        .to({_off:true}, 1)
        .wait(2)
);
```

**Отличия от нативной реализации:**
- Web использует frame-based timeline (24 fps)
- Нативная реализация использует scroll-driven анимации
- Оба подхода поддерживают одинаковые трансформации

---

## 9. Интерфейс Flutter ↔ Native

### 9.1. Входные данные (Flutter → Native)

```dart
class SceneDescriptor {
  final int width;
  final int height;
  final List<LayerDescriptor> layers;
  final String archivePath;
  final String language;
  final bool zoomEnabled;
}

class LayerDescriptor {
  final String imageTemplate;  // e.g. "layers/{0}_{1}_{2}.png"
  final int width;
  final int height;
  final String? popup;
  final List<AnimationDescriptor> animations;
}
```

### 9.2. Выходные события (Native → Flutter)

| Событие | Данные |
|---------|--------|
| `onLayerTap` | layerIndex, popupPath |
| `onLayerLongPress` | layerIndex, popupPath |
| `onTileLoadError` | layerIndex, fileName, error |
| `onScrollChanged` | scrollOffset |

### 9.3. Команды управления

| Метод | Описание |
|-------|----------|
| `setScrollOffset(int offset)` | Программная установка scroll |
| `setZoomEnabled(bool enabled)` | Включение/выключение zoom |
| `hitTest(float x, float y)` | Проверка попадания в слой |
| `dispose()` | Освобождение ресурсов |

---

## 10. Тестирование

### 10.1. Unit-тесты

| Тест | Описание |
|------|----------|
| `testTileFileName` | Проверка генерации имени тайла |
| `testAnimationInterpolation` | Проверка интерполяции анимаций |
| `testMatrixApplication` | Проверка порядка применения трансформаций |
| `testViewportIntersection` | Проверка логики пересечения с viewport |

### 10.2. Golden-тесты

- Рендер сцены с известными параметрами
- Сравнение с reference-изображениями
- Проверка на обоих платформах

---

## 11. Миграция с legacy-кода

### 11.1. Маппинг файлов

| Legacy (Android) | Legacy (iOS) | Flutter Plugin |
|------------------|--------------|----------------|
| `TileImageView.java` | `TileImageView.swift` | `TileImageView.kt/swift` |
| `ZoomFrameLayout.java` | `ImageScrollView.swift` | `ComicsContainerView.kt/swift` |
| `Layer.java` | `Layer.swift` | `LayerRenderer.kt/swift` |
| `Comics.java` | `Comics.swift` | `SceneProcessor.kt/swift` |

### 11.2. Ключевые инварианты

1. **Tile size = 512** — не менять
2. **Tile naming: {0}{1}{2}** — сохранить совместимость с архивами
3. **Animation order: scale → rotate → translate** — критично для визуала
4. **Cubic easing: (f-1)³+1** — сохранить для консистентности

---

## Утверждение

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [conditions/clarifications]
