# Specifications: C# Unity + Web CSS Render Engines

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-05-08
> Requirements: `requirements.md`
> Base specs: `../sdd-render-engine-native/03-specifications-ru.md`

## Overview

Два независимых рендер-движка для отображения .comics архивов:

1. **Unity/C#** — WorldSpace rendering для игр и приложений
2. **Web/JS+CSS** — браузерный просмотр с минимальным JS

Оба движка реализуют идентичную логику рендеринга из нативных спецификаций.

---

# ЧАСТЬ 1: Unity/C# Render Engine

## 1.1. Архитектура Unity

```
┌─────────────────────────────────────────────────────────────┐
│                     Unity Scene                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  ComicsCamera (Orthographic)                        │    │
│  │  - Handles zoom via orthographicSize                │    │
│  │  - Pan via transform.position                       │    │
│  └─────────────────────────────────────────────────────┘    │
│                         │                                    │
│                         ▼                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  ComicsContainer (Empty GameObject)                 │    │
│  │  - Parent for all layers                            │    │
│  │  - Scroll offset via transform.localPosition.y     │    │
│  │  └── Layer0 (Quad + Material)                       │    │
│  │      └── TileRenderer (generates tile meshes)       │    │
│  │  └── Layer1 (Quad + Material)                       │    │
│  │      └── TileRenderer                               │    │
│  │  └── ...                                            │    │
│  └─────────────────────────────────────────────────────┘    │
│                         │                                    │
│                         ▼                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  ComicsArchive (ScriptableObject or Runtime)        │    │
│  │  - Loads data.json                                  │    │
│  │  - Provides tile textures from ZIP                  │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## 1.2. Классы C#

### ComicsViewer.cs (MonoBehaviour)

```csharp
public class ComicsViewer : MonoBehaviour
{
    [Header("Settings")]
    public string archivePath;
    public int languageIndex = 0;
    public bool soundEnabled = true;

    [Header("References")]
    public Camera comicsCamera;
    public Transform container;

    // Events
    public event Action<ComicsInfo> OnLoaded;
    public event Action<int, string> OnLayerTap;
    public event Action<float> OnScrollChanged;
    public event Action<string> OnError;

    // Runtime
    private Comics comics;
    private List<LayerRenderer> layers = new();
    private float scrollOffset;
    private float contentHeight;

    public void LoadArchive(string path);
    public void SetScrollOffset(float offset);
    public void SetLanguage(int index);
    public HitTestResult HitTest(Vector2 screenPos);
}
```

### Comics.cs (Data Model)

```csharp
[Serializable]
public class Comics
{
    public int width;
    public int height;
    public List<Layer> layers;
    public List<Sound> sounds;

    [NonSerialized] private int previousScrollOffset = -1;

    public void Prepare()
    {
        foreach (var layer in layers)
            layer.Prepare();
    }

    public void Process(int scrollOffset)
    {
        foreach (var layer in layers)
            layer.BuildMatrixAndAlpha(scrollOffset);

        if (soundEnabled)
            ProcessSounds(scrollOffset, previousScrollOffset);

        previousScrollOffset = scrollOffset;
    }
}
```

### Layer.cs

```csharp
[Serializable]
public class Layer
{
    public bool preview;
    public List<Image> images;
    public List<Anim> animations;

    // Runtime (transient)
    [NonSerialized] private List<TranslateAnim> translates = new();
    [NonSerialized] private List<RotateAnim> rotates = new();
    [NonSerialized] private List<ScaleAnim> scales = new();
    [NonSerialized] private List<AlphaAnim> alphas = new();

    [NonSerialized] public Matrix4x4 matrix = Matrix4x4.identity;
    [NonSerialized] public float alpha = 1f;

    public Image CurrentImage => GetImageForLanguage(Settings.languageIndex);

    public void Prepare()
    {
        // Sort animations by type and start offset
        foreach (var anim in animations)
        {
            switch (anim.type)
            {
                case AnimType.Translate: translates.AddSorted(anim as TranslateAnim); break;
                case AnimType.Rotate: rotates.AddSorted(anim as RotateAnim); break;
                case AnimType.Scale: scales.AddSorted(anim as ScaleAnim); break;
                case AnimType.Alpha: alphas.AddSorted(anim as AlphaAnim); break;
            }
        }
        animations.Clear();
    }

