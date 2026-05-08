# Specifications: Comics Engine Shared Core

> Version: 1.0
> Status: DRAFT
> Last Updated: 2026-05-08

## Overview

This specification defines the abstraction layer that enables comics.engine to work with both archive (runtime) and folder (editor) sources while maintaining invariants.

---

## 1. Invariants (Unchanged)

| Parameter | Value |
|-----------|-------|
| TILE_SIZE | 512 px |
| Tile naming | `{zoom*1000}_{col}_{row}` |
| Transform order | Scale → Rotate → Translate |
| Easing | `(f-1)³ + 1` |

---

## 2. IComicsSource Interface

```csharp
namespace Comics.Engine.Core
{
    /// <summary>
    /// Abstraction for loading comics data from various sources.
    /// </summary>
    public interface IComicsSource : IDisposable
    {
        /// <summary>
        /// Loads and parses data.json into Comics model.
        /// </summary>
        Comics LoadData();

        /// <summary>
        /// Loads a tile texture by path (relative to layers/).
        /// Format: "layers/{layerIndex}/{zoom*1000}_{col}_{row}.png"
        /// </summary>
        Texture2D LoadTile(string relativePath);

        /// <summary>
        /// Loads audio clip by path (relative to sounds/).
        /// Format: "sounds/{filename}.mp3"
        /// </summary>
        AudioClip LoadSound(string relativePath);

        /// <summary>
        /// Whether source supports modification (editor) or read-only (runtime).
        /// </summary>
        bool IsReadOnly { get; }

        /// <summary>
        /// Invalidate cached data (called when editor modifies files).
        /// </summary>
        void Invalidate();
    }
}
```

---

## 3. Source Implementations

### 3.1 ZipArchiveSource (Runtime)

```csharp
namespace Comics.Engine.IO
{
    /// <summary>
    /// Loads comics from .comics/.puzzle ZIP archive.
    /// Used at runtime in standalone builds.
    /// </summary>
    public class ZipArchiveSource : IComicsSource
    {
        private readonly string _archivePath;
        private readonly string _extractPath;
        private Comics _cachedData;

        public bool IsReadOnly => true;

        public ZipArchiveSource(string archivePath)
        {
            _archivePath = archivePath;
            _extractPath = Path.Combine(
                Application.temporaryCachePath,
                "comics_" + Path.GetFileNameWithoutExtension(archivePath)
            );
        }

        public void Extract()
        {
            if (!Directory.Exists(_extractPath))
                ZipFile.ExtractToDirectory(_archivePath, _extractPath);
        }

        public Comics LoadData()
        {
            if (_cachedData != null) return _cachedData;

            var jsonPath = Path.Combine(_extractPath, "data.json");
            var json = File.ReadAllText(jsonPath);
            _cachedData = ComicsParser.Parse(json);
            return _cachedData;
        }

        public Texture2D LoadTile(string relativePath)
        {
            var fullPath = Path.Combine(_extractPath, relativePath);
            var bytes = File.ReadAllBytes(fullPath);
            var tex = new Texture2D(2, 2);
            tex.LoadImage(bytes);
            return tex;
        }

        public AudioClip LoadSound(string relativePath)
        {
            // Implementation via UnityWebRequest for .mp3
            // ...
        }

        public void Invalidate()
        {
            // Runtime source: no-op (read-only)
        }

        public void Dispose()
        {
            // Cleanup extracted files if desired
            if (Directory.Exists(_extractPath))
                Directory.Delete(_extractPath, recursive: true);
        }
    }
}
```

### 3.2 FolderSource (Editor)

```csharp
namespace Comics.Engine.IO
{
    /// <summary>
    /// Loads comics from unpacked folder (editor temp workspace).
    /// Supports invalidation when files change during editing.
    /// </summary>
    public class FolderSource : IComicsSource
    {
        private readonly string _folderPath;
        private Comics _cachedData;
        private bool _isDirty = true;

        public bool IsReadOnly => false;

        public FolderSource(string folderPath)
        {
            _folderPath = folderPath;
        }

        public Comics LoadData()
        {
            if (_cachedData != null && !_isDirty)
                return _cachedData;

            var jsonPath = Path.Combine(_folderPath, "data.json");
            var json = File.ReadAllText(jsonPath);
            _cachedData = ComicsParser.Parse(json);
            _isDirty = false;
            return _cachedData;
        }

        public Texture2D LoadTile(string relativePath)
        {
            var fullPath = Path.Combine(_folderPath, relativePath);

            // In Editor: prefer AssetDatabase if inside Assets/
            #if UNITY_EDITOR
            if (fullPath.StartsWith(Application.dataPath))
            {
                var assetPath = "Assets" + fullPath.Substring(Application.dataPath.Length);
                return UnityEditor.AssetDatabase.LoadAssetAtPath<Texture2D>(assetPath);
            }
            #endif

            // Fallback: load from disk
            var bytes = File.ReadAllBytes(fullPath);
            var tex = new Texture2D(2, 2);
            tex.LoadImage(bytes);
            return tex;
        }

        public AudioClip LoadSound(string relativePath)
        {
            // Editor audio loading
            // ...
        }

        public void Invalidate()
        {
            _isDirty = true;
            _cachedData = null;
        }

        public void Dispose()
        {
            // Don't delete editor workspace
        }
    }
}
```

