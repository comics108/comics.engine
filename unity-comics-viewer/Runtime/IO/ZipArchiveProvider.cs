using System;
using System.IO;
using System.IO.Compression;
using System.Collections.Generic;
using UnityEngine;

namespace NativeMind.ComicsViewer.IO
{
    /// <summary>
    /// Provides access to .comics archive (ZIP) contents
    /// </summary>
    public class ZipArchiveProvider : IDisposable
    {
        private readonly string _archivePath;
        private readonly string _extractPath;
        private bool _isExtracted;

        public string ExtractPath => _extractPath;
        public bool IsExtracted => _isExtracted;

        public ZipArchiveProvider(string archivePath)
        {
            _archivePath = archivePath;

            // Extract to persistent data path
            string fileName = Path.GetFileNameWithoutExtension(archivePath);
            _extractPath = Path.Combine(Application.persistentDataPath, "comics_cache", fileName);
        }

        /// <summary>
        /// Extract archive if not already extracted
        /// </summary>
        public void Extract(bool force = false)
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
            EnsureExtracted();
            string dataPath = Path.Combine(_extractPath, "data.json");
            return File.ReadAllText(dataPath);
        }

        /// <summary>
        /// Get full path to a tile image
        /// </summary>
        public string GetTilePath(string baseSrc, int col, int row, int zoom = 1000)
        {
            EnsureExtracted();
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
            EnsureExtracted();
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
            EnsureExtracted();
            string fullPath = Path.Combine(_extractPath, subPath);

            if (Directory.Exists(fullPath))
            {
                return Directory.GetFiles(fullPath);
            }

            return Array.Empty<string>();
        }

        private void EnsureExtracted()
        {
            if (!_isExtracted)
            {
                Extract();
            }
        }

        /// <summary>
        /// Clean up extracted files
        /// </summary>
        public void Dispose()
        {
            // Optionally delete extracted files
            // Keep them cached for performance
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
    }
}
