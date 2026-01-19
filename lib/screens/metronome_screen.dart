import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/metronome_provider.dart';
import '../providers/theme_provider.dart';
import 'settings_screen.dart';

class MetronomeScreen extends StatelessWidget {
  const MetronomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final colors = theme.colors;

    // macOS 透明标题栏需要额外顶部间距
    final isDesktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux);
    final topPadding = isDesktop ? 28.0 : 0.0;

    return Scaffold(
      backgroundColor: colors.background.withValues(alpha: 0.85),
      body: SafeArea(
        top: !isDesktop, // 桌面端不使用 SafeArea 顶部
        child: Column(
          children: [
            // 桌面端标题栏占位
            if (isDesktop) SizedBox(height: topPadding),
            // 顶部栏：设置、主题切换和帮助按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  // 设置按钮
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    icon: Icon(
                      Icons.settings_rounded,
                      color: colors.textMuted,
                      size: 24,
                    ),
                    tooltip: '设置',
                  ),
                  const Spacer(),
                  // 主题切换按钮
                  IconButton(
                    onPressed: () => theme.toggleTheme(),
                    icon: Icon(
                      theme.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: colors.textMuted,
                      size: 24,
                    ),
                    tooltip: theme.isDarkMode ? '切换亮色模式' : '切换暗黑模式',
                  ),
                  // 帮助按钮
                  IconButton(
                    onPressed: () => _showHelpDialog(context),
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: colors.textMuted,
                      size: 24,
                    ),
                    tooltip: '帮助',
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxHeight < 600;
                  final isMediumScreen = constraints.maxHeight < 750;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, isSmallScreen ? 16 : 24),
                    child: Column(
                      children: [
                        const BeatIndicator(),
                        SizedBox(height: isSmallScreen ? 16 : 32),
                        Expanded(
                          child: BpmControl(
                            compact: isSmallScreen,
                            mediumCompact: isMediumScreen,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        PlayButton(compact: isSmallScreen),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final colors = context.watch<ThemeProvider>().colors;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: colors.accent, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    '使用帮助',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded, color: colors.textMuted, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _HelpItem(
                icon: Icons.touch_app_rounded,
                title: 'TAP TEMPO',
                description: '连续点击按钮，根据你的点击节奏自动计算 BPM。适合跟着音乐找节奏。',
              ),
              const SizedBox(height: 16),
              const _HelpItem(
                icon: Icons.add_rounded,
                title: 'BPM 调节',
                description: '点击 +/- 微调，长按快速调节（±10）。也可以点击数字直接输入，或拖动滑块。',
              ),
              const SizedBox(height: 16),
              const _HelpItem(
                icon: Icons.repeat_rounded,
                title: '小节循环',
                description: '设置播放 N 小节后静音 M 小节，循环往复。适合节奏训练，培养内心节拍感。',
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colors.textSecondary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 节拍指示器
class BeatIndicator extends StatelessWidget {
  const BeatIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final metronome = context.watch<MetronomeProvider>();
    final colors = context.watch<ThemeProvider>().colors;
    final totalBeats = metronome.beatsPerBar;
    final isPlaying = metronome.isPlaying;
    final bpm = metronome.bpm;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.cardBackground,
            colors.cardBackgroundAlt.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 状态标签
          Container(
            height: 28,
            margin: const EdgeInsets.only(bottom: 20),
            child: isPlaying && metronome.isMuted
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.accentOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.accentOrange.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '静音中',
                      style: TextStyle(
                        color: colors.accentOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,
          ),
          // 节拍点
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 14,
            children: List.generate(totalBeats, (index) {
              final isActive = isPlaying && metronome.currentBeat == index;
              final isFirstBeat = index == 0;
              final isMidBeat = totalBeats > 3 && index == totalBeats ~/ 2;

              return _BeatDot(
                index: index,
                isActive: isActive,
                isFirstBeat: isFirstBeat,
                isMidBeat: isMidBeat,
                isMuted: metronome.isMuted,
                bpm: bpm,
              );
            }),
          ),
          // 节拍图例
          const SizedBox(height: 16),
          const _BeatLegend(),
        ],
      ),
    );
  }
}

/// 节拍图例说明
class _BeatLegend extends StatelessWidget {
  const _BeatLegend();

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(colors.accent, '强拍', colors),
        const SizedBox(width: 16),
        _buildLegendItem(colors.accentGreen, '中拍', colors),
        const SizedBox(width: 16),
        _buildLegendItem(colors.accentPurple, '弱拍', colors),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, AppColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _BeatDot extends StatelessWidget {
  final int index;
  final bool isActive;
  final bool isFirstBeat;
  final bool isMidBeat;
  final bool isMuted;
  final int bpm;

  const _BeatDot({
    required this.index,
    required this.isActive,
    required this.isFirstBeat,
    required this.isMidBeat,
    required this.isMuted,
    required this.bpm,
  });

  /// 根据 BPM 动态计算动画时长
  /// 动画时长 = 拍间隔 * 12%，限制在 30-120ms 之间
  Duration get _animationDuration {
    final beatIntervalMs = 60000 ~/ bpm;  // 每拍间隔(毫秒)
    final animationMs = (beatIntervalMs * 0.12).round().clamp(30, 120);
    return Duration(milliseconds: animationMs);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final color = _getColor(colors);

    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
        child: AnimatedScale(
          scale: isActive ? 1.2 : 1.0,
          duration: _animationDuration,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: _animationDuration,
            curve: Curves.easeOut,
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? color : colors.beatInactive,
              border: Border.all(
                color: isActive ? color : colors.beatBorder,
                width: 2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isActive ? colors.textPrimary : colors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getColor(AppColors colors) {
    if (isMuted) return colors.accentOrange;
    if (isFirstBeat) return colors.accent;
    if (isMidBeat) return colors.accentGreen;
    return colors.accentPurple;
  }
}

/// BPM 控制
class BpmControl extends StatelessWidget {
  final bool compact;
  final bool mediumCompact;

  const BpmControl({
    super.key,
    this.compact = false,
    this.mediumCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final metronome = context.watch<MetronomeProvider>();
    final colors = context.watch<ThemeProvider>().colors;

    final bpmFontSize = compact ? 52.0 : (mediumCompact ? 60.0 : 72.0);
    final buttonSize = compact ? 44.0 : 56.0;
    final spacing = compact ? 8.0 : 16.0;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // BPM 显示
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BpmButton(
                icon: Icons.remove_rounded,
                onTap: () => metronome.decrementBpm(),
                onLongPress: () => metronome.decrementBpm(10),
                size: buttonSize,
              ),
              GestureDetector(
                onTap: () => _showBpmDialog(context, metronome),
                child: Container(
                  width: compact ? 120 : 160,
                  padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
                  child: Column(
                    children: [
                      Text(
                        '${metronome.bpm}',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: bpmFontSize,
                          fontWeight: FontWeight.w300,
                          height: 1,
                          letterSpacing: -2,
                        ),
                      ),
                      SizedBox(height: compact ? 2 : 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 8 : 12,
                          vertical: compact ? 2 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.textPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'BPM',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: compact ? 11 : 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _BpmButton(
                icon: Icons.add_rounded,
                onTap: () => metronome.incrementBpm(),
                onLongPress: () => metronome.incrementBpm(10),
                size: buttonSize,
              ),
            ],
          ),
          SizedBox(height: spacing),
          // 滑块
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accent,
                    inactiveTrackColor: colors.beatInactive,
                    thumbColor: colors.textPrimary,
                    overlayColor: colors.accent.withValues(alpha: 0.15),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                      elevation: 4,
                    ),
                  ),
                  child: Slider(
                    value: metronome.bpm.toDouble(),
                    min: 30,
                    max: 250,
                    onChanged: (v) => metronome.setBpm(v.round()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('30', style: TextStyle(color: colors.textMuted, fontSize: 11)),
                      Text('250', style: TextStyle(color: colors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing),
          // Tap Tempo
          _TapTempoButton(onTap: metronome.tapTempo, compact: compact),
        ],
      ),
    );
  }

  void _showBpmDialog(BuildContext context, MetronomeProvider metronome) {
    final controller = TextEditingController(text: '${metronome.bpm}');
    showDialog(
      context: context,
      builder: (context) {
        final colors = context.watch<ThemeProvider>().colors;
        return AlertDialog(
          backgroundColor: colors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('设置 BPM', style: TextStyle(color: colors.textPrimary)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: colors.textPrimary, fontSize: 32, fontWeight: FontWeight.w300),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '30-250',
              hintStyle: TextStyle(color: colors.textMuted),
              filled: true,
              fillColor: colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消', style: TextStyle(color: colors.textMuted)),
            ),
            TextButton(
              onPressed: () {
                final bpm = int.tryParse(controller.text);
                if (bpm != null) metronome.setBpm(bpm);
                Navigator.pop(context);
              },
              child: Text('确定', style: TextStyle(color: colors.accent)),
            ),
          ],
        );
      },
    );
  }
}

class _BpmButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double size;

  const _BpmButton({
    required this.icon,
    required this.onTap,
    required this.onLongPress,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: colors.border),
        ),
        child: Icon(icon, color: colors.textSecondary, size: size * 0.5),
      ),
    );
  }
}

class _TapTempoButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool compact;

  const _TapTempoButton({required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 24,
          vertical: compact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, color: colors.textSecondary, size: compact ? 16 : 20),
            SizedBox(width: compact ? 6 : 8),
            Text(
              'TAP TEMPO',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 播放按钮
class PlayButton extends StatelessWidget {
  final bool compact;

  const PlayButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final metronome = context.watch<MetronomeProvider>();
    final colors = context.watch<ThemeProvider>().colors;
    final isPlaying = metronome.isPlaying;
    final isDelaying = metronome.isDelaying;

    final Color primaryColor = isDelaying
        ? colors.accentOrange
        : isPlaying
            ? colors.accent
            : colors.accentGreen;

    final height = compact ? 56.0 : 72.0;
    final iconSize = compact ? 26.0 : 32.0;
    final fontSize = compact ? 16.0 : 20.0;

    return GestureDetector(
      onTap: metronome.togglePlaying,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor,
              primaryColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(compact ? 16 : 20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: compact ? 12 : 16,
              offset: Offset(0, compact ? 4 : 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDelaying
                  ? Icons.timer_outlined
                  : isPlaying
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
              color: Colors.white,
              size: iconSize,
            ),
            SizedBox(width: compact ? 8 : 10),
            Text(
              isDelaying
                  ? '${metronome.remainingDelaySeconds}s'
                  : isPlaying
                      ? '停止'
                      : '开始',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
