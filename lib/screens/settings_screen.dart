import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/metronome_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final isDesktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux);

    return Scaffold(
      backgroundColor: colors.background.withValues(alpha: 0.85),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: isDesktop ? 72 : kToolbarHeight,
        leading: Padding(
          padding: EdgeInsets.only(top: isDesktop ? 16 : 0),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textPrimary),
          ),
        ),
        title: Padding(
          padding: EdgeInsets.only(top: isDesktop ? 16 : 0),
          child: Text(
            '设置',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            RhythmPresets(),
            SizedBox(height: 12),
            BeatsSelector(),
            SizedBox(height: 12),
            BarMuteControl(),
            SizedBox(height: 12),
            TimingControl(),
          ],
        ),
      ),
    );
  }
}

/// 节奏预设数据
class RhythmPreset {
  final String name;
  final String description;
  final int beatsPerBar;
  final int playBars;
  final int muteBars;
  final int? suggestedBpm;

  const RhythmPreset({
    required this.name,
    required this.description,
    required this.beatsPerBar,
    this.playBars = 1,
    this.muteBars = 0,
    this.suggestedBpm,
  });
}

/// 常见节奏预设
const List<RhythmPreset> rhythmPresets = [
  RhythmPreset(
    name: '流行/摇滚',
    description: '4/4拍',
    beatsPerBar: 4,
    suggestedBpm: 120,
  ),
  RhythmPreset(
    name: '华尔兹',
    description: '3/4拍',
    beatsPerBar: 3,
    suggestedBpm: 90,
  ),
  RhythmPreset(
    name: '进行曲',
    description: '2/4拍',
    beatsPerBar: 2,
    suggestedBpm: 110,
  ),
  RhythmPreset(
    name: '慢摇/民谣',
    description: '6/8拍',
    beatsPerBar: 6,
    suggestedBpm: 80,
  ),
  RhythmPreset(
    name: '节奏训练',
    description: '4拍·2+2循环',
    beatsPerBar: 4,
    playBars: 2,
    muteBars: 2,
    suggestedBpm: 80,
  ),
  RhythmPreset(
    name: '听力挑战',
    description: '4拍·1+3循环',
    beatsPerBar: 4,
    playBars: 1,
    muteBars: 3,
    suggestedBpm: 60,
  ),
];

/// 节奏预设选择器
class RhythmPresets extends StatelessWidget {
  const RhythmPresets({super.key});

