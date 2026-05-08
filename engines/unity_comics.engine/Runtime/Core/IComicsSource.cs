using System;
using UnityEngine;
using NativeMind.ComicsViewer.Models;

namespace NativeMind.ComicsViewer.Core
{
    /// <summary>
    /// Abstraction for loading comics data from various sources.
    /// Implemented by ZipArchiveSource (runtime) and FolderSource (editor).
    /// </summary>
    public interface IComicsSource : IDisposable
    {
        /// <summary>
        /// Root path where data is located (extracted archive or folder).
        /// </summary>
        string BasePath { get; }

        /// <summary>
        /// Whether source is extracted and ready for use.
        /// </summary>
        bool IsReady { get; }

        /// <summary>
        /// Whether source supports modification (editor) or read-only (runtime).
        /// </summary>
        bool IsReadOnly { get; }

        /// <summary>
        /// Prepare source for reading (extract archive if needed).
        /// </summary>
        void Prepare(bool force = false);

        /// <summary>
        /// Read and parse data.json into Comics model.
        /// </summary>
        string ReadDataJson();

        /// <summary>
        /// Get full path to a tile image.
        /// Returns null if tile doesn't exist.
        /// </summary>
        /// <param name="baseSrc">Base path (e.g., "layers/0")</param>
        /// <param name="col">Column index</param>
        /// <param name="row">Row index</param>
        /// <param name="zoom">Zoom level (default 1000 = 100%)</param>
        string GetTilePath(string baseSrc, int col, int row, int zoom = 1000);

        /// <summary>
        /// Get full path to a sound file.
        /// </summary>
        /// <param name="soundSrc">Sound filename</param>
        string GetSoundPath(string soundSrc);

        /// <summary>
        /// Load texture from tile path.
        /// </summary>
        Texture2D LoadTileTexture(string tilePath);

        /// <summary>
        /// List files in a subdirectory.
        /// </summary>
        string[] ListDirectory(string subPath);

        /// <summary>
        /// Invalidate cached data (called when editor modifies files).
        /// No-op for read-only sources.
        /// </summary>
        void Invalidate();

        /// <summary>
        /// Clear all cached/extracted data.
        /// </summary>
        void ClearCache();
    }
}