    public void BuildMatrixAndAlpha(int scrollOffset)
    {
        var img = CurrentImage;
        if (img == null) return;

        matrix = Matrix4x4.identity;

        // Order: Scale → Rotate → Translate
        ApplyAnimations(scales, DefaultScale, scrollOffset, img);
        ApplyAnimations(rotates, DefaultRotate, scrollOffset, img);
        ApplyAnimations(translates, DefaultTranslate, scrollOffset, img);
        ApplyAnimations(alphas, DefaultAlpha, scrollOffset, img);
    }
}
```

### Anim.cs (Base + Derived)

```csharp
[Serializable]
public abstract class Anim
{
    public int start;
    public int end;
    public AnimType type;

    // Cubic easing: (f-1)³ + 1
    protected float CubicEase(float fraction)
    {
        float f = fraction - 1f;
        return f * f * f + 1f;
    }

    protected float ComputeFraction(int scrollOffset)
    {
        int scrollObj = scrollOffset - start;
        int animHeight = end - start;
        if (animHeight == 0) return 1f;
        return Mathf.Clamp01((float)scrollObj / animHeight);
    }

    public abstract Anim Interpolate(Anim endAnim, int scrollOffset);
    public abstract void Apply(ref Matrix4x4 matrix, ref float alpha, int width, int height);
}

[Serializable]
public class TranslateAnim : Anim
{
    public int x;
    public int y;

    public override void Apply(ref Matrix4x4 matrix, ref float alpha, int w, int h)
    {
        matrix = Matrix4x4.Translate(new Vector3(x, -y, 0)) * matrix;
    }
}

[Serializable]
public class RotateAnim : Anim
{
    public float angle;
    public float pivotX = 0.5f;
    public float pivotY = 0.5f;

    public override void Apply(ref Matrix4x4 matrix, ref float alpha, int w, int h)
    {
        float px = w * pivotX;
        float py = h * pivotY;

        matrix = Matrix4x4.Translate(new Vector3(-px, py, 0)) * matrix;
        matrix = Matrix4x4.Rotate(Quaternion.Euler(0, 0, -angle)) * matrix;
        matrix = Matrix4x4.Translate(new Vector3(px, -py, 0)) * matrix;
    }
}

[Serializable]
public class ScaleAnim : Anim
{
    public float scaleX = 1f;
    public float scaleY = 1f;
    public float pivotX = 0.5f;
    public float pivotY = 0.5f;

    public override void Apply(ref Matrix4x4 matrix, ref float alpha, int w, int h)
    {
        float px = w * pivotX;
        float py = h * pivotY;

        matrix = Matrix4x4.Translate(new Vector3(-px, py, 0)) * matrix;
        matrix = Matrix4x4.Scale(new Vector3(scaleX, scaleY, 1)) * matrix;
        matrix = Matrix4x4.Translate(new Vector3(px, -py, 0)) * matrix;
    }
}

[Serializable]
public class AlphaAnim : Anim
{
    public float alpha = 1f;

    public override void Apply(ref Matrix4x4 matrix, ref float layerAlpha, int w, int h)
    {
        layerAlpha = alpha;
    }
}
```

### TileRenderer.cs

```csharp
public class TileRenderer : MonoBehaviour
{
    private const int TILE_SIZE = 512;

    private Image image;
    private IArchiveProvider archive;
    private Dictionary<string, Texture2D> tileCache = new();
    private HashSet<string> loadingTiles = new();

    public void Initialize(Image image, IArchiveProvider archive)
    {
        this.image = image;
        this.archive = archive;
    }

    public void UpdateVisibleTiles(Rect viewportWorld)
    {
        var visibleTiles = ComputeVisibleTiles(viewportWorld);

        foreach (var tile in visibleTiles)
        {
            if (!tileCache.ContainsKey(tile.fileName) && !loadingTiles.Contains(tile.fileName))
            {
                loadingTiles.Add(tile.fileName);
                StartCoroutine(LoadTileAsync(tile));
            }
        }

        // Unload tiles outside viewport + margin
        UnloadDistantTiles(viewportWorld);
    }

    private string GetTileFileName(float zoom, int col, int row)
    {
        return image.file
            .Replace("{0}", ((int)(zoom * 1000)).ToString())
            .Replace("{1}", col.ToString())
            .Replace("{2}", row.ToString());
    }

