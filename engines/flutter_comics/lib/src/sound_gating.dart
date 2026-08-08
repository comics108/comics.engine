import 'models.dart';

/// What a sound player's per-tick evaluation decided to do for a given sound.
enum SoundAction { none, playOnce, startLooping, stop }

/// Pure port of legacy/comics-editor-v2.8/Comics.Editor's `SoundAnim.FindCurrent`
/// + `SoundViewModel.Scroll`'s scroll-driven half (see
/// flows/vdd-comics-editor-vertical-scroll/01-requirements.md, point 11).
/// Deliberately separated from any real playback call so the gating decision
/// itself is testable without an audio package. The natural-clip-end
/// restart-if-looping behavior (legacy's `Player_MediaEnded`) is NOT part of
/// this -- that's a playback-completion event, not a scroll-driven one; a
/// real player wires it separately to its own completion stream.
///
/// flows/comics-viewer/sdd-flutter-comics-viewer-dart Plan Task 1.1: moved
/// verbatim from apps/comics-editor/lib/src/ui/audio/sound_player.dart --
/// already pure/portable (only depends on the shared [Anim]/[AnimType]),
/// confirmed independently by comics-viewer-ios's `playSoundsByOffset`
/// implementing the exact same one-shot/range/no-replay-on-scroll-up rules.
class SoundGating {
  SoundGating._();

  static SoundAction decide({
    required List<Anim> soundAnims,
    required double prevTime,
    required double currentTime,
    required bool currentlyPlaying,
  }) {
    final anim = _findCurrent(soundAnims, prevTime, currentTime);
    if (anim != null) {
      if (currentlyPlaying) return SoundAction.none; // matches Play(state, force:false)
      return anim.start == anim.end ? SoundAction.playOnce : SoundAction.startLooping;
    }
    return currentlyPlaying ? SoundAction.stop : SoundAction.none;
  }

  /// `SoundAnim.FindCurrent`: matches either a genuine range (`start <=
  /// currentTime <= end`) or a point (`start == end`) crossed while scrolling
  /// DOWNWARD specifically (`prevTime < currentTime && prevTime <= start &&
  /// start <= currentTime`) -- scrolling back up past a point-trigger does
  /// not replay it.
  static Anim? _findCurrent(List<Anim> anims, double prevTime, double currentTime) {
    for (final a in anims) {
      if (a.type != AnimType.sound) continue;
      final inRange = a.start <= currentTime && a.end >= currentTime;
      final crossedPointDownward = a.start == a.end &&
          prevTime < currentTime &&
          prevTime <= a.start &&
          a.start <= currentTime;
      if (inRange || crossedPointDownward) return a;
    }
    return null;
  }
}