  @override
  Widget build(BuildContext context) {
    final metronome = context.watch<MetronomeProvider>();
    final colors = context.watch<ThemeProvider>().colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快速预设',
            style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: rhythmPresets.map((preset) {
              final isSelected = metronome.beatsPerBar == preset.beatsPerBar &&
                  metronome.playBars == preset.playBars &&
                  metronome.muteBars == preset.muteBars;

              return GestureDetector(
                onTap: () => _applyPreset(metronome, preset),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accent : colors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? colors.accent : colors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        preset.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset.description,
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : colors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _applyPreset(MetronomeProvider metronome, RhythmPreset preset) {
    metronome.setBeatsPerBar(preset.beatsPerBar);
    metronome.setPlayBars(preset.playBars);
    metronome.setMuteBars(preset.muteBars);
    if (preset.suggestedBpm != null) {
      metronome.setBpm(preset.suggestedBpm!);
    }
  }
}

/// 拍数选择
class BeatsSelector extends StatelessWidget {
  const BeatsSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final metronome = context.watch<MetronomeProvider>();
    final colors = context.watch<ThemeProvider>().colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '每小节拍数',
            style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(12, (i) {
                final beats = i + 1;
                final selected = metronome.beatsPerBar == beats;
                return GestureDetector(
                  onTap: () => metronome.setBeatsPerBar(beats),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? colors.accent : colors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? colors.accent : colors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$beats',
                        style: TextStyle(
                          color: selected ? Colors.white : colors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// 小节循环
class BarMuteControl extends StatelessWidget {
  const BarMuteControl({super.key});

  @override
  Widget build(BuildContext context) {
    final metronome = context.watch<MetronomeProvider>();
    final colors = context.watch<ThemeProvider>().colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '小节循环',
            style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CounterGroup(
                  label: '播放',
                  value: metronome.playBars,
                  onMinus: () => metronome.setPlayBars(metronome.playBars - 1),
                  onPlus: () => metronome.setPlayBars(metronome.playBars + 1),
                ),
              ),
              Container(
                width: 1,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: colors.border,
              ),
              Expanded(
                child: _CounterGroup(
                  label: '静音',
                  value: metronome.muteBars,
                  onMinus: () => metronome.setMuteBars(metronome.muteBars - 1),
                  onPlus: () => metronome.setMuteBars(metronome.muteBars + 1),
                ),
              ),
            ],
          ),
          if (metronome.muteBars == 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Text(
                  '静音为 0 时不启用循环',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CounterGroup extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _CounterGroup({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _CounterBtn(icon: Icons.remove, onTap: onMinus),
            Container(
              width: 44,
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _CounterBtn(icon: Icons.add, onTap: onPlus),
          ],
        ),
      ],
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CounterBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: colors.textSecondary, size: 18),
      ),
    );
  }
}

/// 定时控制
class TimingControl extends StatelessWidget {
  const TimingControl({super.key});

  @override
  Widget build(BuildContext context) {
    final metronome = context.watch<MetronomeProvider>();
    final colors = context.watch<ThemeProvider>().colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '定时控制',
            style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          // 延迟开始
          _TimingRow(
            icon: Icons.timer_outlined,
            label: '延迟开始',
            value: metronome.delayDuration.inSeconds == 0
                ? '关闭'
                : '${metronome.delayDuration.inSeconds} 秒',
            options: const [0, 3, 5, 10, 15, 30, 60],
            selectedValue: metronome.delayDuration.inSeconds,
            formatOption: (v) => v == 0 ? '关闭' : '$v 秒',
            onChanged: (v) => metronome.setDelay(Duration(seconds: v)),
          ),
          const SizedBox(height: 12),
          // 播放时长
          _TimingRow(
            icon: Icons.schedule,
            label: '播放时长',
            value: metronome.playDuration.inMinutes == 0
                ? '持续'
                : '${metronome.playDuration.inMinutes} 分钟',
            options: const [0, 1, 2, 5, 10, 15, 30, 60],
            selectedValue: metronome.playDuration.inMinutes,
            formatOption: (v) => v == 0 ? '持续' : '$v 分钟',
            onChanged: (v) => metronome.setPlayDuration(Duration(minutes: v)),
          ),
          const SizedBox(height: 12),
          // 循环播放
          Row(
            children: [
              Icon(Icons.repeat, color: colors.textMuted, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '循环播放',
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
              ),
              GestureDetector(
                onTap: () => metronome.setContinuousPlay(!metronome.continuousPlay),
                child: Container(
                  width: 48,
                  height: 28,
                  decoration: BoxDecoration(
                    color: metronome.continuousPlay ? colors.accent : colors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: metronome.continuousPlay ? colors.accent : colors.border,
                    ),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 150),
                    alignment: metronome.continuousPlay
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (metronome.playDuration.inMinutes == 0 && !metronome.continuousPlay)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Text(
                  '持续播放模式，需手动停止',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<int> options;
  final int selectedValue;
  final String Function(int) formatOption;
  final void Function(int) onChanged;

  const _TimingRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.selectedValue,
    required this.formatOption,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Row(
      children: [
        Icon(icon, color: colors.textMuted, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
          ),
        ),
        GestureDetector(
          onTap: () => _showPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: colors.textMuted, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final colors = context.watch<ThemeProvider>().colors;
        return Container(
          margin: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == selectedValue;
                    return GestureDetector(
                      onTap: () {
                        onChanged(option);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        color: isSelected ? colors.accent.withValues(alpha: 0.1) : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                formatOption(option),
                                style: TextStyle(
                                  color: isSelected ? colors.accent : colors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check, color: colors.accent, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