    private IEnumerator LoadTileAsync(TileInfo tile)
    {
        var bytes = archive.GetFileBytes(tile.fileName);
        if (bytes != null)
        {
            var tex = new Texture2D(TILE_SIZE, TILE_SIZE);
            tex.LoadImage(bytes);
            tileCache[tile.fileName] = tex;
        }
        loadingTiles.Remove(tile.fileName);
        yield return null;
    }
}
```

### IArchiveProvider.cs

```csharp
public interface IArchiveProvider
{
    string GetTextFile(string path);
    byte[] GetFileBytes(string path);
    void Dispose();
}

public class ZipArchiveProvider : IArchiveProvider
{
    private ZipArchive archive;

    public ZipArchiveProvider(string zipPath)
    {
        var stream = File.OpenRead(zipPath);
        archive = new ZipArchive(stream, ZipArchiveMode.Read);
    }

    public string GetTextFile(string path)
    {
        var entry = archive.GetEntry(path);
        if (entry == null) return null;
        using var reader = new StreamReader(entry.Open());
        return reader.ReadToEnd();
    }

    public byte[] GetFileBytes(string path)
    {
        var entry = archive.GetEntry(path);
        if (entry == null) return null;
        using var stream = entry.Open();
        using var ms = new MemoryStream();
        stream.CopyTo(ms);
        return ms.ToArray();
    }
}
```

## 1.3. Unity Scroll Handling

```csharp
public class ComicsScrollHandler : MonoBehaviour
{
    public ComicsViewer viewer;
    public float scrollSpeed = 1f;
    public float maxScroll;

    private float currentScroll;

    void Update()
    {
        // Mouse wheel
        float wheel = Input.mouseScrollDelta.y;
        if (wheel != 0)
        {
            currentScroll = Mathf.Clamp(currentScroll - wheel * scrollSpeed, 0, maxScroll);
            viewer.SetScrollOffset(currentScroll);
        }

        // Touch drag
        if (Input.touchCount == 1)
        {
            var touch = Input.GetTouch(0);
            if (touch.phase == TouchPhase.Moved)
            {
                currentScroll = Mathf.Clamp(currentScroll - touch.deltaPosition.y, 0, maxScroll);
                viewer.SetScrollOffset(currentScroll);
            }
        }
    }
}
```

---

# ЧАСТЬ 2: Web/JS+CSS Render Engine

## 2.1. Архитектура Web

```
┌─────────────────────────────────────────────────────────────┐
│  Browser                                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  <div class="comics-viewer">                        │    │
│  │    overflow-y: scroll                               │    │
│  │    ┌─────────────────────────────────────────────┐  │    │
│  │    │  <div class="comics-content">               │  │    │
│  │    │    height: {comics.height}px                │  │    │
│  │    │    ┌─────────────────────────────────────┐  │  │    │
│  │    │    │  <div class="layer" data-index="0"> │  │  │    │
│  │    │    │    transform: translate() rotate()  │  │  │    │
│  │    │    │    scale(); opacity: 0.8;           │  │  │    │
│  │    │    │    ┌───┬───┬───┐                    │  │  │    │
│  │    │    │    │t00│t01│t02│ ← tiles (img)      │  │  │    │
│  │    │    │    ├───┼───┼───┤                    │  │  │    │
│  │    │    │    │t10│t11│t12│                    │  │  │    │
│  │    │    │    └───┴───┴───┘                    │  │  │    │
│  │    │    └─────────────────────────────────────┘  │  │    │
│  │    │    ... more layers ...                      │  │    │
│  │    └─────────────────────────────────────────────┘  │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
        │                              │
        ▼                              ▼
┌───────────────────┐        ┌─────────────────────┐
│  comics-engine.js │        │  ZIP (fflate)       │
│  ~10KB gzipped    │        │  ~8KB gzipped       │
└───────────────────┘        └─────────────────────┘
```

## 2.2. CSS Styles

```css
/* comics-viewer.css */
.comics-viewer {
  width: 100%;
  height: 100vh;
  overflow-y: scroll;
  overflow-x: hidden;
  -webkit-overflow-scrolling: touch;
  scroll-behavior: smooth;
}

.comics-content {
  position: relative;
  width: 100%;
  /* height set by JS based on comics.height * scale */
}

.comics-layer {
  position: absolute;
  top: 0;
  left: 0;
  /* transform set by JS on scroll */
  will-change: transform, opacity;
  transform-origin: top left;
}

