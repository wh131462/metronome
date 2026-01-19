# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter cross-platform metronome application (节拍器) supporting Android, iOS, Web, Windows, macOS, and Linux. It uses Provider for state management and audioplayers for sound playback.

## Common Commands

```bash
# Run the app
flutter run

# Build for specific platforms
flutter build apk --release      # Android
flutter build ios                # iOS
flutter build web                # Web
flutter build macos              # macOS
flutter build windows            # Windows
flutter build linux              # Linux

# Code quality
flutter analyze                  # Static analysis
flutter pub get                  # Install dependencies

# Custom build scripts (from project root)
dart scripts/build_android.dart --increment-version    # Full Android build with versioning
dart scripts/rebuild_project.dart                      # Clean rebuild
dart scripts/create_icons.dart                         # Generate app icons
```

## Architecture

### State Management
- Uses **Provider** with `ChangeNotifier` pattern
- Single `MetronomeProvider` handles all app state: BPM (30-250), time signature, playback, pendulum animation
- UI components use `context.watch<MetronomeProvider>()` for reactive updates

### Directory Structure
- `lib/models/` - Data models (e.g., `TimeSignature` with 12 predefined signatures)
- `lib/providers/` - `MetronomeProvider` containing audio players, timing logic, animation loop
- `lib/screens/` - Main `MetronomeScreen` with sub-components (display, controls, play button)
- `lib/painters/` - `MetronomePainter` for custom canvas rendering of the metronome visualization
- `lib/widgets/` - Reusable UI components like `TimingControlPanel`
- `scripts/` - Dart-based build automation scripts
- `assets/sounds/` - Audio files: `high_tick.mp3` (first beat), `low_tick.mp3` (regular beats)

### Key Implementation Details
- Audio: Three `AudioPlayer` instances for different tick sounds
- Animation: Uses `Future.doWhile()` with 16ms frame timing for pendulum swing
- Pendulum physics: Swing angle inversely proportional to BPM (faster = smaller swing)
- Custom painting: Hand-drawn metronome case with wood grain, shadows, and gradients

### Dependencies
- `audioplayers: ^5.2.1` - Cross-platform audio playback
- `provider: ^6.1.1` - State management
- `shared_preferences: ^2.2.2` - Local storage (available but currently unused)

## Known Issues
- `mid_tick.mp3` is referenced in code but the file doesn't exist in assets
- Registry uses Chinese mirror: `https://pub.flutter-io.cn`
