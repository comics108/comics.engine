using System;
using UnityEngine;

namespace NativeMind.ComicsViewer.Models
{
    /// <summary>
    /// Base animation class with cubic easing
    /// </summary>
    [Serializable]
    public class Anim
    {
        public string type;
        public float start;
        public float end;

        /// <summary>
        /// Cubic easing function: (f-1)^3 + 1
        /// </summary>
        protected float CubicEase(float fraction)
        {
            float f = fraction - 1f;
            return f * f * f + 1f;
        }

        /// <summary>
        /// Calculate interpolation fraction based on scroll offset
        /// </summary>
        public float GetFraction(float scrollOffset)
        {
            if (scrollOffset <= start) return 0f;
            if (scrollOffset >= end) return 1f;

            float range = end - start;
            if (range <= 0f) return 1f;

            float linear = (scrollOffset - start) / range;
            return CubicEase(linear);
        }

        /// <summary>
        /// Linear interpolation helper
        /// </summary>
        protected float Lerp(float from, float to, float fraction)
        {
            return from + (to - from) * fraction;
        }
    }

    /// <summary>
    /// Translate animation
    /// </summary>
    [Serializable]
    public class TranslateAnim : Anim
    {
        public float fromX;
        public float fromY;
        public float toX;
        public float toY;

        public TranslateAnim()
        {
            type = "translate";
        }

        public Vector2 GetValue(float scrollOffset)
        {
            float f = GetFraction(scrollOffset);
            return new Vector2(
                Lerp(fromX, toX, f),
                Lerp(fromY, toY, f)
            );
        }
    }

    /// <summary>
    /// Rotate animation
    /// </summary>
    [Serializable]
    public class RotateAnim : Anim
    {
        public float from;
        public float to;
        public float pivotX;
        public float pivotY;

        public RotateAnim()
        {
            type = "rotate";
        }

        public float GetValue(float scrollOffset)
        {
            float f = GetFraction(scrollOffset);
            return Lerp(from, to, f);
        }

        public Vector2 GetPivot()
        {
            return new Vector2(pivotX, pivotY);
        }
    }

    /// <summary>
    /// Scale animation
    /// </summary>
    [Serializable]
    public class ScaleAnim : Anim
    {
        public float fromX = 1f;
        public float fromY = 1f;
        public float toX = 1f;
        public float toY = 1f;
        public float pivotX;
        public float pivotY;

        public ScaleAnim()
        {
            type = "scale";
        }

        public Vector2 GetValue(float scrollOffset)
        {
            float f = GetFraction(scrollOffset);
            return new Vector2(
                Lerp(fromX, toX, f),
                Lerp(fromY, toY, f)
            );
        }

        public Vector2 GetPivot()
        {
            return new Vector2(pivotX, pivotY);
        }
    }

    /// <summary>
    /// Alpha (opacity) animation
    /// </summary>
    [Serializable]
    public class AlphaAnim : Anim
    {
        public float from = 1f;
        public float to = 1f;

        public AlphaAnim()
        {
            type = "alpha";
        }

        public float GetValue(float scrollOffset)
        {
            float f = GetFraction(scrollOffset);
            return Mathf.Clamp01(Lerp(from, to, f));
        }
    }
}