.comics-tile {
  position: absolute;
  width: 512px;
  height: 512px;
  background-size: cover;
  /* Lazy loading */
  content-visibility: auto;
}

.comics-tile[data-loaded="false"] {
  background-color: #1a1a1a;
}

/* GPU acceleration */
.comics-layer,
.comics-tile {
  transform: translateZ(0);
  backface-visibility: hidden;
}
```

## 2.3. JavaScript Engine

### comics-engine.js

```javascript
// comics-engine.js (~10KB minified+gzipped)

class ComicsViewer {
  static TILE_SIZE = 512;

  constructor(container, options = {}) {
    this.container = container;
    this.options = {
      languageIndex: 0,
      soundEnabled: true,
      onLoad: null,
      onScroll: null,
      onLayerTap: null,
      onError: null,
      ...options
    };

    this.comics = null;
    this.layers = [];
    this.scale = 1;
    this.archive = null;
    this.tileCache = new Map();
    this.observer = null;

    this._setupDOM();
    this._setupScrollHandler();
  }

  async load(archiveUrl) {
    try {
      // Fetch ZIP
      const response = await fetch(archiveUrl);
      const buffer = await response.arrayBuffer();

      // Parse ZIP with fflate
      this.archive = fflate.unzipSync(new Uint8Array(buffer));

      // Parse data.json
      const dataJson = new TextDecoder().decode(this.archive['data.json']);
      this.comics = JSON.parse(dataJson);

      // Prepare animations
      this._prepareComics();

      // Render initial state
      this._render();

      this.options.onLoad?.(this.comics);
    } catch (err) {
      this.options.onError?.(err.message);
    }
  }

  _setupDOM() {
    this.container.classList.add('comics-viewer');
    this.content = document.createElement('div');
    this.content.className = 'comics-content';
    this.container.appendChild(this.content);
  }

  _setupScrollHandler() {
    let ticking = false;

    this.container.addEventListener('scroll', () => {
      if (!ticking) {
        requestAnimationFrame(() => {
          this._onScroll();
          ticking = false;
        });
        ticking = true;
      }
    }, { passive: true });
  }

  _onScroll() {
    const scrollOffset = Math.round(this.container.scrollTop / this.scale);

    // Process animations
    this._processAnimations(scrollOffset);

    // Update layer transforms
    this._updateLayerTransforms();

    // Load visible tiles
    this._updateVisibleTiles();

    // Notify
    const maxScroll = this.comics.height - (this.container.clientHeight / this.scale);
    this.options.onScroll?.(scrollOffset, Math.round(maxScroll));
  }

  _processAnimations(scrollOffset) {
    for (const layer of this.comics.layers) {
      this._buildMatrixAndAlpha(layer, scrollOffset);
    }
  }

  _buildMatrixAndAlpha(layer, scrollOffset) {
    const img = this._getCurrentImage(layer);
    if (!img) return;

    // Reset
    layer._matrix = { tx: 0, ty: 0, rotate: 0, scaleX: 1, scaleY: 1 };
    layer._alpha = 1;

    // Apply in order: Scale → Rotate → Translate
    this._applyAnims(layer._scales, layer, scrollOffset, img);
    this._applyAnims(layer._rotates, layer, scrollOffset, img);
    this._applyAnims(layer._translates, layer, scrollOffset, img);
    this._applyAnims(layer._alphas, layer, scrollOffset, img);
  }

  _applyAnims(anims, layer, scrollOffset, img) {
    if (!anims || anims.length === 0) return;

    // Find current animation
    let prev = anims[0].type === 'translate' ? { x: 0, y: 0 } :
               anims[0].type === 'rotate' ? { angle: 0, pivotX: 0.5, pivotY: 0.5 } :
               anims[0].type === 'scale' ? { scaleX: 1, scaleY: 1, pivotX: 0.5, pivotY: 0.5 } :
               { alpha: 1 };
    let curr = prev;

    for (const anim of anims) {
      if (scrollOffset < anim.end) {
        curr = anim;
        break;
      }
      prev = anim;
    }

    // Interpolate
    const fraction = this._computeFraction(scrollOffset, curr);
    const eased = this._cubicEase(fraction);

    // Apply based on type
    this._applyInterpolated(layer, prev, curr, eased, img);
  }

