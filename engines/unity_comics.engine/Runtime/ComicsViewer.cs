using System;
using UnityEngine;
using NativeMind.ComicsViewer.Models;
using NativeMind.ComicsViewer.Core;
using NativeMind.ComicsViewer.IO;
using NativeMind.ComicsViewer.Rendering;
using NativeMind.ComicsViewer.Audio;

// Backwards compatibility alias
using ZipArchiveProvider = NativeMind.ComicsViewer.IO.ZipArchiveSource;

namespace NativeMind.ComicsViewer
{
    /// <summary>
    /// Information about loaded comics
    /// </summary>
    public struct ComicsInfo
    {
        public int Width;
        public int Height;
        public int LayerCount;
        public bool HasSound;
    }

    /// <summary>
    /// Main comics viewer component
    /// Attach to a GameObject with Camera child for WorldSpace rendering
    /// </summary>
    public class ComicsViewer : MonoBehaviour
    {
        [Header("Configuration")]
        [Tooltip("Path to .comics archive file")]
        public string archivePath;

        [Tooltip("Language index for localized content")]
        [Range(0, 10)]
        public int languageIndex = 0;

        [Tooltip("Enable sound playback")]
        public bool soundEnabled = true;

        [Header("Scroll Settings")]
        [Tooltip("Scroll speed multiplier")]
        public float scrollSpeed = 1f;

        [Tooltip("Enable scroll momentum")]
        public bool enableMomentum = true;

        [Tooltip("Momentum friction")]
        [Range(0.9f, 0.99f)]
        public float momentumFriction = 0.95f;

        // Events
        public event Action<ComicsInfo> OnLoaded;
        public event Action<float, float> OnScroll; // scrollY, maxScroll
        public event Action<string> OnError;

        // Private state
        private Comics _comics;
        private IComicsSource _source;
        private AnimationProcessor _animationProcessor;
        private TileRenderer _tileRenderer;
        private SoundManager _soundManager;

        private Transform _contentRoot;
        private Camera _viewCamera;

        private float _scrollY;
        private float _maxScroll;
        private float _velocity;
        private bool _isDragging;
        private float _lastDragY;
        private float _viewportHeight;

        public float ScrollOffset => _scrollY;
        public float MaxScrollOffset => _maxScroll;
        public bool IsLoaded => _comics != null;

        private void Awake()
        {
            // Create content root
            _contentRoot = new GameObject("ComicsContent").transform;
            _contentRoot.SetParent(transform, false);

            // Find or create camera
            _viewCamera = GetComponentInChildren<Camera>();
            if (_viewCamera == null)
            {
                var camObj = new GameObject("ViewCamera");
                camObj.transform.SetParent(transform, false);
                _viewCamera = camObj.AddComponent<Camera>();
                _viewCamera.orthographic = true;
                _viewCamera.clearFlags = CameraClearFlags.SolidColor;
                _viewCamera.backgroundColor = Color.black;
            }
        }

        private void Start()
        {
            if (!string.IsNullOrEmpty(archivePath))
            {
                LoadArchive(archivePath);
            }
        }

        /// <summary>
        /// Load comics from archive path
        /// </summary>
        public void LoadArchive(string path)
        {
            archivePath = path;
            var source = new ZipArchiveSource(path);
            source.Prepare();
            Initialize(source);
        }

        /// <summary>
        /// Load comics from unpacked folder (for editor preview)
        /// </summary>
        public void LoadFolder(string folderPath)
        {
            var source = new FolderSource(folderPath);
            source.Prepare();
            Initialize(source);
        }

        /// <summary>
        /// Initialize with any source (for dependency injection)
        /// </summary>
        public void Initialize(IComicsSource source)
        {
            try
            {
                // Cleanup previous
                Unload();

                _source = source;

                // Parse data.json
                string jsonString = _source.ReadDataJson();
                _comics = ComicsParser.Parse(jsonString);

                // Setup camera for content size
                SetupCamera();

                // Initialize systems
                _animationProcessor = new AnimationProcessor(_comics);
                _tileRenderer = new TileRenderer(_comics, _source, _contentRoot, languageIndex);

                // Sound manager only for read-only sources (runtime)
                // Editor can enable separately if needed
                if (_source.IsReadOnly)
                {
                    _soundManager = new SoundManager(_source, _comics, soundEnabled);
                }

                // Calculate scroll bounds
                _maxScroll = Mathf.Max(0, _comics.height - _viewportHeight);

                // Initial render
                UpdateViewport();

                // Notify loaded
                OnLoaded?.Invoke(new ComicsInfo
                {
                    Width = _comics.width,
                    Height = _comics.height,
                    LayerCount = _comics.layers.Count,
                    HasSound = _comics.sounds?.Count > 0
                });
            }
            catch (Exception e)
            {
                Debug.LogError($"Failed to load comics: {e.Message}");
                OnError?.Invoke(e.Message);
            }
        }