---

## 4. Refactored ComicsViewer

```csharp
namespace Comics.Engine
{
    /// <summary>
    /// Main viewer component. Source-agnostic.
    /// </summary>
    public class ComicsViewer : MonoBehaviour
    {
        private IComicsSource _source;
        private Comics _comics;
        private AnimationProcessor _animationProcessor;
        private TileRenderer _tileRenderer;
        private SoundManager _soundManager;

        /// <summary>
        /// Initialize with archive source (runtime).
        /// </summary>
        public void LoadArchive(string archivePath)
        {
            var source = new ZipArchiveSource(archivePath);
            source.Extract();
            Initialize(source);
        }

        /// <summary>
        /// Initialize with folder source (editor).
        /// </summary>
        public void LoadFolder(string folderPath)
        {
            var source = new FolderSource(folderPath);
            Initialize(source);
        }

        /// <summary>
        /// Initialize with any source (for dependency injection).
        /// </summary>
        public void Initialize(IComicsSource source)
        {
            _source?.Dispose();
            _source = source;

            _comics = _source.LoadData();
            _comics.Prepare();

            _animationProcessor = new AnimationProcessor(_comics);
            _tileRenderer = new TileRenderer(_comics, _source, _contentRoot, _languageIndex);

            if (!_source.IsReadOnly)
            {
                // Editor mode: no automatic sound
                _soundManager = null;
            }
            else
            {
                _soundManager = new SoundManager(_source, _comics, _soundEnabled);
            }
        }

        /// <summary>
        /// Called when editor modifies document.
        /// </summary>
        public void RefreshFromSource()
        {
            _source.Invalidate();
            _comics = _source.LoadData();
            _comics.Prepare();
            _animationProcessor = new AnimationProcessor(_comics);
            // Keep TileRenderer, just invalidate cache
            _tileRenderer.InvalidateCache();
        }
    }
}
```

---

## 5. TileRenderer Updates

```csharp
namespace Comics.Engine.Rendering
{
    public class TileRenderer
    {
        private readonly IComicsSource _source;
        private readonly TileCache _cache;

        public TileRenderer(Comics comics, IComicsSource source, Transform root, int languageIndex)
        {
            _source = source;
            _cache = new TileCache();
            // ...
        }

        public void LoadTile(int layerIndex, int zoom, int col, int row)
        {
            var path = $"layers/{layerIndex}/{(int)(zoom * 1000)}_{col}_{row}.png";

            if (_cache.Has(path)) return;

            var texture = _source.LoadTile(path);
            _cache.Add(path, texture);
            // Apply to quad...
        }

        public void InvalidateCache()
        {
            _cache.Clear();
        }
    }
}
```

---

## 6. Assembly Structure

```
unity_comics.engine/
├── Runtime/
│   ├── Comics.Engine.asmdef
│   ├── Core/
│   │   ├── IComicsSource.cs
│   │   ├── AnimationProcessor.cs
│   │   └── ComicsCore.cs (shared logic)
│   ├── IO/
│   │   ├── ZipArchiveSource.cs
│   │   ├── FolderSource.cs
│   │   └── ComicsParser.cs
│   ├── Rendering/
│   │   ├── TileRenderer.cs
│   │   └── TileCache.cs
│   ├── Audio/
│   │   └── SoundManager.cs
│   └── ComicsViewer.cs
└── Editor/
    └── Comics.Engine.Editor.asmdef (references Runtime)
```

---

## 7. Editor Integration Pattern

```csharp
// In comics.editor:
public class ComicsEditorWindow : EditorWindow
{
    private ComicsViewer _previewViewer;
    private FolderSource _folderSource;
    private string _tempFolderPath;

    private void OnEnable()
    {
        // Create preview viewer (hidden, for rendering only)
        var go = new GameObject("PreviewViewer", typeof(ComicsViewer));
        go.hideFlags = HideFlags.HideAndDontSave;
        _previewViewer = go.GetComponent<ComicsViewer>();
    }

    private void LoadDocument(string path)
    {
        // Unpack to temp
        _tempFolderPath = ExtractToTemp(path);

        // Initialize viewer with folder source
        _previewViewer.LoadFolder(_tempFolderPath);
    }

    private void OnLayerModified()
    {
        // Save data.json
        SaveDataJson();

        // Refresh preview
        _previewViewer.RefreshFromSource();
    }

    private void RenderPreview(Rect previewRect)
    {
        // Use viewer's rendered output for IMGUI preview
        var transforms = _previewViewer.GetLayerTransforms(_scrollPosition);
        // Apply to preview canvas...
    }
}
```

---

## 8. Migration Path

1. **Extract interface**: Create `IComicsSource` from `ZipArchiveProvider` API
2. **Rename**: `ZipArchiveProvider` → `ZipArchiveSource`, implement interface
3. **Create**: `FolderSource` implementation
4. **Refactor**: `ComicsViewer.LoadArchive()` to use new source
5. **Add**: `ComicsViewer.LoadFolder()` for editor
6. **Test**: Both paths produce identical rendering

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-05-08
- [ ] Notes: -