  _computeFraction(scrollOffset, anim) {
    const scrollObj = scrollOffset - anim.start;
    const animHeight = anim.end - anim.start;
    if (animHeight === 0) return 1;
    return Math.max(0, Math.min(1, scrollObj / animHeight));
  }

  _cubicEase(f) {
    // (f - 1)³ + 1
    const t = f - 1;
    return t * t * t + 1;
  }

  _updateLayerTransforms() {
    for (let i = 0; i < this.comics.layers.length; i++) {
      const layer = this.comics.layers[i];
      const el = this.layerElements[i];

      if (!el) continue;

      const m = layer._matrix;
      const transform = `translate(${m.tx}px, ${m.ty}px) ` +
                        `rotate(${m.rotate}deg) ` +
                        `scale(${m.scaleX}, ${m.scaleY})`;

      el.style.transform = transform;
      el.style.opacity = layer._alpha;
    }
  }

  _updateVisibleTiles() {
    const viewportTop = this.container.scrollTop / this.scale;
    const viewportHeight = this.container.clientHeight / this.scale;
    const margin = viewportHeight; // Preload 1 screen ahead

    const visibleTop = viewportTop - margin;
    const visibleBottom = viewportTop + viewportHeight + margin;

    for (let i = 0; i < this.comics.layers.length; i++) {
      const layer = this.comics.layers[i];
      const layerEl = this.layerElements[i];
      const img = this._getCurrentImage(layer);

      if (!img || !img.file.includes('{0}')) continue;

      // Check if layer intersects viewport
      const layerBounds = this._getLayerBounds(layer, img);
      if (layerBounds.bottom < visibleTop || layerBounds.top > visibleBottom) {
        // Layer not visible, skip tiles
        continue;
      }

      // Load visible tiles
      this._loadTilesForLayer(i, img, visibleTop, visibleBottom);
    }
  }

  _loadTilesForLayer(layerIndex, img, visibleTop, visibleBottom) {
    const cols = Math.ceil(img.width / ComicsViewer.TILE_SIZE);
    const rows = Math.ceil(img.height / ComicsViewer.TILE_SIZE);

    for (let row = 0; row < rows; row++) {
      const tileTop = row * ComicsViewer.TILE_SIZE;
      const tileBottom = tileTop + ComicsViewer.TILE_SIZE;

      // Check if tile row is visible
      if (tileBottom < visibleTop || tileTop > visibleBottom) continue;

      for (let col = 0; col < cols; col++) {
        const fileName = this._getTileFileName(img.file, 1.0, col, row);

        if (!this.tileCache.has(fileName)) {
          this._loadTile(layerIndex, col, row, fileName);
        }
      }
    }
  }

  _loadTile(layerIndex, col, row, fileName) {
    const layerEl = this.layerElements[layerIndex];
    const tileId = `tile-${layerIndex}-${col}-${row}`;

    let tileEl = layerEl.querySelector(`#${tileId}`);
    if (!tileEl) {
      tileEl = document.createElement('div');
      tileEl.id = tileId;
      tileEl.className = 'comics-tile';
      tileEl.style.left = `${col * ComicsViewer.TILE_SIZE}px`;
      tileEl.style.top = `${row * ComicsViewer.TILE_SIZE}px`;
      tileEl.dataset.loaded = 'false';
      layerEl.appendChild(tileEl);
    }

    // Load from archive
    const filePath = `layers/${fileName}`;
    const bytes = this.archive[filePath];

    if (bytes) {
      const blob = new Blob([bytes], { type: 'image/png' });
      const url = URL.createObjectURL(blob);
      tileEl.style.backgroundImage = `url(${url})`;
      tileEl.dataset.loaded = 'true';
      this.tileCache.set(fileName, url);
    }
  }

  _getTileFileName(template, zoom, col, row) {
    return template
      .replace('{0}', Math.round(zoom * 1000))
      .replace('{1}', col)
      .replace('{2}', row);
  }

  // Hit testing
  hitTest(x, y) {
    // Convert to content coordinates
    const contentX = x / this.scale;
    const contentY = (y + this.container.scrollTop) / this.scale;

    // Test layers back-to-front
    for (let i = this.comics.layers.length - 1; i >= 0; i--) {
      const layer = this.comics.layers[i];
      const img = this._getCurrentImage(layer);
      if (!img) continue;

      // Apply inverse transform and check bounds
      const hit = this._hitTestLayer(layer, img, contentX, contentY);
      if (hit) {
        return { layerIndex: i, popupPath: img.popup, isHit: true };
      }
    }

    return { isHit: false };
  }

