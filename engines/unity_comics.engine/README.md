# Comics Engine (Unity)

Движок для отображения интерактивных `.comics` / `.puzzle` архивов с scroll-driven анимациями в Unity.

## Возможности

- Загрузка и распаковка ZIP-архивов `.comics` / `.puzzle`
- Scroll-driven анимации (translate, rotate, scale, alpha, pivot)
- Тайловый рендеринг больших изображений (TILE_SIZE = 512px)
- Мультиязычность (переключение культуры)
- Воспроизведение звуков по scroll-позиции
- События загрузки, скролла, ошибок

## Требования

- Unity **2021.3 LTS** или новее
- Пакет **Newtonsoft.Json** (для парсинга data.json)

## Установка

### Через Package Manager (рекомендуется)

1. Откройте **Window → Package Manager**
2. Нажмите **+** → **Add package from disk...**
3. Выберите `app/unity_comics.engine/package.json`

### Через manifest.json

Добавьте в `Packages/manifest.json`:

```json
{
  "dependencies": {
    "net.nativemind.comics-viewer": "file:../../app/unity_comics.engine"
  }
}
```

## Быстрый старт

### 1. Добавьте компонент ComicsViewer

```csharp
using NativeMind.ComicsViewer;
using UnityEngine;

public class MyViewer : MonoBehaviour
{
    void Start()
    {
        var viewer = gameObject.AddComponent<ComicsViewer>();
        viewer.LoadArchive("path/to/my.comics");
    }
}
```

### 2. Или через Inspector

1. Создайте пустой GameObject
2. Добавьте компонент **Comics Viewer**
3. Укажите путь к архиву в поле **Archive Path**
4. Play!

## API

### ComicsViewer

```csharp
// Загрузка архива
viewer.LoadArchive(string path);

// Управление скроллом
viewer.SetScrollOffset(float offset);
float current = viewer.ScrollOffset;
float max = viewer.MaxScrollOffset;

// Язык (0 = En, 1 = Ru, 2 = Hi)
viewer.SetLanguageIndex(int index);

// Звук
viewer.SetSoundEnabled(bool enabled);
viewer.PauseSounds();
viewer.ResumeSounds();

// Выгрузка
viewer.Unload();
```

### События

```csharp
viewer.OnLoaded += (ComicsInfo info) => {
    Debug.Log($"Loaded: {info.Width}x{info.Height}, {info.LayerCount} layers");
};

viewer.OnScroll += (float scrollY, float maxScroll) => {
    Debug.Log($"Scroll: {scrollY}/{maxScroll}");
};

viewer.OnError += (string message) => {
    Debug.LogError($"Error: {message}");
};
```

## Структура проекта

```
unity_comics.engine/
├── package.json                 # UPM манифест
├── Runtime/
│   ├── ComicsViewer.cs          # Главный MonoBehaviour
│   ├── Core/
│   │   └── AnimationProcessor.cs # Вычисление трансформаций
│   ├── Models/
│   │   ├── Comics.cs            # Модель документа
│   │   └── Anim.cs              # Типы анимаций
│   ├── IO/
│   │   ├── ZipArchiveProvider.cs # Работа с ZIP
│   │   └── ComicsParser.cs      # Парсинг JSON
│   ├── Rendering/
│   │   ├── TileRenderer.cs      # Тайловый рендеринг
│   │   └── TileCache.cs         # Кэш текстур
│   └── Audio/
│       └── SoundManager.cs      # Воспроизведение звуков
├── Editor/
│   └── (Editor-only код)
└── Samples~/
    └── BasicViewer/             # Демо-сцена
```

## Инварианты (не изменять!)

| Параметр | Значение |
|----------|----------|
| TILE_SIZE | 512 px |
| Именование тайлов | `{zoom*1000}_{col}_{row}.png` |
| Порядок трансформаций | Scale → Rotate → Translate |
| Функция сглаживания | `(f-1)³ + 1` (cubic ease-out) |

## Формат .comics

```
my.comics (ZIP)
├── data.json          # Метаданные + анимации
├── layers/
│   ├── 0/             # Слой 0
│   │   ├── 1000_0_0.png
│   │   ├── 1000_0_1.png
│   │   └── ...
│   └── 1/             # Слой 1
│       └── ...
└── sounds/
    ├── bgm.mp3
    └── sfx.mp3
```

## Планируемые улучшения

### IComicsSource абстракция

Для поддержки редактора планируется рефакторинг:

```csharp
interface IComicsSource
{
    Comics LoadData();
    Texture2D LoadTile(string path);
    AudioClip LoadSound(string path);
    void Invalidate();
}

class ZipArchiveSource : IComicsSource { ... }  // Runtime
class FolderSource : IComicsSource { ... }      // Editor
```

См. `flows/sdd-comics.engine-shared-core/` для деталей.

## Связанные документы

- Спецификации: `flows/sdd-comics.engine-csharp-unity/specifications-ru.md`
- Формат данных: `flows/sdd-comics.engine-format/02-specifications-ru.md`
- ADR-006: Порядок трансформаций: `flows/adr-006-transform-composition-order/adr.md`

## Лицензия

Proprietary - NativeMind
