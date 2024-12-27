import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:async';
import '../models/time_signature.dart';

class MetronomeProvider with ChangeNotifier {
  static const List<TimeSignature> availableTimeSignatures = [
    // 简单拍子
    TimeSignature(beats: 2, beatUnit: 4, name: '二拍子'),
    TimeSignature(beats: 3, beatUnit: 4, name: '三拍子'),
    TimeSignature(beats: 4, beatUnit: 4, name: '四拍子'),
    
    // 复合拍子
    TimeSignature(beats: 6, beatUnit: 8, name: '六八拍子'),
    TimeSignature(beats: 9, beatUnit: 8, name: '九八拍子'),
    TimeSignature(beats: 12, beatUnit: 8, name: '十二八拍子'),
    
    // 混合拍子
    TimeSignature(beats: 5, beatUnit: 4, name: '五拍子'),
    TimeSignature(beats: 7, beatUnit: 4, name: '七拍子'),
    
    // 其他常用拍子
    TimeSignature(beats: 2, beatUnit: 2, name: '切分音拍子'),
    TimeSignature(beats: 3, beatUnit: 2, name: '三二拍子'),
    TimeSignature(beats: 3, beatUnit: 8, name: '三八拍子'),
    TimeSignature(beats: 4, beatUnit: 2, name: '四二拍子'),
  ];

  final AudioPlayer _highTickPlayer = AudioPlayer();
  final AudioPlayer _midTickPlayer = AudioPlayer();
  final AudioPlayer _lowTickPlayer = AudioPlayer();
  bool _isPlaying = false;
  int _bpm = 120;
  TimeSignature _timeSignature = availableTimeSignatures[2]; // 默认 4/4
  int _currentBeat = 0;
  double _pendulumAngle = 0.0;
  
  // 添加定时相关属性
  Timer? _delayTimer;
  Timer? _durationTimer;
  Duration _delayDuration = Duration.zero;
  Duration _playDuration = Duration.zero;
  bool _continuousPlay = false;
  
  // 添加一个变量来追踪动画方向
  bool _isSwingingRight = true;
  
  MetronomeProvider() {
    _initAudio();
  }

  Future<void> _initAudio() async {
    // 设置音量
    await _highTickPlayer.setVolume(1.0);
    await _midTickPlayer.setVolume(1.0);
    await _lowTickPlayer.setVolume(1.0);
    
    // 预加载音频文件
    await _highTickPlayer.setSource(AssetSource('sounds/high_tick.mp3'));
    await _midTickPlayer.setSource(AssetSource('sounds/mid_tick.mp3'));
    await _lowTickPlayer.setSource(AssetSource('sounds/low_tick.mp3'));
  }

  bool get isPlaying => _isPlaying;
  int get bpm => _bpm;
  TimeSignature get timeSignature => _timeSignature;
  List<TimeSignature> get timeSignatures => availableTimeSignatures;
  int get currentBeat => _currentBeat;
  double get pendulumAngle => _pendulumAngle;
  Duration get delayDuration => _delayDuration;
  Duration get playDuration => _playDuration;
  bool get continuousPlay => _continuousPlay;
  bool get isDelaying => _delayTimer?.isActive ?? false;

  void setBpm(int newBpm) {
    _bpm = newBpm.clamp(30, 250);
    if (_isPlaying) {
      _restartMetronome();
    }
    notifyListeners();
  }

  void setTimeSignature(TimeSignature signature) {
    _timeSignature = signature;
    _currentBeat = 0;
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

  void _startMetronome() {
    const tickInterval = Duration(minutes: 1);
    // 根据 BPM 调整摆动幅度，BPM 越快幅度越小
    final maxAngle = (0.5 - (_bpm - 30) / 440) * pi / 2;
    
    Future.doWhile(() async {
      if (!_isPlaying) return false;
      
      final beatDuration = tickInterval ~/ _bpm;
      final frameCount = beatDuration.inMilliseconds ~/ 16;
      
      // 播放当前拍的音效
      _playTick();
      _currentBeat = (_currentBeat + 1) % _timeSignature.beats;
      
      // 执行摆针动画
      for (int frame = 0; frame < frameCount; frame++) {
        if (!_isPlaying) return false;
        
        final progress = frame / frameCount;
        
        // 根据摆动方向计算角度
        if (_isSwingingRight) {
          _pendulumAngle = maxAngle * (-1 + 2 * progress);
        } else {
          _pendulumAngle = maxAngle * (1 - 2 * progress);
        }
        
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 16));
      }
      
      // 在每个节拍结束时切换方向
      _isSwingingRight = !_isSwingingRight;
      
      return _isPlaying;
    });
  }

  void _stopMetronome() {
    _currentBeat = 0;
    _isSwingingRight = true; // 重置方向
    _pendulumAngle = 0.0;  // 重置角度
    _highTickPlayer.stop();
    _midTickPlayer.stop();
    _lowTickPlayer.stop();
  }

  void _restartMetronome() {
    _stopMetronome();
    _startMetronome();
  }

  void _stopAll() {
    _isPlaying = false;
    _delayTimer?.cancel();
    _durationTimer?.cancel();
    _stopMetronome();
    notifyListeners();
  }

  void _startWithDelay() {
    if (_delayDuration > Duration.zero) {
      _delayTimer = Timer(_delayDuration, () {
        _startWithDuration();
      });
      notifyListeners();
    } else {
      _startWithDuration();
    }
  }

  void _startWithDuration() {
    _isPlaying = true;
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

  void _playTick() {
    if (_currentBeat == 0) {
      _highTickPlayer.play(AssetSource('sounds/high_tick.mp3'));
    } else if (_timeSignature.beats > 3 && _currentBeat == _timeSignature.beats ~/ 2) {
      _midTickPlayer.play(AssetSource('sounds/mid_tick.mp3'));
    } else {
      _lowTickPlayer.play(AssetSource('sounds/low_tick.mp3'));
    }
  }

  @override
  void dispose() {
    _stopAll();
    _highTickPlayer.dispose();
    _midTickPlayer.dispose();
    _lowTickPlayer.dispose();
    super.dispose();
  }
} 