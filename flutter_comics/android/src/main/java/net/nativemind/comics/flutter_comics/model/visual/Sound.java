package net.nativemind.comics.flutter_comics.model.visual;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ValueAnimator;
import android.content.Context;
import android.view.animation.AccelerateDecelerateInterpolator;
import android.view.animation.Interpolator;
import androidx.annotation.FloatRange;

import net.nativemind.comics.flutter_comics.model.visual.animation.SoundAnim;

import java.util.ArrayList;

public class Sound {
	private static final Interpolator INTERPOLATOR = new AccelerateDecelerateInterpolator();

	private String file;
	private ArrayList<SoundAnim> animations;

	// TODO: Replace with actual sound implementation
	private transient boolean playing = false;
	private transient boolean prepared = false;
	private transient float oldVolume = 0f;
	private transient float newVolume = 1f;
	private transient float volume = 0f;
	private transient boolean looping = false;
	private transient String archivePath;
	private transient ValueAnimator volumeAnimator = ValueAnimator.ofFloat(0f, 1f);
	private transient ValueAnimator.AnimatorUpdateListener volumeUpdateListener = new ValueAnimator.AnimatorUpdateListener() {
		private float oldValue = -1;

		@Override
		public void onAnimationUpdate(ValueAnimator valueAnimator) {
			float value = (float) valueAnimator.getAnimatedValue();
			if (oldValue == value)
				return;

			oldValue = value;
			setVolume(Layer.FLOAT_EVALUATOR.evaluate(value, oldVolume, newVolume));
		}
	};
	private transient ValueAnimator.AnimatorListener volumeAnimatorListener = new AnimatorListenerAdapter() {
		@Override
		public void onAnimationEnd(Animator animation) {
			super.onAnimationEnd(animation);
			if (volume == 0)
				stop(false);
		}
	};

	public Sound() {
		volumeAnimator.addUpdateListener(volumeUpdateListener);
		volumeAnimator.addListener(volumeAnimatorListener);
		volumeAnimator.setDuration(600);
		volumeAnimator.setInterpolator(INTERPOLATOR);
	}

	public String getFile() {
		return file;
	}

	public ArrayList<SoundAnim> getAnimations() {
		return animations;
	}

	public void prepare(Context context, String archivePath) {
		this.archivePath = archivePath;
		// TODO: Initialize sound manager here
		// Stub implementation - sound playback not yet implemented
		prepared = true;
	}

	public void process(int scrollOffset, int previousScrollOffset, boolean skipPointSounds) {
		for (SoundAnim anim : getAnimations()) {
			if (anim.isPoint()) {
				if (!skipPointSounds && previousScrollOffset < scrollOffset && previousScrollOffset < anim.getStart() && scrollOffset >= anim.getStart())
					play(false);
				return;
			}
			if (scrollOffset >= anim.getStart() && scrollOffset <= anim.getEnd()) {
				if (!isPlaying())
					play(true);
				return;
			}
		}
		stop(true);
	}

	public boolean isPlaying() {
		// TODO: Return actual playing state when sound manager is implemented
		return playing && prepared;
	}

	public void play(boolean looping) {
		this.looping = looping;
		if (!isPlaying()) {
			// TODO: Prepare and play sound from archivePath + getFile()
			// Stub implementation
			playInternal();
		}
	}

	private void playInternal() {
		// TODO: Implement actual sound playback
		// Stub implementation
		playing = true;
		if (looping)
			animateVolume(1f);
		else
			setVolume(1f);
	}

	public void resume() {
		// TODO: Resume sound playback
		// Stub implementation
		if (prepared && !playing) {
			playing = true;
		}
	}

	public void pause() {
		// TODO: Pause sound playback
		// Stub implementation
		if (isPlaying()) {
			playing = false;
		}
	}

	public void stop(boolean anim) {
		if (!isPlaying()) {
			// TODO: Release sound resources
			return;
		}

		if (anim) {
			animateVolume(0f);
		} else {
			setVolume(0f);
			playing = false;
			// TODO: Release sound resources
		}
	}

	private void animateVolume(@FloatRange(from = 0f, to = 1f) float volume) {
		oldVolume = this.volume;
		newVolume = volume;
		volumeAnimator.start();
	}

	private void setVolume(@FloatRange(from = 0f, to = 1f) float volume) {
		this.volume = volume;
		// TODO: Set actual volume when sound manager is implemented
	}

	public void release() {
		// TODO: Release sound manager resources
		playing = false;
		prepared = false;
	}
}
