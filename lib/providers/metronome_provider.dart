import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/time_signature.dart';
import '../services/audio_engine.dart';

class MetronomeProvider with ChangeNotifier {
  static const List<TimeSignature> availableTimeSignatures = [
    TimeSignature(beats: 2, beatUnit: 4, name: '二拍子'),
    TimeSignature(beats: 3, beatUnit: 4, name: '三拍子'),
    TimeSignature(beats: 4, beatUnit: 4, name: '四拍子'),
    TimeSignature(beats: 6, beatUnit: 8, name: '六八拍子'),
    TimeSignature(beats: 9, beatUnit: 8, name: '九八拍子'),
    TimeSignature(beats: 12, beatUnit: 8, name: '十二八拍子'),
    TimeSignature(beats: 5, beatUnit: 4, name: '五拍子'),
    TimeSignature(beats: 7, beatUnit: 4, name: '七拍子'),
  ];

  final AudioEngineBase _audioEngine = createAudioEngine();

  bool _isPlaying = false;
  int _bpm = 120;
  TimeSignature _timeSignature = availableTimeSignatures[2];
  int _currentBeat = 0;

  Timer? _delayTimer;
  Timer? _delayCountdownTimer;
  Timer? _durationTimer;
  Timer? _bpmDebounceTimer;
  Duration _delayDuration = Duration.zero;
  Duration _playDuration = Duration.zero;
  bool _continuousPlay = false;
  int _remainingDelaySeconds = 0;

  final List<DateTime> _tapTimes = [];

  int _playBars = 1;
  int _muteBars = 0;
  bool _isMuted = false;

