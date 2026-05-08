using System.Collections.Generic;
using UnityEngine;
using NativeMind.ComicsViewer.Models;
using NativeMind.ComicsViewer.Core;

namespace NativeMind.ComicsViewer.Rendering
{
    /// <summary>
    /// Renders tiled layers with viewport culling
    /// </summary>
    public class TileRenderer
    {
        public const int TILE_SIZE = 512;
        private const float PRELOAD_MARGIN = 512f;

        private readonly Comics _comics;
        private readonly IComicsSource _source;
        private readonly TileCache _cache;
        private readonly Transform _parent;
        private readonly int _languageIndex;

        private readonly List<LayerRenderer> _layerRenderers;

        public TileRenderer(Comics comics, IComicsSource source, Transform parent, int languageIndex = 0)
        {
            _comics = comics;
            _source = source;
            _parent = parent;
            _languageIndex = languageIndex;
            _cache = new TileCache(150);
            _layerRenderers = new List<LayerRenderer>();

            CreateLayers();
        }

        private void CreateLayers()
        {
            for (int i = 0; i < _comics.layers.Count; i++)
            {
                var layer = _comics.layers[i];
                var layerRenderer = new LayerRenderer(layer, _source, _cache, _parent, i, _languageIndex);
                _layerRenderers.Add(layerRenderer);
            }
        }

        /// <summary>
        /// Invalidate tile cache - called when editor modifies files
        /// </summary>
        public void InvalidateCache()
        {
            _cache.Clear();
            foreach (var renderer in _layerRenderers)
            {
                renderer.ClearTiles();
            }
        }

        /// <summary>
        /// Update visible tiles based on viewport
        /// </summary>
        public void UpdateViewport(float scrollY, float viewportHeight)
        {
            float viewTop = scrollY - PRELOAD_MARGIN;
            float viewBottom = scrollY + viewportHeight + PRELOAD_MARGIN;

            foreach (var renderer in _layerRenderers)
            {
                renderer.UpdateVisibility(viewTop, viewBottom);
            }
        }

        /// <summary>
        /// Apply transforms to layers
        /// </summary>
        public void ApplyTransforms(Core.LayerTransform[] transforms)
        {
            for (int i = 0; i < transforms.Length && i < _layerRenderers.Count; i++)
            {
                _layerRenderers[i].ApplyTransform(transforms[i]);
            }
        }

        public void SetLanguageIndex(int index)
        {
            foreach (var renderer in _layerRenderers)
            {
                renderer.SetLanguageIndex(index);
            }
        }

        public void Dispose()
        {
            foreach (var renderer in _layerRenderers)
            {
                renderer.Dispose();
            }
            _layerRenderers.Clear();
            _cache.Clear();
        }
    }

    /// <summary>
    /// Renders a single layer with its tiles
    /// </summary>
    internal class LayerRenderer
    {
        private readonly Layer _layer;
        private readonly IComicsSource _source;
        private readonly TileCache _cache;
        private readonly GameObject _layerObject;
        private readonly Dictionary<string, GameObject> _tileObjects;
        private int _languageIndex;

        private readonly int _cols;
        private readonly int _rows;

        public LayerRenderer(Layer layer, IComicsSource source, TileCache cache, Transform parent, int sortOrder, int languageIndex)
        {
            _layer = layer;
            _source = source;
            _cache = cache;
            _languageIndex = languageIndex;
            _tileObjects = new Dictionary<string, GameObject>();

            _cols = Mathf.CeilToInt((float)layer.width / TileRenderer.TILE_SIZE);
            _rows = Mathf.CeilToInt((float)layer.height / TileRenderer.TILE_SIZE);

            // Create layer container
            _layerObject = new GameObject($"Layer_{layer.id ?? sortOrder.ToString()}");
            _layerObject.transform.SetParent(parent, false);
            _layerObject.transform.localPosition = new Vector3(layer.x, -layer.y, -sortOrder * 0.01f);
        }

        public void UpdateVisibility(float viewTop, float viewBottom)
        {
            float layerTop = _layer.y;
            float layerBottom = _layer.y + _layer.height;

            // Skip if layer completely outside viewport
            if (layerBottom < viewTop || layerTop > viewBottom)
            {
                HideAllTiles();
                return;
            }

            // Check each tile
            for (int row = 0; row < _rows; row++)
            {
                float tileTop = _layer.y + row * TileRenderer.TILE_SIZE;
                float tileBottom = tileTop + TileRenderer.TILE_SIZE;

                bool inView = tileBottom >= viewTop && tileTop <= viewBottom;

                for (int col = 0; col < _cols; col++)
                {
                    string key = GetTileKey(col, row);

                    if (inView)
                    {
                        EnsureTileLoaded(col, row, key);
                    }
                    else
                    {
                        HideTile(key);
                    }
                }
            }
        }

