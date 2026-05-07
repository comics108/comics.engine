using System;
using System.Collections.Generic;
using UnityEngine;
using NativeMind.ComicsViewer.Models;

namespace NativeMind.ComicsViewer.IO
{
    /// <summary>
    /// Parses data.json into Comics model
    /// Uses Unity's JsonUtility with custom handling for polymorphic animations
    /// </summary>
    public static class ComicsParser
    {
        /// <summary>
        /// Parse JSON string to Comics object
        /// </summary>
        public static Comics Parse(string jsonString)
        {
            // Parse with Unity's JsonUtility
            var rawData = JsonUtility.FromJson<RawComicsData>(jsonString);

            var comics = new Comics
            {
                width = rawData.width,
                height = rawData.height
            };

            // Parse layers
            if (rawData.layers != null)
            {
                foreach (var rawLayer in rawData.layers)
                {
                    var layer = ParseLayer(rawLayer);
                    comics.layers.Add(layer);
                }
            }

            // Parse sounds
            if (rawData.sounds != null)
            {
                foreach (var rawSound in rawData.sounds)
                {
                    comics.sounds.Add(rawSound);
                }
            }

            return comics;
        }

        private static Layer ParseLayer(RawLayerData rawLayer)
        {
            var layer = new Layer
            {
                id = rawLayer.id,
                x = rawLayer.x,
                y = rawLayer.y,
                width = rawLayer.width,
                height = rawLayer.height,
                alpha = rawLayer.alpha
            };

            if (rawLayer.images != null)
            {
                layer.images.AddRange(rawLayer.images);
            }

            if (rawLayer.anim != null)
            {
                foreach (var rawAnim in rawLayer.anim)
                {
                    var anim = ParseAnimation(rawAnim);
                    if (anim != null)
                    {
                        layer.anim.Add(anim);
                    }
                }
            }

            return layer;
        }

        private static Anim ParseAnimation(RawAnimData rawAnim)
        {
            switch (rawAnim.type)
            {
                case "translate":
                    return new TranslateAnim
                    {
                        start = rawAnim.start,
                        end = rawAnim.end,
                        fromX = rawAnim.fromX,
                        fromY = rawAnim.fromY,
                        toX = rawAnim.toX,
                        toY = rawAnim.toY
                    };

                case "rotate":
                    return new RotateAnim
                    {
                        start = rawAnim.start,
                        end = rawAnim.end,
                        from = rawAnim.from,
                        to = rawAnim.to,
                        pivotX = rawAnim.pivotX,
                        pivotY = rawAnim.pivotY
                    };

                case "scale":
                    return new ScaleAnim
                    {
                        start = rawAnim.start,
                        end = rawAnim.end,
                        fromX = rawAnim.fromX != 0 ? rawAnim.fromX : 1f,
                        fromY = rawAnim.fromY != 0 ? rawAnim.fromY : 1f,
                        toX = rawAnim.toX != 0 ? rawAnim.toX : 1f,
                        toY = rawAnim.toY != 0 ? rawAnim.toY : 1f,
                        pivotX = rawAnim.pivotX,
                        pivotY = rawAnim.pivotY
                    };

                case "alpha":
                    return new AlphaAnim
                    {
                        start = rawAnim.start,
                        end = rawAnim.end,
                        from = rawAnim.from != 0 ? rawAnim.from : 1f,
                        to = rawAnim.to
                    };

                default:
                    Debug.LogWarning($"Unknown animation type: {rawAnim.type}");
                    return null;
            }
        }

        // Raw data classes for JsonUtility parsing
        [Serializable]
        private class RawComicsData
        {
            public int width = 1080;
            public int height = 1920;
            public List<RawLayerData> layers;
            public List<Sound> sounds;
        }

        [Serializable]
        private class RawLayerData
        {
            public string id;
            public int x;
            public int y;
            public int width;
            public int height;
            public float alpha = 1f;
            public List<Image> images;
            public List<RawAnimData> anim;
        }

        [Serializable]
        private class RawAnimData
        {
            public string type;
            public float start;
            public float end;
            public float from;
            public float to;
            public float fromX;
            public float fromY;
            public float toX;
            public float toY;
            public float pivotX;
            public float pivotY;
        }
    }
}
