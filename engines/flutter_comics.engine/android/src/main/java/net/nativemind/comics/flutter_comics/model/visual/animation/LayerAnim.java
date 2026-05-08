package net.nativemind.comics.flutter_comics.model.visual.animation;

import net.nativemind.comics.flutter_comics.model.visual.Layer;

public abstract class LayerAnim extends Anim {
	public LayerAnim interpolate(LayerAnim endAnim, int scrollOffset) {
		int scrollObject = scrollOffset - endAnim.getStart();
		int animHeight = endAnim.getEnd() - endAnim.getStart();
		float fraction = animHeight == 0 ? 1f : Math.min(1, Math.max(0, (float) scrollObject / (float) animHeight));
		return interpolate(endAnim, transformToCubic(fraction));
	}

	private float transformToCubic(float fraction) {
		return (--fraction) * fraction * fraction + 1;
	}

	protected abstract LayerAnim interpolate(LayerAnim endAnim, float fraction);

	public abstract void apply(Layer.ViewData data, int width, int height);
}
