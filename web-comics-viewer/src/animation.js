/**
 * Animation Processor
 * Handles scroll-driven animation interpolation with cubic easing
 */

export class AnimationProcessor {
  constructor(comics) {
    this.comics = comics;
    this.layerCount = comics.layers.length;
  }

  /**
   * Cubic easing function: (f-1)^3 + 1
   * @param {number} f - Fraction 0..1
   * @returns {number} - Eased value 0..1
   */
  _cubicEase(f) {
    const t = f - 1;
    return t * t * t + 1;
  }

  /**
   * Calculate fraction for animation based on scroll offset
   * @param {object} anim - Animation definition
   * @param {number} scrollY - Current scroll position
   * @returns {number} - Fraction 0..1 (clamped)
   */
  _calculateFraction(anim, scrollY) {
    if (scrollY <= anim.start) return 0;
    if (scrollY >= anim.end) return 1;

    const range = anim.end - anim.start;
    if (range <= 0) return 1;

    const linear = (scrollY - anim.start) / range;
    return this._cubicEase(linear);
  }

  /**
   * Interpolate between two values
   * @param {number} from - Start value
   * @param {number} to - End value
   * @param {number} fraction - Interpolation fraction 0..1
   * @returns {number} - Interpolated value
   */
  _lerp(from, to, fraction) {
    return from + (to - from) * fraction;
  }

  /**
   * Process all layer animations for current scroll offset
   * @param {number} scrollY - Current scroll position
   * @returns {Array} - Array of transform objects per layer
   */
  process(scrollY) {
    const transforms = [];

    for (let i = 0; i < this.layerCount; i++) {
      const layer = this.comics.layers[i];
      const transform = {
        translateX: 0,
        translateY: 0,
        scaleX: 1,
        scaleY: 1,
        rotation: 0,
        alpha: layer.alpha !== undefined ? layer.alpha : 1
      };

      // Process each animation for this layer
      for (const anim of layer.animations) {
        const fraction = this._calculateFraction(anim, scrollY);

        switch (anim.type) {
          case 'translate':
            transform.translateX += this._lerp(anim.fromX, anim.toX, fraction);
            transform.translateY += this._lerp(anim.fromY, anim.toY, fraction);
            break;

          case 'rotate':
            transform.rotation += this._lerp(anim.from, anim.to, fraction);
            break;

          case 'scale':
            // Multiplicative scaling
            transform.scaleX *= this._lerp(anim.fromX, anim.toX, fraction);
            transform.scaleY *= this._lerp(anim.fromY, anim.toY, fraction);
            break;

          case 'alpha':
            transform.alpha *= this._lerp(anim.from, anim.to, fraction);
            break;
        }
      }

      // Clamp alpha
      transform.alpha = Math.max(0, Math.min(1, transform.alpha));

      transforms.push(transform);
    }

    return transforms;
  }
}

export default AnimationProcessor;
