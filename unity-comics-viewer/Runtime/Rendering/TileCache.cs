using System.Collections.Generic;
using UnityEngine;

namespace NativeMind.ComicsViewer.Rendering
{
    /// <summary>
    /// LRU cache for tile textures
    /// </summary>
    public class TileCache
    {
        private readonly int _maxSize;
        private readonly Dictionary<string, CacheEntry> _cache;
        private readonly LinkedList<string> _lruList;

        private class CacheEntry
        {
            public Texture2D Texture;
            public LinkedListNode<string> LruNode;
        }

        public TileCache(int maxSize = 100)
        {
            _maxSize = maxSize;
            _cache = new Dictionary<string, CacheEntry>(maxSize);
            _lruList = new LinkedList<string>();
        }

        public Texture2D Get(string key)
        {
            if (_cache.TryGetValue(key, out var entry))
            {
                // Move to front of LRU
                _lruList.Remove(entry.LruNode);
                _lruList.AddFirst(entry.LruNode);
                return entry.Texture;
            }

            return null;
        }

        public void Put(string key, Texture2D texture)
        {
            if (_cache.ContainsKey(key))
            {
                // Update existing
                var entry = _cache[key];
                Object.Destroy(entry.Texture);
                entry.Texture = texture;

                _lruList.Remove(entry.LruNode);
                _lruList.AddFirst(entry.LruNode);
                return;
            }

            // Evict if necessary
            while (_cache.Count >= _maxSize && _lruList.Count > 0)
            {
                var oldest = _lruList.Last.Value;
                _lruList.RemoveLast();

                if (_cache.TryGetValue(oldest, out var oldEntry))
                {
                    Object.Destroy(oldEntry.Texture);
                    _cache.Remove(oldest);
                }
            }

            // Add new entry
            var node = _lruList.AddFirst(key);
            _cache[key] = new CacheEntry
            {
                Texture = texture,
                LruNode = node
            };
        }

        public void Remove(string key)
        {
            if (_cache.TryGetValue(key, out var entry))
            {
                _lruList.Remove(entry.LruNode);
                Object.Destroy(entry.Texture);
                _cache.Remove(key);
            }
        }

        public void Clear()
        {
            foreach (var entry in _cache.Values)
            {
                Object.Destroy(entry.Texture);
            }
            _cache.Clear();
            _lruList.Clear();
        }

        public int Count => _cache.Count;
    }
}
