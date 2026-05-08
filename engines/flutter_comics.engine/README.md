# comics.engine

Runtime-движки для отображения интерактивных `.comics` / `.puzzle` архивов со scroll-driven анимациями.

## Поддерживаемые платформы

| Платформа | Пакет | Статус |
|-----------|-------|--------|
| **Flutter** | `flutter_comics` | iOS, Android, macOS, Windows, Linux |
| **Unity** | `net.nativemind.comics-viewer` | Unity 2021.3+ |
| **Web** | vanilla JS | Chrome, Firefox, Safari |

## Возможности

- Загрузка и распаковка ZIP-архивов `.comics` / `.puzzle`
- Scroll-driven анимации (translate, rotate, scale, alpha, pivot)
- Тайловый рендеринг больших изображений (512px tiles)
- Мультиязычность (переключение culture/languageIndex)
- Воспроизведение звуков по scroll-позиции
- Hit-testing для интерактивных слоёв
- Popup-изображения при тапе на слой

---

## Flutter


## Getting Started

- Add to your project:

```yaml
# pubspec.yaml
dependencies:
  flutter_comics: ^0.0.1
```

- Import:

```dart
import 'package:flutter_comics/flutter_comics.dart';
```


### Установка
```

### Базовое использование

```dart
import 'package:flutter/material.dart';
import 'package:flutter_comics/flutter_comics.dart';

class MyComicsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ComicsViewer(
        archivePath: '/path/to/my.comics',
        languageIndex: 0,        // 0=En, 1=Ru, 2=Hi
        soundEnabled: true,
        onSceneLoaded: (info) {
          print('Loaded: ${info.width}x${info.height}, ${info.layerCount} layers');
        },
        onScrollChanged: (offset, maxOffset) {
          print('Scroll: $offset / $maxOffset');
        },
        onLayerTap: (layerIndex, popupPath) {
          if (popupPath != null) {
            // Show popup image
          }
        },
        onError: (error) => print('Error: $error'),
      ),
    );
  }
}
```

### Программное управление через Controller

```dart
class MyComicsPage extends StatefulWidget {
  @override
  State<MyComicsPage> createState() => _MyComicsPageState();
}

