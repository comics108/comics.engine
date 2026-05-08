using System;
using System.Collections.Generic;
using UnityEngine;
using NativeMind.ComicsViewer.Models;
using NativeMind.ComicsViewer.Core;

namespace NativeMind.ComicsViewer.Audio
{
    /// <summary>
    /// Manages scroll-triggered sound playback
    /// </summary>
    public class SoundManager : IDisposable
    {
        private readonly IComicsSource _source;
        private readonly Comics _comics;
        private readonly GameObject _audioRoot;
        private readonly Dictionary<string, AudioSource> _audioSources;
        private readonly Dictionary<string, AudioClip> _audioClips;
        private readonly HashSet<string> _playedOneShots;

        private bool _enabled;
        private float _lastScrollY;

        public SoundManager(IComicsSource source, Comics comics, bool enabled = true)
        {
            _source = source;
            _comics = comics;
            _enabled = enabled;

            _audioRoot = new GameObject("SoundManager");
            _audioSources = new Dictionary<string, AudioSource>();
            _audioClips = new Dictionary<string, AudioClip>();
            _playedOneShots = new HashSet<string>();

            PreloadSounds();
        }

        private void PreloadSounds()
        {
            if (_comics.sounds == null) return;

            foreach (var sound in _comics.sounds)
            {
                LoadSound(sound.src);
            }
        }

        private AudioClip LoadSound(string src)
        {
            if (_audioClips.TryGetValue(src, out var cachedClip))
            {
                return cachedClip;
            }

            string soundPath = _source.GetSoundPath(src);
            if (string.IsNullOrEmpty(soundPath) || !System.IO.File.Exists(soundPath))
            {
                Debug.LogWarning($"Sound not found: {src}");
                return null;
            }

            // Load audio file
            // Note: For production, use proper async loading with UnityWebRequest
            var audioData = System.IO.File.ReadAllBytes(soundPath);
            var clip = CreateAudioClipFromWav(audioData, src);

            if (clip != null)
            {
                _audioClips[src] = clip;
            }

            return clip;
        }

        private AudioClip CreateAudioClipFromWav(byte[] data, string name)
        {
            // Simple WAV parser - for production use a proper audio library
            try
            {
                // Skip WAV header (44 bytes for standard WAV)
                int headerSize = 44;
                int sampleCount = (data.Length - headerSize) / 2;

                // Assume 16-bit, mono, 44100 Hz
                var clip = AudioClip.Create(name, sampleCount, 1, 44100, false);

                float[] samples = new float[sampleCount];
                for (int i = 0; i < sampleCount; i++)
                {
                    int offset = headerSize + i * 2;
                    if (offset + 1 < data.Length)
                    {
                        short sample = (short)(data[offset] | (data[offset + 1] << 8));
                        samples[i] = sample / 32768f;
                    }
                }

                clip.SetData(samples, 0);
                return clip;
            }
            catch (Exception e)
            {
                Debug.LogError($"Failed to parse audio: {name} - {e.Message}");
                return null;
            }
        }

        private AudioSource GetOrCreateSource(string src)
        {
            if (_audioSources.TryGetValue(src, out var source))
            {
                return source;
            }

            var clip = LoadSound(src);
            if (clip == null) return null;

            source = _audioRoot.AddComponent<AudioSource>();
            source.clip = clip;
            source.playOnAwake = false;

            _audioSources[src] = source;
            return source;
        }

        /// <summary>
        /// Process sounds based on scroll position
        /// </summary>
        public void Process(float scrollY)
        {
            if (!_enabled || _comics.sounds == null) return;

            bool scrollingDown = scrollY > _lastScrollY;
            _lastScrollY = scrollY;

            foreach (var sound in _comics.sounds)
            {
                ProcessSound(sound, scrollY, scrollingDown);
            }
        }

        private void ProcessSound(Sound sound, float scrollY, bool scrollingDown)
        {
            var source = GetOrCreateSource(sound.src);
            if (source == null) return;

            source.volume = sound.volume;

            if (sound.type == "point")
            {
                // One-shot at specific scroll position
                if (scrollingDown &&
                    scrollY >= sound.start &&
                    !_playedOneShots.Contains(sound.src))
                {
                    _playedOneShots.Add(sound.src);
                    source.loop = false;
                    source.Play();
                }
            }
            else if (sound.type == "range")
            {
                // Play while in range
                bool inRange = scrollY >= sound.start &&
                              (sound.end < 0 || scrollY <= sound.end);

                if (inRange && !source.isPlaying)
                {
                    source.loop = sound.loop;
                    source.Play();
                }
                else if (!inRange && source.isPlaying)
                {
                    source.Stop();
                }
            }
        }

        public void SetEnabled(bool enabled)
        {
            _enabled = enabled;

            if (!enabled)
            {
                StopAll();
            }
        }

        public void Pause()
        {
            foreach (var source in _audioSources.Values)
            {
                if (source.isPlaying)
                {
                    source.Pause();
                }
            }
        }

        public void Resume()
        {
            foreach (var source in _audioSources.Values)
            {
                source.UnPause();
            }
        }

        public void StopAll()
        {
            foreach (var source in _audioSources.Values)
            {
                source.Stop();
            }
        }

        public void Dispose()
        {
            StopAll();

            foreach (var clip in _audioClips.Values)
            {
                if (clip != null)
                {
                    UnityEngine.Object.Destroy(clip);
                }
            }

            _audioClips.Clear();
            _audioSources.Clear();

            if (_audioRoot != null)
            {
                UnityEngine.Object.Destroy(_audioRoot);
            }
        }
    }
}
