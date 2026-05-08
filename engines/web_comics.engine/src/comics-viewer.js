/**
 * Comics Viewer - Main Entry Point
 * Render engine for interactive .comics archives with scroll-driven animations
 */

import { parseComicsData } from './models.js';
import { AnimationProcessor } from './animation.js';
import { TileLoader } from './tile-loader.js';
import { SoundManager } from './sound-manager.js';

export class ComicsViewer {
  static TILE_SIZE = 512;

  constructor(container, options = {}) {
    this.container = container;
    this.options = {
      languageIndex: 0,
      soundEnabled: true,
      onLoad: null,
      onScroll: null,
      onError: null,
      onLayerTap: null,
      ...options
    };

    this.comics = null;
    this.archive = null;
    this.animationProcessor = null;
    this.tileLoader = null;
    this.soundManager = null;
    this.contentElement = null;
    this.layerElements = [];
    this.currentScroll = 0;

    this._setupContainer();
    this._bindEvents();
  }

  _setupContainer() {
    this.container.classList.add('comics-viewer');
    this.contentElement = document.createElement('div');
    this.contentElement.className = 'comics-content';
    this.container.appendChild(this.contentElement);
  }

  _bindEvents() {
    this.container.addEventListener('scroll', this._onScroll.bind(this), { passive: true });
  }

  async load(archiveUrl) {
    try {
      // Dynamic import of fflate for ZIP parsing
      const { unzipSync } = await import('https://cdn.jsdelivr.net/npm/fflate@0.8.2/+esm');

      const response = await fetch(archiveUrl);
      if (!response.ok) {
        throw new Error(`Failed to fetch: ${response.status}`);
      }

      const buffer = await response.arrayBuffer();
      this.archive = unzipSync(new Uint8Array(buffer));

      // Parse data.json
      const dataJson = this.archive['data.json'];
      if (!dataJson) {
        throw new Error('data.json not found in archive');
      }

      const jsonString = new TextDecoder().decode(dataJson);
      this.comics = parseComicsData(JSON.parse(jsonString));

      // Initialize subsystems
      this.animationProcessor = new AnimationProcessor(this.comics);
      this.tileLoader = new TileLoader(this.archive, this.comics, this.options.languageIndex);
      this.soundManager = new SoundManager(this.archive, this.comics, this.options.soundEnabled);

      // Setup content
      this._setupContent();

      // Notify loaded
      if (this.options.onLoad) {
        this.options.onLoad({
          width: this.comics.width,
          height: this.comics.height,
          layerCount: this.comics.layers.length,
          hasSound: this.comics.sounds && this.comics.sounds.length > 0
        });
      }

      // Initial render
      this._onScroll();

    } catch (error) {
      console.error('ComicsViewer load error:', error);
      if (this.options.onError) {
        this.options.onError(error.message);
      }
      throw error;
    }
  }

  _setupContent() {
    const { width, height, layers } = this.comics;

    // Set content size
    this.contentElement.style.width = `${width}px`;
    this.contentElement.style.height = `${height}px`;

    // Create layer elements (bottom to top)
    layers.forEach((layer, index) => {
      const layerEl = document.createElement('div');
      layerEl.className = 'comics-layer';
      layerEl.dataset.layerId = layer.id || index;
      layerEl.style.width = `${layer.width}px`;
      layerEl.style.height = `${layer.height}px`;
      layerEl.style.left = `${layer.x}px`;
      layerEl.style.top = `${layer.y}px`;

      // Create tile grid
      this.tileLoader.createTileElements(layerEl, layer, index);

      this.contentElement.appendChild(layerEl);
      this.layerElements.push(layerEl);
    });
  }

  _onScroll() {
    const scrollY = this.container.scrollTop;
    const maxScroll = this.contentElement.offsetHeight - this.container.offsetHeight;
    this.currentScroll = scrollY;

    // Process animations
    if (this.animationProcessor) {
      const transforms = this.animationProcessor.process(scrollY);
      this._applyTransforms(transforms);
    }

    // Update tiles visibility
    if (this.tileLoader) {
      this.tileLoader.updateViewport(scrollY, this.container.offsetHeight);
    }

    // Process sounds
    if (this.soundManager) {
      this.soundManager.process(scrollY);
    }

    // Notify callback
    if (this.options.onScroll) {
      this.options.onScroll(scrollY, maxScroll);
    }
  }

  _applyTransforms(transforms) {
    transforms.forEach((transform, index) => {
      const layerEl = this.layerElements[index];
      if (!layerEl) return;

      const { translateX, translateY, scaleX, scaleY, rotation, alpha } = transform;

      // Build transform string: Scale -> Rotate -> Translate
      const transformStr = `translate(${translateX}px, ${translateY}px) rotate(${rotation}deg) scale(${scaleX}, ${scaleY})`;

      layerEl.style.transform = transformStr;
      layerEl.style.opacity = alpha;
    });
  }

  setScrollOffset(offset) {
    this.container.scrollTop = offset;
  }

  getScrollOffset() {
    return this.container.scrollTop;
  }

  setLanguageIndex(index) {
    this.options.languageIndex = index;
    if (this.tileLoader) {
      this.tileLoader.setLanguageIndex(index);
    }
  }

  setSoundEnabled(enabled) {
    this.options.soundEnabled = enabled;
    if (this.soundManager) {
      this.soundManager.setEnabled(enabled);
    }
  }

  pauseSounds() {
    this.soundManager?.pause();
  }

  resumeSounds() {
    this.soundManager?.resume();
  }

  destroy() {
    this.soundManager?.destroy();
    this.tileLoader?.destroy();
    this.container.innerHTML = '';
    this.comics = null;
    this.archive = null;
  }
}

export default ComicsViewer;
