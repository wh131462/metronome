import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'audio_engine_base.dart';

/// Web Audio Engine - Uses Web Audio API for browser-based playback
class WebAudioEngine implements AudioEngineBase {
  web.AudioContext? _audioContext;

  bool _isInitialized = false;
  bool _isPlaying = false;

  int _bpm = 120;
  int _beatsPerBar = 4;
  int _playBars = 1;
  int _muteBars = 0;

  int _currentBeat = 0;
  int _currentBar = 0;
  bool _isMuted = false;

  Timer? _playbackTimer;

  Function(int beat, bool isMuted)? _beatCallback;
  // ignore: unused_field
  Function(bool isPlaying)? _playStateCallback; // Web has no native controls
  // ignore: unused_field
  Function(int bpm, int beatsPerBar, int presetIndex)? _presetChangedCallback;

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _audioContext = web.AudioContext();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Failed to initialize Web Audio: $e');
      return false;
    }
  }

  @override
  Future<bool> start({
    required int bpm,
    required int beatsPerBar,
    int playBars = 1,
    int muteBars = 0,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    // Resume audio context (required for user gesture)
    if (_audioContext?.state == 'suspended') {
      await _audioContext?.resume().toDart;
    }

    _bpm = bpm.clamp(30, 250);
    _beatsPerBar = beatsPerBar.clamp(1, 12);
    _playBars = playBars.clamp(1, 16);
    _muteBars = muteBars.clamp(0, 16);
    _currentBeat = 0;
    _currentBar = 0;
    _isMuted = false;
    _isPlaying = true;

    _startPlaybackLoop();
    return true;
  }

  void _startPlaybackLoop() {
    _playbackTimer?.cancel();

    final beatDuration = Duration(milliseconds: (60000 / _bpm).round());

    // Play first beat immediately
    _playBeat();

    _playbackTimer = Timer.periodic(beatDuration, (_) {
      if (!_isPlaying) {
        _playbackTimer?.cancel();
        return;
      }
      _playBeat();
    });
  }

  void _playBeat() {
    // Play click sound if not muted
    if (!_isMuted) {
      _playClick(_currentBeat == 0);
    }

    // Notify callback
    _beatCallback?.call(_currentBeat, _isMuted);

    // Update beat counter
    _currentBeat = (_currentBeat + 1) % _beatsPerBar;

    // Handle bar mute logic
    if (_currentBeat == 0) {
      _currentBar++;

      if (_muteBars > 0) {
        if (_isMuted) {
          if (_currentBar >= _muteBars) {
            _currentBar = 0;
            _isMuted = false;
          }
        } else {
          if (_currentBar >= _playBars) {
            _currentBar = 0;
            _isMuted = true;
          }
        }
      }
    }
  }

  void _playClick(bool isAccent) {
    final ctx = _audioContext;
    if (ctx == null) return;

    try {
      final oscillator = ctx.createOscillator();
      final gainNode = ctx.createGain();

      oscillator.connect(gainNode);
      gainNode.connect(ctx.destination);

      // Higher frequency for accent (first beat)
      final frequency = isAccent ? 1000.0 : 600.0;
      oscillator.frequency.value = frequency;
      oscillator.type = 'sine';

      final now = ctx.currentTime;
      gainNode.gain.setValueAtTime(0.5, now);
      gainNode.gain.exponentialRampToValueAtTime(0.01, now + 0.05);

      oscillator.start(now);
      oscillator.stop(now + 0.05);
    } catch (e) {
      debugPrint('Error playing click: $e');
    }
  }

  @override
  Future<bool> stop() async {
    _isPlaying = false;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _currentBeat = 0;
    _currentBar = 0;
    _isMuted = false;
    return true;
  }

  @override
  Future<bool> setBpm(int bpm) async {
    _bpm = bpm.clamp(30, 250);
    if (_isPlaying) {
      // Restart with new BPM
      _startPlaybackLoop();
    }
    return true;
  }

  @override
  Future<bool> setBeatsPerBar(int beats) async {
    _beatsPerBar = beats.clamp(1, 12);
    _currentBeat = 0;
    return true;
  }

  @override
  Future<bool> setBarMute({required int playBars, required int muteBars}) async {
    _playBars = playBars.clamp(1, 16);
    _muteBars = muteBars.clamp(0, 16);
    _currentBar = 0;
    _isMuted = false;
    return true;
  }

  @override
  void setBeatCallback(Function(int beat, bool isMuted)? callback) {
    _beatCallback = callback;
  }

  @override
  void setPlayStateCallback(Function(bool isPlaying)? callback) {
    _playStateCallback = callback;
  }

  @override
  void setPresetChangedCallback(Function(int bpm, int beatsPerBar, int presetIndex)? callback) {
    _presetChangedCallback = callback;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _audioContext?.close().toDart;
    _audioContext = null;
    _isInitialized = false;
  }
}

/// Factory function for conditional import
AudioEngineBase createAudioEngine() => WebAudioEngine();
