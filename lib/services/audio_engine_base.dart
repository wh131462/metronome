/// Abstract audio engine interface for cross-platform metronome
abstract class AudioEngineBase {
  bool get isInitialized;
  bool get isPlaying;

  /// Initialize audio engine
  Future<bool> initialize();

  /// Start metronome playback
  Future<bool> start({
    required int bpm,
    required int beatsPerBar,
    int playBars = 1,
    int muteBars = 0,
  });

  /// Stop playback
  Future<bool> stop();

  /// Update BPM during playback
  Future<bool> setBpm(int bpm);

  /// Update beats per bar
  Future<bool> setBeatsPerBar(int beats);

  /// Update bar mute settings
  Future<bool> setBarMute({required int playBars, required int muteBars});

  /// Set beat callback
  void setBeatCallback(Function(int beat, bool isMuted)? callback);

  /// Set play state callback
  void setPlayStateCallback(Function(bool isPlaying)? callback);

  /// Set preset changed callback
  void setPresetChangedCallback(Function(int bpm, int beatsPerBar, int presetIndex)? callback);

  /// Dispose resources
  Future<void> dispose();
}
