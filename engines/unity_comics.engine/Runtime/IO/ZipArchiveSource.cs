using System;
using System.IO;
using System.IO.Compression;
using UnityEngine;
using NativeMind.ComicsViewer.Core;

namespace NativeMind.ComicsViewer.IO
{
    /// <summary>
    /// Loads comics from .comics/.puzzle ZIP archive.
    /// Used at runtime in standalone builds.
    /// </summary>
    public class ZipArchiveSource : IComicsSource
    {
        private readonly string _archivePath;
        private readonly string _extractPath;
        private bool _isExtracted;

        public string BasePath => _extractPath;
        public bool IsReady => _isExtracted;
        public bool IsReadOnly => true;

        public ZipArchiveSource(string archivePath)
        {
            _archivePath = archivePath;

            // Extract to persistent data path
            string fileName = Path.GetFileNameWithoutExtension(archivePath);
            _extractPath = Path.Combine(Application.persistentDataPath, "comics_cache", fileName);
        }

        /// <summary>
        /// Extract archive if not already extracted
        /// </summary>
        public void Prepare(bool force = false)
        {
            if (_isExtracted && !force)
            {
                return;
            }

            if (Directory.Exists(_extractPath))
            {
                if (force)
                {
                    Directory.Delete(_extractPath, true);
                }
                else
                {
                    _isExtracted = true;
                    return;
                }
            }

            Directory.CreateDirectory(_extractPath);
            ZipFile.ExtractToDirectory(_archivePath, _extractPath);
            _isExtracted = true;
        }

        /// <summary>
        /// Read data.json as string
        /// </summary>
        public string ReadDataJson()
        {
            EnsureReady();
            string dataPath = Path.Combine(_extractPath, "data.json");
            return File.ReadAllText(dataPath);
        }

        /// <summary>
        /// Get full path to a tile image
        /// </summary>
        public string GetTilePath(string baseSrc, int col, int row, int zoom = 1000)
        {
            EnsureReady();
            string tileName = $"{zoom}_{col}_{row}.jpg";
            string tilePath = Path.Combine(_extractPath, baseSrc, tileName);

            if (File.Exists(tilePath))
            {
                return tilePath;
            }

            // Try PNG fallback
            tilePath = Path.Combine(_extractPath, baseSrc, $"{zoom}_{col}_{row}.png");
            return File.Exists(tilePath) ? tilePath : null;
        }

        /// <summary>
        /// Get full path to a sound file
        /// </summary>
        public string GetSoundPath(string soundSrc)
        {
            EnsureReady();
            return Path.Combine(_extractPath, "sounds", soundSrc);
        }

        /// <summary>
        /// Load texture from extracted tile
        /// </summary>
        public Texture2D LoadTileTexture(string tilePath)
        {
            if (string.IsNullOrEmpty(tilePath) || !File.Exists(tilePath))
            {
                return null;
            }

            byte[] fileData = File.ReadAllBytes(tilePath);
            Texture2D texture = new Texture2D(512, 512, TextureFormat.RGB24, false);
            texture.LoadImage(fileData);
            texture.wrapMode = TextureWrapMode.Clamp;
            return texture;
        }

        /// <summary>
        /// List all files in a directory within the archive
        /// </summary>
        public string[] ListDirectory(string subPath)
        {
            EnsureReady();
            string fullPath = Path.Combine(_extractPath, subPath);

            if (Directory.Exists(fullPath))
            {
                return Directory.GetFiles(fullPath);
            }

            return Array.Empty<string>();
        }

        /// <summary>
        /// Invalidate cached data - no-op for read-only source
        /// </summary>
        public void Invalidate()
        {
            // Runtime source: no-op (read-only)
        }

        /// <summary>
        /// Clean up extracted files
        /// </summary>
        public void Dispose()
        {
            // Keep extracted files cached for performance
            // Use ClearCache() to explicitly delete
        }

        /// <summary>
        /// Delete cache for this archive
        /// </summary>
        public void ClearCache()
        {
            if (Directory.Exists(_extractPath))
            {
                Directory.Delete(_extractPath, true);
            }
            _isExtracted = false;
        }

        private void EnsureReady()
        {
            if (!_isExtracted)
            {
                Prepare();
            }
        }
    }
}