class _MyComicsPageState extends State<MyComicsPage> {
  final _controller = ComicsViewerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _controller.setScrollOffset(0);
  }

  void _toggleSound(bool enabled) {
    _controller.setSoundEnabled(enabled);
  }

  void _changeLanguage(int index) {
    _controller.setLanguageIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comics Viewer'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_upward),
            onPressed: _scrollToTop,
          ),
          IconButton(
            icon: Icon(Icons.volume_up),
            onPressed: () => _toggleSound(true),
          ),
          IconButton(
            icon: Icon(Icons.volume_off),
            onPressed: () => _toggleSound(false),
          ),
        ],
      ),
      body: ComicsViewer(
        archivePath: '/path/to/my.comics',
        controller: _controller,
        loadingWidget: Center(child: CircularProgressIndicator()),
        errorBuilder: (error) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

### Flutter API Reference

```dart
// ComicsViewer widget properties
ComicsViewer({
  required String archivePath,       // Путь к .comics файлу
  int languageIndex = 0,             // Индекс языка (0-based)
  int initialScrollOffset = 0,       // Начальная позиция скролла
  bool zoomEnabled = false,          // Разрешить зум (для puzzle)
  bool soundEnabled = true,          // Включить звук
  ComicsViewerController? controller,// Контроллер для управления

  // Callbacks
  void Function(ComicsInfo)? onSceneLoaded,
  void Function(int offset, int maxOffset)? onScrollChanged,
  void Function(int layerIndex, String? popupPath)? onLayerTap,
  void Function(int layerIndex, String? popupPath)? onLayerLongPress,
  void Function(String error)? onError,

  // Custom widgets
  Widget? loadingWidget,
  Widget Function(String error)? errorBuilder,
});

// ComicsViewerController methods
await controller.setScrollOffset(int offset);
await controller.setLanguageIndex(int index);
await controller.setSoundEnabled(bool enabled);
await controller.pauseSounds();
await controller.resumeSounds();
int offset = await controller.getScrollOffset();
HitTestResult? hit = await controller.hitTest(double x, double y);
```

---

## Unity (C#)

### Установка

**Через Package Manager:**
1. Window → Package Manager → + → Add package from disk...
2. Выберите `engines/unity_comics.engine/package.json`

**Через manifest.json:**
```json
{
  "dependencies": {
    "net.nativemind.comics-viewer": "file:../../engines/unity_comics.engine"
  }
}
```

### Базовое использование

```csharp
using UnityEngine;
using NativeMind.ComicsViewer;

public class MyComicsPlayer : MonoBehaviour
{
    private ComicsViewer _viewer;

    void Start()
    {
        // Добавляем компонент
        _viewer = gameObject.AddComponent<ComicsViewer>();

        // Подписываемся на события
        _viewer.OnLoaded += OnComicsLoaded;
        _viewer.OnScroll += OnScrollChanged;
        _viewer.OnError += OnError;

        // Загружаем архив
        _viewer.LoadArchive(Application.streamingAssetsPath + "/my.comics");
    }

    void OnComicsLoaded(ComicsInfo info)
    {
        Debug.Log($"Loaded: {info.Width}x{info.Height}, {info.LayerCount} layers");
    }

    void OnScrollChanged(float scrollY, float maxScroll)
    {
        Debug.Log($"Scroll: {scrollY}/{maxScroll}");
    }

    void OnError(string message)
    {
        Debug.LogError($"Comics error: {message}");
    }

    void OnDestroy()
    {
        _viewer?.Unload();
    }
}
```

### Программное управление скроллом

```csharp
using UnityEngine;
using UnityEngine.UI;
using NativeMind.ComicsViewer;

public class ComicsPlayerWithUI : MonoBehaviour
{
    [SerializeField] private Slider scrollSlider;
    [SerializeField] private Toggle soundToggle;
    [SerializeField] private Dropdown languageDropdown;

    private ComicsViewer _viewer;

    void Start()
    {
        _viewer = GetComponent<ComicsViewer>();

        // Загрузка
        _viewer.LoadArchive(Application.streamingAssetsPath + "/episode1.comics");

        // UI bindings
        scrollSlider.onValueChanged.AddListener(OnSliderChanged);
        soundToggle.onValueChanged.AddListener(OnSoundToggled);
        languageDropdown.onValueChanged.AddListener(OnLanguageChanged);

        // Обновляем слайдер при скролле
        _viewer.OnScroll += (current, max) => {
            scrollSlider.SetValueWithoutNotify(current / max);
        };
    }

    void OnSliderChanged(float value)
    {
        _viewer.SetScrollOffset(value * _viewer.MaxScrollOffset);
    }

    void OnSoundToggled(bool enabled)
    {
        _viewer.SetSoundEnabled(enabled);
    }

    void OnLanguageChanged(int index)
    {
        // 0 = English, 1 = Russian, 2 = Hindi
        _viewer.SetLanguageIndex(index);
    }

    // Программная навигация
    public void ScrollToTop()
    {
        _viewer.SetScrollOffset(0);
    }

    public void ScrollToBottom()
    {
        _viewer.SetScrollOffset(_viewer.MaxScrollOffset);
    }

    public void ScrollBy(float delta)
    {
        var newOffset = Mathf.Clamp(
            _viewer.ScrollOffset + delta,
            0,
            _viewer.MaxScrollOffset
        );
        _viewer.SetScrollOffset(newOffset);
    }
}
```

### Пример с touch-управлением

```csharp
using UnityEngine;
using NativeMind.ComicsViewer;

public class TouchComicsController : MonoBehaviour
{
    private ComicsViewer _viewer;
    private float _lastTouchY;
    private bool _isDragging;

    void Start()
    {
        _viewer = GetComponent<ComicsViewer>();
        _viewer.LoadArchive(Application.streamingAssetsPath + "/story.comics");
    }

    void Update()
    {
        HandleTouchInput();
        HandleMouseInput();
    }

    void HandleTouchInput()
    {
        if (Input.touchCount == 0) return;

        var touch = Input.GetTouch(0);

        switch (touch.phase)
        {
            case TouchPhase.Began:
                _lastTouchY = touch.position.y;
                _isDragging = true;
                break;

            case TouchPhase.Moved:
                if (_isDragging)
                {
                    var deltaY = _lastTouchY - touch.position.y;
                    _viewer.SetScrollOffset(_viewer.ScrollOffset + deltaY);
                    _lastTouchY = touch.position.y;
                }
                break;

            case TouchPhase.Ended:
            case TouchPhase.Canceled:
                _isDragging = false;
                break;
        }
    }

    void HandleMouseInput()
    {
        // Scroll wheel
        var scroll = Input.mouseScrollDelta.y;
        if (Mathf.Abs(scroll) > 0.01f)
        {
            _viewer.SetScrollOffset(_viewer.ScrollOffset - scroll * 100f);
        }
    }
}
```

### Unity API Reference

```csharp
// ComicsViewer component
public class ComicsViewer : MonoBehaviour
{
    // Methods
    void LoadArchive(string path);
    void Unload();
    void SetScrollOffset(float offset);
    void SetLanguageIndex(int index);      // 0=En, 1=Ru, 2=Hi
    void SetSoundEnabled(bool enabled);
    void PauseSounds();
    void ResumeSounds();

    // Properties
    float ScrollOffset { get; }
    float MaxScrollOffset { get; }
    bool IsLoaded { get; }

    // Events
    event Action<ComicsInfo> OnLoaded;
    event Action<float, float> OnScroll;   // (current, max)
    event Action<string> OnError;
    event Action<int, string> OnLayerTap;  // (layerIndex, popupPath)
}

// ComicsInfo struct
public struct ComicsInfo
{
    public int Width;
    public int Height;
    public int LayerCount;
    public int SoundCount;
}
```

---

## Формат .comics

```
my.comics (ZIP)
├── data.json          # Метаданные + анимации
├── layers/
│   ├── image.png      # Простое изображение
│   └── big_1000_0_0.png  # Тайлы: {zoom*1000}_{col}_{row}.png
└── sounds/
    ├── bgm.mp3
    └── sfx.mp3
```

### Инварианты

| Параметр | Значение |
|----------|----------|
| Размер тайла | 512 px |
| Порядок трансформаций | Scale → Rotate → Translate |
| Easing функция | `(f-1)³ + 1` (cubic ease-out) |
| languageIndex | 0=En, 1=Ru, 2=Hi |

---

## Структура репозитория

```
comics.engine/
├── engines/
│   ├── flutter_comics.engine/   # Flutter plugin
│   ├── unity_comics.engine/     # Unity package
│   └── web_comics.engine/       # Web viewer (JS)
├── flows/                       # Спецификации и ADR
├── sample/                      # Тестовые архивы
└── legacy/                      # Исторические реализации
```


## Links

- Repository: https://github.com/gita108/comics.engine

## Лицензия

NativeMindNONC
