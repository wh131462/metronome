# Metronome 节拍器

一个使用 Flutter 开发的跨平台专业节拍器应用，支持原生音频引擎实现精准节拍。

## 功能特点

- **精准节拍** - 原生音频引擎 (Android/iOS/macOS)，Web Audio API (浏览器)
- **BPM 调节** - 支持 30-250 BPM，点击、长按、滑块多种调节方式
- **TAP TEMPO** - 连续点击自动计算节奏速度
- **多种拍号** - 支持 1-12 拍，涵盖 2/4、3/4、4/4、6/8 等常用拍号
- **小节循环** - 播放 N 小节后静音 M 小节，适合节奏训练
- **定时控制** - 延迟开始、播放时长、循环播放
- **主题切换** - 深色/浅色主题一键切换
- **可视化反馈** - 动态节拍指示器，当前拍高亮显示

## 平台支持

| 平台 | 状态 | 音频引擎 |
|------|------|----------|
| Android | ✅ | Native AudioTrack |
| iOS | ✅ | AVAudioEngine |
| macOS | ✅ | AVAudioEngine |
| Web | ✅ | Web Audio API |
| Windows | ✅ | Flutter 默认 |
| Linux | ✅ | Flutter 默认 |

## 快速开始

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
# 自动选择设备
flutter run

# 指定平台
flutter run -d chrome      # Web
flutter run -d macos       # macOS
flutter run -d windows     # Windows
```

### 构建发布版本

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

## 项目结构

```
lib/
├── main.dart              # 入口文件
├── models/                # 数据模型
│   └── time_signature.dart
├── providers/             # 状态管理
│   ├── metronome_provider.dart
│   └── theme_provider.dart
├── screens/               # 页面
│   ├── metronome_screen.dart
│   ├── settings_screen.dart
│   └── splash_screen.dart
├── services/              # 音频服务
│   ├── audio_engine.dart        # 条件导出
│   ├── audio_engine_base.dart   # 抽象接口
│   ├── native_audio_engine.dart # 原生实现
│   └── web_audio_engine.dart    # Web 实现
├── painters/              # 自定义绑定
│   └── metronome_painter.dart
└── widgets/               # 可复用组件
    └── timing_control_panel.dart

macos/Runner/
├── MetronomeAudioEngine.swift   # macOS 原生音频
└── AppDelegate.swift            # Platform Channel

ios/Runner/
├── MetronomeAudioEngine.swift   # iOS 原生音频
└── AppDelegate.swift

android/app/src/main/kotlin/
└── MetronomeAudioEngine.kt      # Android 原生音频
```

## 技术栈

- **框架**: Flutter 3.x
- **状态管理**: Provider
- **音频**: 原生平台 API + Web Audio API
- **平台通信**: MethodChannel

## 依赖项

```yaml
dependencies:
  flutter: sdk
  provider: ^6.1.1       # 状态管理
  cupertino_icons: ^1.0.2
  web: ^1.0.0            # Web Audio API
```

## 开发命令

```bash
# 静态分析
flutter analyze

# 格式化代码
dart format lib/

# 生成应用图标
dart run flutter_launcher_icons

# Android 完整构建 (带版本号递增)
dart scripts/build_android.dart --increment-version
```

## 更新日志

### [1.0.1] - 2025-01
- 新增 macOS 原生音频引擎
- 新增 Web Audio API 支持
- 新增 TAP TEMPO 功能
- 新增小节循环 (播放/静音)
- 新增定时控制 (延迟开始、播放时长)
- 优化透明窗口支持 (macOS)
- 优化响应式布局

### [1.0.0] - 2025-01
- 初始版本发布
- 基础节拍器功能
- 支持多种拍号
- 深色/浅色主题

## 许可证

MIT License - 详见 [LICENSE](LICENSE)
