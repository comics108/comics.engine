/**
 * Tile Loader
 * Lazy loading of tiles with viewport culling
 */

export class TileLoader {
  static TILE_SIZE = 512;
  static PRELOAD_MARGIN = 512; // Preload one tile ahead

  constructor(archive, comics, languageIndex = 0) {
    this.archive = archive;
    this.comics = comics;
    this.languageIndex = languageIndex;
    this.tileElements = new Map(); // Map of layerIndex -> tile elements
    this.loadedTiles = new Set();
    this.blobUrls = new Map(); // Cache blob URLs
  }

  /**
   * Create tile elements for a layer
   * @param {HTMLElement} layerEl - Layer container element
   * @param {object} layer - Layer data
   * @param {number} layerIndex - Layer index
   */
  createTileElements(layerEl, layer, layerIndex) {
    const cols = Math.ceil(layer.width / TileLoader.TILE_SIZE);
    const rows = Math.ceil(layer.height / TileLoader.TILE_SIZE);
    const tiles = [];

    for (let row = 0; row < rows; row++) {
      for (let col = 0; col < cols; col++) {
        const tileEl = document.createElement('div');
        tileEl.className = 'comics-tile loading';
        tileEl.style.left = `${col * TileLoader.TILE_SIZE}px`;
        tileEl.style.top = `${row * TileLoader.TILE_SIZE}px`;

        tileEl.dataset.col = col;
        tileEl.dataset.row = row;
        tileEl.dataset.layerIndex = layerIndex;

        layerEl.appendChild(tileEl);
        tiles.push({ element: tileEl, col, row });
      }
    }

    this.tileElements.set(layerIndex, tiles);
  }

  /**
   * Get tile image path from layer
   * @param {object} layer - Layer data
   * @returns {string} - Image source path
   */
  _getImageSrc(layer) {
    const images = layer.images;
    if (!images || images.length === 0) return null;

    // Try to find localized image
    const localizedImage = images.find(img =>
      img.locale === this.languageIndex ||
      img.locale === String(this.languageIndex)
    );

    if (localizedImage) return localizedImage.src;

    // Fallback to first image
    return images[0].src;
  }

  /**
   * Build tile filename
   * @param {string} baseSrc - Base image source (e.g., "layers/layer1")
   * @param {number} col - Column index
   * @param {number} row - Row index
   * @param {number} zoom - Zoom level (default 1000 = 1x)
   * @returns {string} - Full tile path
   */
  _getTilePath(baseSrc, col, row, zoom = 1000) {
    // Format: {src}/{zoom}_{col}_{row}.jpg
    return `${baseSrc}/${zoom}_${col}_${row}.jpg`;
  }

  /**
   * Load a tile image from archive
   * @param {HTMLElement} tileEl - Tile element
   * @param {object} layer - Layer data
   * @param {number} col - Column
   * @param {number} row - Row
   */
  async _loadTile(tileEl, layer, col, row) {
    const tileKey = `${tileEl.dataset.layerIndex}_${col}_${row}`;

    if (this.loadedTiles.has(tileKey)) return;

    const baseSrc = this._getImageSrc(layer);
    if (!baseSrc) return;

    const tilePath = this._getTilePath(baseSrc, col, row);
    const tileData = this.archive[tilePath];

    if (!tileData) {
      // Try PNG fallback
      const pngPath = tilePath.replace('.jpg', '.png');
      const pngData = this.archive[pngPath];
      if (!pngData) {
        tileEl.classList.remove('loading');
        return;
      }
      this._setTileImage(tileEl, pngData, 'image/png', tileKey);
      return;
    }

    this._setTileImage(tileEl, tileData, 'image/jpeg', tileKey);
  }

  _setTileImage(tileEl, data, mimeType, tileKey) {
    // Create blob URL
    const blob = new Blob([data], { type: mimeType });
    const url = URL.createObjectURL(blob);
    this.blobUrls.set(tileKey, url);

    tileEl.style.backgroundImage = `url(${url})`;
    tileEl.classList.remove('loading');
    tileEl.classList.add('loaded');
    this.loadedTiles.add(tileKey);
  }

  /**
   * Update visible tiles based on viewport
   * @param {number} scrollY - Current scroll position
   * @param {number} viewportHeight - Viewport height
   */
  updateViewport(scrollY, viewportHeight) {
    const viewTop = scrollY - TileLoader.PRELOAD_MARGIN;
    const viewBottom = scrollY + viewportHeight + TileLoader.PRELOAD_MARGIN;

    this.tileElements.forEach((tiles, layerIndex) => {
      const layer = this.comics.layers[layerIndex];
      const layerTop = layer.y;
      const layerBottom = layer.y + layer.height;

      // Skip if layer is completely outside viewport
      if (layerBottom < viewTop || layerTop > viewBottom) {
        return;
      }

      tiles.forEach(({ element, col, row }) => {
        const tileTop = layerTop + row * TileLoader.TILE_SIZE;
        const tileBottom = tileTop + TileLoader.TILE_SIZE;

        // Check if tile is in viewport
        if (tileBottom >= viewTop && tileTop <= viewBottom) {
          this._loadTile(element, layer, col, row);
        }
      });
    });
  }

  setLanguageIndex(index) {
    if (this.languageIndex === index) return;

    this.languageIndex = index;

    // Clear and reload all tiles
    this.loadedTiles.clear();
    this.blobUrls.forEach(url => URL.revokeObjectURL(url));
    this.blobUrls.clear();

    this.tileElements.forEach((tiles) => {
      tiles.forEach(({ element }) => {
        element.style.backgroundImage = '';
        element.classList.add('loading');
        element.classList.remove('loaded');
      });
    });
  }

  destroy() {
    // Revoke all blob URLs
    this.blobUrls.forEach(url => URL.revokeObjectURL(url));
    this.blobUrls.clear();
    this.loadedTiles.clear();
    this.tileElements.clear();
  }
}

export default TileLoader;
