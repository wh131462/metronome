import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'audio_engine_base.dart';

/// Native Audio Engine - 使用平台原生音频 API 实现精准节拍
/// Android: AudioTrack / Oboe
/// iOS: AVAudioEngine
/// macOS: AVAudioEngine
class NativeAudioEngine implements AudioEngineBase {
  static const MethodChannel _channel = MethodChannel('com.eternalheart.metronome/audio');

  static final NativeAudioEngine _instance = NativeAudioEngine._internal();
  factory NativeAudioEngine() => _instance;
  NativeAudioEngine._internal();

  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  bool get isInitialized => _isInitialized;
  @override
  bool get isPlaying => _isPlaying;

  /// 初始化音频引擎，预加载音频 buffer
  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final result = await _channel.invokeMethod<bool>('initialize');
      _isInitialized = result ?? false;
      return _isInitialized;
    } on PlatformException catch (e) {
      debugPrint('Failed to initialize audio engine: ${e.message}');
      return false;
    }
  }

  /// 开始播放节拍器
  /// [bpm] - 每分钟拍数
  /// [beatsPerBar] - 每小节拍数
  /// [playBars] - 播放小节数（用于循环静音）
  /// [muteBars] - 静音小节数
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

    try {
      final result = await _channel.invokeMethod<bool>('start', {
        'bpm': bpm,
        'beatsPerBar': beatsPerBar,
        'playBars': playBars,
        'muteBars': muteBars,
      });
      _isPlaying = result ?? false;
      return _isPlaying;
    } on PlatformException catch (e) {
      debugPrint('Failed to start metronome: ${e.message}');
      return false;
    }
  }

  /// 停止播放
  @override
  Future<bool> stop() async {
    try {
      final result = await _channel.invokeMethod<bool>('stop');
      _isPlaying = !(result ?? true);
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to stop metronome: ${e.message}');
      return false;
    }
  }

  /// 更新 BPM（运行时）
  @override
  Future<bool> setBpm(int bpm) async {
    try {
      final result = await _channel.invokeMethod<bool>('setBpm', {'bpm': bpm});
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set BPM: ${e.message}');
      return false;
    }
  }

  /// 更新每小节拍数
  @override
  Future<bool> setBeatsPerBar(int beats) async {
    try {
      final result = await _channel.invokeMethod<bool>('setBeatsPerBar', {'beats': beats});
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set beats per bar: ${e.message}');
      return false;
    }
  }

  /// 更新循环静音设置
  @override
  Future<bool> setBarMute({required int playBars, required int muteBars}) async {
    try {
      final result = await _channel.invokeMethod<bool>('setBarMute', {
        'playBars': playBars,
        'muteBars': muteBars,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set bar mute: ${e.message}');
      return false;
    }
  }

  Function(int beat, bool isMuted)? _beatCallback;
  Function(bool isPlaying)? _playStateCallback;
  Function(int bpm, int beatsPerBar, int presetIndex)? _presetChangedCallback;

  /// 设置音频回调（接收当前拍数）
  @override
  void setBeatCallback(Function(int beat, bool isMuted)? callback) {
    _beatCallback = callback;
    _setupMethodCallHandler();
  }

  /// 设置播放状态回调（从通知栏控制）
  @override
  void setPlayStateCallback(Function(bool isPlaying)? callback) {
    _playStateCallback = callback;
    _setupMethodCallHandler();
  }

  /// 设置预设切换回调（从通知栏控制）
  @override
  void setPresetChangedCallback(Function(int bpm, int beatsPerBar, int presetIndex)? callback) {
    _presetChangedCallback = callback;
    _setupMethodCallHandler();
  }

  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onBeat':
          if (_beatCallback != null) {
            final beat = call.arguments['beat'] as int;
            final isMuted = call.arguments['isMuted'] as bool;
            _beatCallback!(beat, isMuted);
          }
          break;
        case 'onPlayStateChanged':
          if (_playStateCallback != null) {
            final isPlaying = call.arguments['isPlaying'] as bool;
            _playStateCallback!(isPlaying);
          }
          break;
        case 'onPresetChanged':
          if (_presetChangedCallback != null) {
            final bpm = call.arguments['bpm'] as int;
            final beatsPerBar = call.arguments['beatsPerBar'] as int;
            final presetIndex = call.arguments['presetIndex'] as int;
            _presetChangedCallback!(bpm, beatsPerBar, presetIndex);
          }
          break;
      }
    });
  }

  /// 释放资源
  @override
  Future<void> dispose() async {
    await stop();
    try {
      await _channel.invokeMethod('dispose');
      _isInitialized = false;
    } on PlatformException catch (e) {
      debugPrint('Failed to dispose audio engine: ${e.message}');
    }
  }
}

/// Factory function for conditional import
AudioEngineBase createAudioEngine() => NativeAudioEngine();
