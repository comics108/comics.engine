using UnityEngine;
using UnityEngine.UI;
using NativeMind.ComicsViewer;

namespace NativeMind.ComicsViewer.Samples
{
    /// <summary>
    /// Demo controller for BasicViewer sample scene
    /// </summary>
    public class DemoController : MonoBehaviour
    {
        [Header("References")]
        public ComicsViewer viewer;
        public Text statusText;
        public Slider scrollSlider;
        public Toggle soundToggle;

        [Header("Settings")]
        public string comicsPath = "test-comics.comics";

        private void Start()
        {
            if (viewer == null)
            {
                viewer = FindObjectOfType<ComicsViewer>();
            }

            if (viewer != null)
            {
                viewer.OnLoaded += OnComicsLoaded;
                viewer.OnScroll += OnScroll;
                viewer.OnError += OnError;

                // Load comics from Resources or StreamingAssets
                string fullPath = System.IO.Path.Combine(
                    Application.streamingAssetsPath,
                    comicsPath
                );

                if (System.IO.File.Exists(fullPath))
                {
                    viewer.LoadArchive(fullPath);
                }
                else
                {
                    UpdateStatus("Comics not found: " + comicsPath);
                }
            }

            SetupUI();
        }

        private void SetupUI()
        {
            if (scrollSlider != null)
            {
                scrollSlider.onValueChanged.AddListener(OnSliderChanged);
            }

            if (soundToggle != null)
            {
                soundToggle.isOn = true;
                soundToggle.onValueChanged.AddListener(OnSoundToggled);
            }
        }

        private void OnComicsLoaded(ComicsInfo info)
        {
            UpdateStatus($"Loaded: {info.Width}x{info.Height}, {info.LayerCount} layers");

            if (scrollSlider != null)
            {
                scrollSlider.maxValue = viewer.MaxScrollOffset;
            }
        }

        private void OnScroll(float scrollY, float maxScroll)
        {
            if (scrollSlider != null && !scrollSlider.isFocused)
            {
                scrollSlider.SetValueWithoutNotify(scrollY);
            }
        }

        private void OnError(string error)
        {
            UpdateStatus("Error: " + error);
        }

        private void OnSliderChanged(float value)
        {
            if (viewer != null)
            {
                viewer.SetScrollOffset(value);
            }
        }

        private void OnSoundToggled(bool enabled)
        {
            if (viewer != null)
            {
                viewer.SetSoundEnabled(enabled);
            }
        }

        public void SetLanguage(int index)
        {
            if (viewer != null)
            {
                viewer.SetLanguageIndex(index);
            }
        }

        private void UpdateStatus(string text)
        {
            if (statusText != null)
            {
                statusText.text = text;
            }
            Debug.Log(text);
        }

        private void OnDestroy()
        {
            if (viewer != null)
            {
                viewer.OnLoaded -= OnComicsLoaded;
                viewer.OnScroll -= OnScroll;
                viewer.OnError -= OnError;
            }
        }
    }
}
