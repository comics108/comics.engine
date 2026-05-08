package net.nativemind.comics.flutter_comics.model.visual;

import android.text.TextUtils;

public class Image {
	private String file;
	private int width;
	private int height;
	private String popup;

	public String getFile() {
		return file;
	}

	public int getWidth() {
		return width;
	}

	public int getHeight() {
		return height;
	}

	public String getPopup() {
		return popup;
	}

	public boolean isEmpty() {
		return TextUtils.isEmpty(file);
	}

	public boolean hasPopup() {
		return !TextUtils.isEmpty(popup);
	}
}
