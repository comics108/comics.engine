using System;
using System.Collections.Generic;
using UnityEngine;

namespace NativeMind.ComicsViewer.Models
{
    /// <summary>
    /// Root data model for comics archive
    /// </summary>
    [Serializable]
    public class Comics
    {
        public int width = 1080;
        public int height = 1920;
        public List<Layer> layers = new List<Layer>();
        public List<Sound> sounds = new List<Sound>();
    }

    /// <summary>
    /// Single layer in the comics
    /// </summary>
    [Serializable]
    public class Layer
    {
        public string id;
        public int x;
        public int y;
        public int width;
        public int height;
        public float alpha = 1f;
        public List<Image> images = new List<Image>();
        public List<Anim> anim = new List<Anim>();
    }

    /// <summary>
    /// Image reference with optional locale
    /// </summary>
    [Serializable]
    public class Image
    {
        public string src;
        public string locale;
    }

    /// <summary>
    /// Sound trigger configuration
    /// </summary>
    [Serializable]
    public class Sound
    {
        public string src;
        public string type = "point"; // "point" or "range"
        public float start;
        public float end = -1f;
        public float volume = 1f;
        public bool loop;
    }
}
