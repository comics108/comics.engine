using System.Collections.Generic;
using UnityEngine;
using NativeMind.ComicsViewer.Models;

namespace NativeMind.ComicsViewer.Core
{
    /// <summary>
    /// Computed transform state for a layer
    /// </summary>
    public struct LayerTransform
    {
        public Vector2 translation;
        public Vector2 scale;
        public float rotation;
        public float alpha;
        public Vector2 pivot;

        public static LayerTransform Identity => new LayerTransform
        {
            translation = Vector2.zero,
            scale = Vector2.one,
            rotation = 0f,
            alpha = 1f,
            pivot = Vector2.zero
        };
    }

    /// <summary>
    /// Processes scroll-driven animations for all layers
    /// </summary>
    public class AnimationProcessor
    {
        private readonly Comics _comics;
        private readonly LayerTransform[] _transforms;

        public AnimationProcessor(Comics comics)
        {
            _comics = comics;
            _transforms = new LayerTransform[comics.layers.Count];
        }

        /// <summary>
        /// Process all animations for current scroll offset
        /// </summary>
        /// <param name="scrollOffset">Current scroll Y position</param>
        /// <returns>Array of transforms for each layer</returns>
        public LayerTransform[] Process(float scrollOffset)
        {
            for (int i = 0; i < _comics.layers.Count; i++)
            {
                _transforms[i] = ProcessLayer(_comics.layers[i], scrollOffset);
            }

            return _transforms;
        }

        private LayerTransform ProcessLayer(Layer layer, float scrollOffset)
        {
            var transform = new LayerTransform
            {
                translation = Vector2.zero,
                scale = Vector2.one,
                rotation = 0f,
                alpha = layer.alpha,
                pivot = Vector2.zero
            };

            foreach (var anim in layer.anim)
            {
                ProcessAnimation(anim, scrollOffset, ref transform);
            }

            // Clamp alpha
            transform.alpha = Mathf.Clamp01(transform.alpha);

            return transform;
        }

        private void ProcessAnimation(Anim anim, float scrollOffset, ref LayerTransform transform)
        {
            switch (anim)
            {
                case TranslateAnim translate:
                    var t = translate.GetValue(scrollOffset);
                    transform.translation += t;
                    break;

                case RotateAnim rotate:
                    transform.rotation += rotate.GetValue(scrollOffset);
                    transform.pivot = rotate.GetPivot();
                    break;

                case ScaleAnim scale:
                    var s = scale.GetValue(scrollOffset);
                    transform.scale = new Vector2(
                        transform.scale.x * s.x,
                        transform.scale.y * s.y
                    );
                    transform.pivot = scale.GetPivot();
                    break;

                case AlphaAnim alpha:
                    transform.alpha *= alpha.GetValue(scrollOffset);
                    break;
            }
        }
    }
}