  MetronomeProvider() {
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioEngine.initialize();

      // 节拍回调
      _audioEngine.setBeatCallback((beat, isMuted) {
        _currentBeat = beat;
        _isMuted = isMuted;
        // 使用 scheduleMicrotask 尽快触发 UI 更新，减少延迟
        scheduleMicrotask(() {
          notifyListeners();
        });
      });

      // 播放状态回调（从通知栏控制）
      _audioEngine.setPlayStateCallback((isPlaying) {
        _isPlaying = isPlaying;
        if (!isPlaying) {
          _currentBeat = 0;
          _isMuted = false;
        }
        scheduleMicrotask(() {
          notifyListeners();
        });
      });

      // 预设切换回调（从通知栏控制）
      _audioEngine.setPresetChangedCallback((bpm, beatsPerBar, presetIndex) {
        _bpm = bpm;
        _timeSignature = TimeSignature(beats: beatsPerBar, beatUnit: 4, name: '');
        _currentBeat = 0;
        scheduleMicrotask(() {
          notifyListeners();
        });
      });
    } catch (e) {
      debugPrint('Audio init error: $e');
    }
  }

  bool get isPlaying => _isPlaying;
  int get bpm => _bpm;
  TimeSignature get timeSignature => _timeSignature;
  List<TimeSignature> get timeSignatures => availableTimeSignatures;
  int get currentBeat => _currentBeat;
  Duration get delayDuration => _delayDuration;
  Duration get playDuration => _playDuration;
  bool get continuousPlay => _continuousPlay;
  bool get isDelaying => _delayTimer?.isActive ?? false;
  int get remainingDelaySeconds => _remainingDelaySeconds;
  int get playBars => _playBars;
  int get muteBars => _muteBars;
  bool get isMuted => _isMuted;
  int get beatsPerBar => _timeSignature.beats;

  void setBpm(int newBpm) {
    _bpm = newBpm.clamp(30, 250);
    notifyListeners();

    if (_isPlaying) {
      _bpmDebounceTimer?.cancel();
      _bpmDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        if (_isPlaying) {
          _audioEngine.setBpm(_bpm);
        }
      });
    }
  }

  void setTimeSignature(TimeSignature signature) {
    _timeSignature = signature;
    _currentBeat = 0;
    if (_isPlaying) {
      _audioEngine.setBeatsPerBar(signature.beats);
    }
    notifyListeners();
  }

  void togglePlaying() {
    if (_isPlaying || isDelaying) {
      _stopAll();
    } else {
      _startWithDelay();
    }
    notifyListeners();
  }

  Future<void> _startMetronome() async {
    await _audioEngine.start(
      bpm: _bpm,
      beatsPerBar: _timeSignature.beats,
      playBars: _playBars,
      muteBars: _muteBars,
    );
  }

  Future<void> _stopMetronome() async {
    await _audioEngine.stop();
    _currentBeat = 0;
    _isMuted = false;
  }

  Future<void> _restartMetronome() async {
    await _stopMetronome();
    await _startMetronome();
  }

  void _stopAll() {
    _isPlaying = false;
    _delayTimer?.cancel();
    _delayCountdownTimer?.cancel();
    _durationTimer?.cancel();
    _bpmDebounceTimer?.cancel();
    _remainingDelaySeconds = 0;
    _stopMetronome();
    notifyListeners();
  }

  void _startWithDelay() {
    if (_delayDuration > Duration.zero) {
      _remainingDelaySeconds = _delayDuration.inSeconds;
      notifyListeners();

      _delayCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _remainingDelaySeconds--;
        if (_remainingDelaySeconds <= 0) {
          timer.cancel();
        }
        notifyListeners();
      });

      _delayTimer = Timer(_delayDuration, () {
        _delayCountdownTimer?.cancel();
        _remainingDelaySeconds = 0;
        _startWithDuration();
      });
    } else {
      _startWithDuration();
    }
  }

  void _startWithDuration() {
    _isPlaying = true;
    if (_playDuration > Duration.zero || _continuousPlay) {
      if (_playDuration > Duration.zero) {
        _durationTimer = Timer(_playDuration, () {
          if (_continuousPlay) {
            _restartMetronome();
            _startWithDelay();
          } else {
            _stopAll();
          }
        });
      }
    }
    _startMetronome();
    notifyListeners();
  }

  void setDelay(Duration duration) {
    _delayDuration = duration;
    notifyListeners();
  }

  void setPlayDuration(Duration duration) {
    _playDuration = duration;
    notifyListeners();
  }

  void setContinuousPlay(bool value) {
    _continuousPlay = value;
    notifyListeners();
  }

  void setBeatsPerBar(int beats) {
    if (beats >= 1 && beats <= 12) {
      _timeSignature = TimeSignature(beats: beats, beatUnit: 4, name: '');
      _currentBeat = 0;
      if (_isPlaying) {
        _audioEngine.setBeatsPerBar(beats);
      }
      notifyListeners();
    }
  }

  void tapTempo() {
    final now = DateTime.now();
    _tapTimes.removeWhere((t) => now.difference(t).inMilliseconds > 2000);
    _tapTimes.add(now);

    if (_tapTimes.length >= 2) {
      int totalMs = 0;
      for (int i = 1; i < _tapTimes.length; i++) {
        totalMs += _tapTimes[i].difference(_tapTimes[i - 1]).inMilliseconds;
      }
      final avgMs = totalMs / (_tapTimes.length - 1);
      final newBpm = (60000 / avgMs).round();
      setBpm(newBpm);
    }
  }

  void setPlayBars(int bars) {
    _playBars = bars.clamp(1, 16);
    if (_isPlaying) {
      _audioEngine.setBarMute(playBars: _playBars, muteBars: _muteBars);
    }
    notifyListeners();
  }

  void setMuteBars(int bars) {
    _muteBars = bars.clamp(0, 16);
    if (_isPlaying) {
      _audioEngine.setBarMute(playBars: _playBars, muteBars: _muteBars);
    }
    notifyListeners();
  }

  void incrementBpm([int amount = 1]) {
    setBpm(_bpm + amount);
  }

  void decrementBpm([int amount = 1]) {
    setBpm(_bpm - amount);
  }

  @override
  void dispose() {
    _stopAll();
    _bpmDebounceTimer?.cancel();
    _audioEngine.dispose();
    super.dispose();
  }
}
