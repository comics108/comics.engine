/**
 * Sound Manager
 * Handles sound playback based on scroll position
 */

export class SoundManager {
  constructor(archive, comics, enabled = true) {
    this.archive = archive;
    this.comics = comics;
    this.enabled = enabled;

    this.audioContext = null;
    this.audioBuffers = new Map();
    this.activeSources = new Map();
    this.playedOneShots = new Set();
    this.lastScrollY = 0;

    this._initAudioContext();
  }

  _initAudioContext() {
    // Lazy init on first user interaction
    if (typeof window !== 'undefined') {
      const initOnInteraction = () => {
        if (!this.audioContext) {
          this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
        }
        document.removeEventListener('click', initOnInteraction);
        document.removeEventListener('touchstart', initOnInteraction);
      };

      document.addEventListener('click', initOnInteraction);
      document.addEventListener('touchstart', initOnInteraction);
    }
  }

  async _loadSound(src) {
    if (this.audioBuffers.has(src)) {
      return this.audioBuffers.get(src);
    }

    const soundPath = `sounds/${src}`;
    const data = this.archive[soundPath];

    if (!data) {
      console.warn(`Sound not found: ${soundPath}`);
      return null;
    }

    if (!this.audioContext) {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
    }

    try {
      const audioBuffer = await this.audioContext.decodeAudioData(data.buffer.slice(0));
      this.audioBuffers.set(src, audioBuffer);
      return audioBuffer;
    } catch (e) {
      console.error(`Failed to decode audio: ${src}`, e);
      return null;
    }
  }

  async _playSound(sound) {
    if (!this.enabled || !this.audioContext) return;

    const buffer = await this._loadSound(sound.src);
    if (!buffer) return;

    // Resume audio context if suspended
    if (this.audioContext.state === 'suspended') {
      await this.audioContext.resume();
    }

    const source = this.audioContext.createBufferSource();
    source.buffer = buffer;

    // Apply volume
    const gainNode = this.audioContext.createGain();
    gainNode.gain.value = sound.volume;

    source.connect(gainNode);
    gainNode.connect(this.audioContext.destination);

    source.loop = sound.loop || false;
    source.start(0);

    // Track active sources for looping sounds
    if (sound.loop) {
      this.activeSources.set(sound.src, { source, gainNode });
    }

    source.onended = () => {
      if (!sound.loop) {
        // Allow replay on scroll back
        // this.playedOneShots.delete(sound.src);
      }
    };
  }

  _stopSound(src) {
    const active = this.activeSources.get(src);
    if (active) {
      try {
        active.source.stop();
      } catch (e) {
        // Already stopped
      }
      this.activeSources.delete(src);
    }
  }

  /**
   * Process sounds based on scroll position
   * @param {number} scrollY - Current scroll position
   */
  process(scrollY) {
    if (!this.enabled || !this.comics.sounds) return;

    const scrollingDown = scrollY > this.lastScrollY;
    this.lastScrollY = scrollY;

    for (const sound of this.comics.sounds) {
      if (sound.type === 'point') {
        // One-shot sound at specific scroll position
        if (scrollingDown &&
            scrollY >= sound.start &&
            !this.playedOneShots.has(sound.src)) {
          this.playedOneShots.add(sound.src);
          this._playSound(sound);
        }
      } else if (sound.type === 'range') {
        // Range sound - play while in range
        const inRange = scrollY >= sound.start &&
                       (sound.end === null || scrollY <= sound.end);
        const isPlaying = this.activeSources.has(sound.src);

        if (inRange && !isPlaying) {
          this._playSound({ ...sound, loop: true });
        } else if (!inRange && isPlaying) {
          this._stopSound(sound.src);
        }
      }
    }
  }

  setEnabled(enabled) {
    this.enabled = enabled;

    if (!enabled) {
      // Stop all active sounds
      this.activeSources.forEach((_, src) => this._stopSound(src));
    }
  }

  pause() {
    this.audioContext?.suspend();
  }

  resume() {
    this.audioContext?.resume();
  }

  destroy() {
    this.activeSources.forEach((_, src) => this._stopSound(src));
    this.audioBuffers.clear();
    this.playedOneShots.clear();

    if (this.audioContext) {
      this.audioContext.close();
      this.audioContext = null;
    }
  }
}

export default SoundManager;