        private void EnsureTileLoaded(int col, int row, string key)
        {
            if (_tileObjects.ContainsKey(key))
            {
                _tileObjects[key].SetActive(true);
                return;
            }

            // Get image source
            string imageSrc = GetImageSrc();
            if (string.IsNullOrEmpty(imageSrc)) return;

            string tilePath = _source.GetTilePath(imageSrc, col, row);
            if (tilePath == null) return;

            // Load or get from cache
            Texture2D texture = _cache.Get(key);
            if (texture == null)
            {
                texture = _source.LoadTileTexture(tilePath);
                if (texture != null)
                {
                    _cache.Put(key, texture);
                }
            }

            if (texture == null) return;

            // Create tile quad
            var tileObj = GameObject.CreatePrimitive(PrimitiveType.Quad);
            tileObj.name = $"Tile_{col}_{row}";
            tileObj.transform.SetParent(_layerObject.transform, false);

            // Position tile (Unity Y is up, comics Y is down)
            tileObj.transform.localPosition = new Vector3(
                col * TileRenderer.TILE_SIZE + TileRenderer.TILE_SIZE / 2f,
                -(row * TileRenderer.TILE_SIZE + TileRenderer.TILE_SIZE / 2f),
                0
            );
            tileObj.transform.localScale = new Vector3(TileRenderer.TILE_SIZE, TileRenderer.TILE_SIZE, 1);

            // Set material
            var renderer = tileObj.GetComponent<MeshRenderer>();
            renderer.material = new Material(Shader.Find("Unlit/Transparent"));
            renderer.material.mainTexture = texture;

            // Remove collider
            Object.Destroy(tileObj.GetComponent<Collider>());

            _tileObjects[key] = tileObj;
        }

        private void HideTile(string key)
        {
            if (_tileObjects.TryGetValue(key, out var tileObj))
            {
                tileObj.SetActive(false);
            }
        }

        private void HideAllTiles()
        {
            foreach (var tileObj in _tileObjects.Values)
            {
                tileObj.SetActive(false);
            }
        }

        private string GetTileKey(int col, int row)
        {
            return $"{_layer.id}_{_languageIndex}_{col}_{row}";
        }

        private string GetImageSrc()
        {
            if (_layer.images == null || _layer.images.Count == 0)
                return null;

            // Find localized image
            foreach (var img in _layer.images)
            {
                if (img.locale == _languageIndex.ToString())
                    return img.src;
            }

            // Fallback to first image
            return _layer.images[0].src;
        }

        public void ApplyTransform(Core.LayerTransform transform)
        {
            // Apply translation
            var pos = _layerObject.transform.localPosition;
            pos.x = _layer.x + transform.translation.x;
            pos.y = -(_layer.y + transform.translation.y);
            _layerObject.transform.localPosition = pos;

            // Apply scale
            _layerObject.transform.localScale = new Vector3(
                transform.scale.x,
                transform.scale.y,
                1f
            );

            // Apply rotation
            _layerObject.transform.localRotation = Quaternion.Euler(0, 0, -transform.rotation);

            // Apply alpha (to all tile materials)
            foreach (var tileObj in _tileObjects.Values)
            {
                var renderer = tileObj.GetComponent<MeshRenderer>();
                if (renderer != null && renderer.material != null)
                {
                    var color = renderer.material.color;
                    color.a = transform.alpha;
                    renderer.material.color = color;
                }
            }
        }

        public void SetLanguageIndex(int index)
        {
            if (_languageIndex == index) return;
            _languageIndex = index;
            ClearTiles();
        }

        /// <summary>
        /// Clear all tiles - called on language change or cache invalidation
        /// </summary>
        public void ClearTiles()
        {
            foreach (var tileObj in _tileObjects.Values)
            {
                Object.Destroy(tileObj);
            }
            _tileObjects.Clear();
        }

        public void Dispose()
        {
            foreach (var tileObj in _tileObjects.Values)
            {
                Object.Destroy(tileObj);
            }
            _tileObjects.Clear();
            Object.Destroy(_layerObject);
        }
    }
}