  setLanguage(index) {
    this.options.languageIndex = index;
    this._render();
  }

  destroy() {
    // Cleanup
    this.observer?.disconnect();
    this.tileCache.forEach(url => URL.revokeObjectURL(url));
    this.tileCache.clear();
    this.container.innerHTML = '';
  }
}

// Export
if (typeof module !== 'undefined') module.exports = ComicsViewer;
if (typeof window !== 'undefined') window.ComicsViewer = ComicsViewer;
```

## 2.4. HTML Usage

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Comics Viewer</title>
  <link rel="stylesheet" href="comics-viewer.css">
</head>
<body>
  <div id="viewer"></div>

  <script src="https://unpkg.com/fflate@0.8.0/umd/index.js"></script>
  <script src="comics-engine.js"></script>
  <script>
    const viewer = new ComicsViewer(document.getElementById('viewer'), {
      languageIndex: 0,
      soundEnabled: true,
      onLoad: (comics) => console.log('Loaded:', comics.width, 'x', comics.height),
      onScroll: (offset, max) => console.log('Scroll:', offset, '/', max),
      onLayerTap: (index, popup) => console.log('Tap layer:', index),
      onError: (err) => console.error('Error:', err)
    });

    viewer.load('bhagavadgita.comics');
  </script>
</body>
</html>
```

## 2.5. Offline Support (Optional)

```javascript
// sw.js - Service Worker
const CACHE_NAME = 'comics-viewer-v1';
const PRECACHE = [
  '/comics-viewer.css',
  '/comics-engine.js',
  '/fflate.min.js'
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(PRECACHE))
  );
});

self.addEventListener('fetch', e => {
  e.respondWith(
    caches.match(e.request)
      .then(cached => cached || fetch(e.request))
  );
});

// Registration in main.js
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js');
}
```

---

# ЧАСТЬ 3: Общие спецификации

## 3.1. Формат данных (data.json)

```json
{
  "width": 1080,
  "height": 15000,
  "layers": [
    {
      "preview": false,
      "images": [
        {
          "width": 1080,
          "height": 2000,
          "file": "layer0_{0}_{1}_{2}.png",
          "popup": "popup0.png"
        }
      ],
      "animations": [
        { "type": "translate", "start": 0, "end": 500, "x": 0, "y": 100 },
        { "type": "scale", "start": 200, "end": 700, "scaleX": 1.2, "scaleY": 1.2, "pivotX": 0.5, "pivotY": 0.5 },
        { "type": "alpha", "start": 600, "end": 800, "alpha": 0 }
      ]
    }
  ],
  "sounds": [
    {
      "file": "ambient.mp3",
      "animations": [
        { "type": "sound", "start": 0, "end": 1000 }
      ]
    }
  ]
}
```

## 3.2. Константы (инварианты)

| Параметр | Значение | Нельзя менять |
|----------|----------|---------------|
| TILE_SIZE | 512 px | ✓ |
| Tile naming | `{0}_{1}_{2}` | ✓ |
| Zoom * 1000 | `{0}` = 1000 for zoom 1.0 | ✓ |
| Animation order | Scale → Rotate → Translate | ✓ |
| Cubic easing | `(f-1)³ + 1` | ✓ |

## 3.3. Edge Cases

| Case | Trigger | Handling |
|------|---------|----------|
| Missing tile | File not in archive | Show placeholder or skip |
| Invalid JSON | Malformed data.json | Show error, don't crash |
| Large content | height > 50000px | Aggressive tile unloading |
| Memory pressure | Too many tiles | LRU cache eviction |
| Network error (Web) | Failed to fetch ZIP | Show retry option |

## 3.4. Testing Strategy

### Unit Tests

- [ ] Animation interpolation (cubic easing)
- [ ] Tile name generation
- [ ] Matrix composition order
- [ ] Language fallback logic

### Integration Tests

- [ ] Load .comics archive and render
- [ ] Scroll and verify animations
- [ ] Hit test on layers
- [ ] Sound playback triggers

### Visual Tests

- [ ] Compare renders: Unity vs Web vs Native
- [ ] Performance: 60 FPS scroll test

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-05-08
- [x] Notes: Ready for implementation plan
