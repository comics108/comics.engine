using System;
using System.IO;
using UnityEngine;
using NativeMind.ComicsViewer.Core;

namespace NativeMind.ComicsViewer.IO
{
    /// <summary>
    /// Loads comics from unpacked folder (editor temp workspace).
    /// Supports invalidation when files change during editing.
    /// </summary>
    public class FolderSource : IComicsSource
    {
        private readonly string _folderPath;
        private bool _isDirty = true;
        private string _cachedDataJson;

        public string BasePath => _folderPath;
        public bool IsReady => Directory.Exists(_folderPath);
        public bool IsReadOnly => false;

        public FolderSource(string folderPath)
        {
            _folderPath = folderPath;
        }

        /// <summary>
        /// Prepare source - just verify folder exists
        /// </summary>
        public void Prepare(bool force = false)
        {
            if (force)
            {
                _isDirty = true;
                _cachedDataJson = null;
            }

            if (!Directory.Exists(_folderPath))
            {
                throw new DirectoryNotFoundException($"Comics folder not found: {_folderPath}");
            }
        }

        /// <summary>
        /// Read data.json as string
        /// </summary>
        public string ReadDataJson()
        {
            if (_cachedDataJson != null && !_isDirty)
            {
                return _cachedDataJson;
            }

            string dataPath = Path.Combine(_folderPath, "data.json");
            _cachedDataJson = File.ReadAllText(dataPath);
            _isDirty = false;
            return _cachedDataJson;
        }

        /// <summary>
        /// Get full path to a tile image
        /// </summary>
        public string GetTilePath(string baseSrc, int col, int row, int zoom = 1000)
        {
            string tileName = $"{zoom}_{col}_{row}.jpg";
            string tilePath = Path.Combine(_folderPath, baseSrc, tileName);

            if (File.Exists(tilePath))
            {
                return tilePath;
            }

            // Try PNG fallback
            tilePath = Path.Combine(_folderPath, baseSrc, $"{zoom}_{col}_{row}.png");
            return File.Exists(tilePath) ? tilePath : null;
        }

        /// <summary>
        /// Get full path to a sound file
        /// </summary>
        public string GetSoundPath(string soundSrc)
        {
            return Path.Combine(_folderPath, "sounds", soundSrc);
        }

        /// <summary>
        /// Load texture from tile path
        /// </summary>
        public Texture2D LoadTileTexture(string tilePath)
        {
            if (string.IsNullOrEmpty(tilePath) || !File.Exists(tilePath))
            {
                return null;
            }

            #if UNITY_EDITOR
            // In Editor: try AssetDatabase first if inside Assets/
            if (tilePath.StartsWith(Application.dataPath))
            {
                string assetPath = "Assets" + tilePath.Substring(Application.dataPath.Length);
                var tex = UnityEditor.AssetDatabase.LoadAssetAtPath<Texture2D>(assetPath);
                if (tex != null)
                {
                    return tex;
                }
            }
            #endif

            // Fallback: load from disk
            byte[] fileData = File.ReadAllBytes(tilePath);
            Texture2D texture = new Texture2D(512, 512, TextureFormat.RGB24, false);
            texture.LoadImage(fileData);
            texture.wrapMode = TextureWrapMode.Clamp;
            return texture;
        }

        /// <summary>
        /// List all files in a directory
        /// </summary>
        public string[] ListDirectory(string subPath)
        {
            string fullPath = Path.Combine(_folderPath, subPath);

            if (Directory.Exists(fullPath))
            {
                return Directory.GetFiles(fullPath);
            }

            return Array.Empty<string>();
        }

        /// <summary>
        /// Invalidate cached data - called when editor modifies files
        /// </summary>
        public void Invalidate()
        {
            _isDirty = true;
            _cachedDataJson = null;
        }

        /// <summary>
        /// Clean up - don't delete editor workspace
        /// </summary>
        public void Dispose()
        {
            // Don't delete editor workspace folder
            _cachedDataJson = null;
        }

        /// <summary>
        /// Clear cache - just invalidate
        /// </summary>
        public void ClearCache()
        {
            Invalidate();
        }
    }
}
