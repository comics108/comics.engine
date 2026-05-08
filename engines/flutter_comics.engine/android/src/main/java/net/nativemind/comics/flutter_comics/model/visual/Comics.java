package net.nativemind.comics.flutter_comics.model.visual;

import android.content.Context;

import java.util.ArrayList;

public class Comics {
	private int width;
	private int height;
	private ArrayList<Layer> layers;
	private ArrayList<Sound> sounds;
	private transient String archivePath = null;
	private transient int sampleSize = -1;
	private transient int previousScrollOffset = -1;
	private transient boolean skipPointSounds = false;
	private transient boolean soundOn = true;

	public int getWidth() {
		return width;
	}

	public int getHeight() {
		return height;
	}

	public ArrayList<Layer> getLayers() {
		return layers;
	}

	public ArrayList<Sound> getSounds() {
		return sounds;
	}

	public String getArchivePath() {
		return archivePath;
	}

	public int getSampleSize() {
		return sampleSize;
	}

	public boolean isSkipPointSounds() {
		return skipPointSounds;
	}

	public void setSkipPointSounds(boolean skipPointSounds) {
		this.skipPointSounds = skipPointSounds;
	}

	public boolean isSoundOn() {
		return soundOn;
	}

	public void setSoundOn(boolean soundOn) {
		this.soundOn = soundOn;
	}

	public void prepare(Context context, String archivePath) {
		this.archivePath = archivePath;
		sampleSize = computeSampleSize(context);
		for (Layer layer : getLayers())
			layer.prepare();
		for (Sound sound : getSounds())
			sound.prepare(context, archivePath);
	}

	public void prepare(Context context, String archivePath, int languageIndex) {
		this.archivePath = archivePath;
		sampleSize = computeSampleSize(context);
		for (Layer layer : getLayers()) {
			layer.setLanguageIndex(languageIndex);
			layer.prepare();
		}
		for (Sound sound : getSounds())
			sound.prepare(context, archivePath);
	}

	public void release() {
		for (Sound sound : sounds)
			sound.release();
	}

	public void process(int scrollOffset) {
		for (Layer layer : getLayers())
			layer.buildMatrixAndAlpha(scrollOffset);
		if (soundOn) {
			for (Sound sound : getSounds())
				sound.process(scrollOffset, previousScrollOffset, skipPointSounds);
		}
		previousScrollOffset = scrollOffset;
	}

	public boolean hasPreview() {
		for (Layer layer : layers) {
			if (layer.isPreview())
				return true;
		}
		return false;
	}

	private int computeSampleSize(Context context) {
		int size = getWidth() / context.getResources().getDisplayMetrics().widthPixels;
		int oldValue = 1;
		for (int i = 1; i <= 5; i++) {
			int value = (int) Math.pow(2, i);
			if (size < value)
				return oldValue;
			oldValue = value;
		}
		return oldValue;
	}

	public void toggleSounds() {
		soundOn = !soundOn;
		updateSoundsState();
	}

	public void updateSoundsState() {
		if (soundOn)
			resumeSoundsInternal();
		else
			pauseSoundsInternal();
	}

	public void pauseSounds() {
		if (soundOn)
			pauseSoundsInternal();
	}

	public void resumeSounds() {
		if (soundOn)
			resumeSoundsInternal();
	}

	private void pauseSoundsInternal() {
		for (Sound audio : getSounds())
			audio.pause();
	}

	private void resumeSoundsInternal() {
		for (Sound audio : getSounds())
			audio.resume();
	}

	public void setLanguageIndex(int languageIndex) {
		for (Layer layer : getLayers()) {
			layer.setLanguageIndex(languageIndex);
		}
	}
}