        /// <summary>
        /// Refresh from source after editor modifies document
        /// </summary>
        public void RefreshFromSource()
        {
            if (_source == null) return;

            try
            {
                _source.Invalidate();

                // Reload data
                string jsonString = _source.ReadDataJson();
                _comics = ComicsParser.Parse(jsonString);

                // Recreate animation processor
                _animationProcessor = new AnimationProcessor(_comics);

                // Invalidate tile cache
                _tileRenderer?.InvalidateCache();

                // Recalculate bounds
                _maxScroll = Mathf.Max(0, _comics.height - _viewportHeight);

                // Re-render
                UpdateViewport();
            }
            catch (Exception e)
            {
                Debug.LogError($"Failed to refresh comics: {e.Message}");
                OnError?.Invoke(e.Message);
            }
        }

        private void SetupCamera()
        {
            // Position camera at content center
            _viewCamera.transform.localPosition = new Vector3(
                _comics.width / 2f,
                0,
                -10
            );

            // Calculate orthographic size based on screen
            float screenAspect = (float)Screen.width / Screen.height;
            float comicsAspect = (float)_comics.width / _comics.height;

            if (screenAspect > comicsAspect)
            {
                // Screen is wider - fit to height
                _viewCamera.orthographicSize = Screen.height / 2f;
            }
            else
            {
                // Screen is taller - fit to width
                _viewCamera.orthographicSize = _comics.width / (2f * screenAspect);
            }

            _viewportHeight = _viewCamera.orthographicSize * 2f;
        }

        private void Update()
        {
            if (_comics == null) return;

            HandleInput();
            UpdateMomentum();
            UpdateViewport();
        }

        private void HandleInput()
        {
            // Mouse/touch drag
            if (Input.GetMouseButtonDown(0))
            {
                _isDragging = true;
                _lastDragY = Input.mousePosition.y;
                _velocity = 0;
            }
            else if (Input.GetMouseButtonUp(0))
            {
                _isDragging = false;
            }

            if (_isDragging)
            {
                float deltaY = _lastDragY - Input.mousePosition.y;
                float scrollDelta = deltaY * scrollSpeed;

                _velocity = scrollDelta;
                SetScrollOffset(_scrollY + scrollDelta);

                _lastDragY = Input.mousePosition.y;
            }

            // Mouse wheel
            float scroll = Input.mouseScrollDelta.y;
            if (Mathf.Abs(scroll) > 0.01f)
            {
                SetScrollOffset(_scrollY - scroll * 100 * scrollSpeed);
            }
        }

        private void UpdateMomentum()
        {
            if (!enableMomentum || _isDragging) return;

            if (Mathf.Abs(_velocity) > 0.1f)
            {
                SetScrollOffset(_scrollY + _velocity);
                _velocity *= momentumFriction;
            }
            else
            {
                _velocity = 0;
            }
        }

        private void UpdateViewport()
        {
            if (_tileRenderer == null) return;

            // Update camera position for scroll
            var camPos = _viewCamera.transform.localPosition;
            camPos.y = -_scrollY - _viewportHeight / 2f;
            _viewCamera.transform.localPosition = camPos;

            // Update tile visibility
            _tileRenderer.UpdateViewport(_scrollY, _viewportHeight);

            // Process animations
            var transforms = _animationProcessor.Process(_scrollY);
            _tileRenderer.ApplyTransforms(transforms);

            // Process sounds
            _soundManager?.Process(_scrollY);
        }

        /// <summary>
        /// Set scroll offset programmatically
        /// </summary>
        public void SetScrollOffset(float offset)
        {
            float newScroll = Mathf.Clamp(offset, 0, _maxScroll);

            if (Mathf.Abs(newScroll - _scrollY) > 0.01f)
            {
                _scrollY = newScroll;
                OnScroll?.Invoke(_scrollY, _maxScroll);
            }
        }

        /// <summary>
        /// Set language index for localized content
        /// </summary>
        public void SetLanguageIndex(int index)
        {
            languageIndex = index;
            _tileRenderer?.SetLanguageIndex(index);
        }

        /// <summary>
        /// Enable or disable sound
        /// </summary>
        public void SetSoundEnabled(bool enabled)
        {
            soundEnabled = enabled;
            _soundManager?.SetEnabled(enabled);
        }

        /// <summary>
        /// Pause all sounds
        /// </summary>
        public void PauseSounds()
        {
            _soundManager?.Pause();
        }

        /// <summary>
        /// Resume sounds
        /// </summary>
        public void ResumeSounds()
        {
            _soundManager?.Resume();
        }

        /// <summary>
        /// Unload current comics
        /// </summary>
        public void Unload()
        {
            _soundManager?.Dispose();
            _soundManager = null;

            _tileRenderer?.Dispose();
            _tileRenderer = null;

            _animationProcessor = null;

            _source?.Dispose();
            _source = null;

            _comics = null;
            _scrollY = 0;
            _maxScroll = 0;
        }

        /// <summary>
        /// Get the current comics source (for advanced usage)
        /// </summary>
        public IComicsSource Source => _source;

        private void OnDestroy()
        {
            Unload();
        }

        private void OnApplicationPause(bool pause)
        {
            if (pause)
            {
                PauseSounds();
            }
            else
            {
                ResumeSounds();
            }
        }
    }
}
