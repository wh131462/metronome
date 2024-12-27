import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../painters/metronome_painter.dart';
import '../providers/metronome_provider.dart';
import '../widgets/timing_control_panel.dart';

class MetronomeScreen extends StatelessWidget {
  const MetronomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const MetronomeDisplay(),
              const TempoControl(),
              const BeatsControl(),
              const TimingControlPanel(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: PlayButton(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class MetronomeDisplay extends StatelessWidget {
  const MetronomeDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final metronome = context.watch<MetronomeProvider>();
    
    return Container(
      height: 300,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        painter: MetronomePainter(
          currentBeat: metronome.currentBeat,
          totalBeats: metronome.timeSignature.beats,
          angle: metronome.pendulumAngle,
        ),
      ),
    );
  }
}

// 添加 BPM 控制滑块
class TempoControl extends StatelessWidget {
  const TempoControl({super.key});

  @override
  Widget build(BuildContext context) {
    final metronome = context.watch<MetronomeProvider>();

    return Column(
      children: [
        Text(
          '${metronome.bpm} BPM',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Slider(
          value: metronome.bpm.toDouble(),
          min: 30,
          max: 250,
          divisions: 220,
          onChanged: (value) => metronome.setBpm(value.round()),
        ),
      ],
    );
  }
}

// 添加拍号选择器
class BeatsControl extends StatelessWidget {
  const BeatsControl({super.key});

  @override
  Widget build(BuildContext context) {
    final metronome = context.watch<MetronomeProvider>();

    return Column(
      children: [
        Text(
          '拍号',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final timeSignature in metronome.timeSignatures)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(timeSignature.display),
                        if (timeSignature.name.isNotEmpty)
                          Text(
                            timeSignature.name,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                    selected: metronome.timeSignature == timeSignature,
                    onSelected: (selected) {
                      if (selected) {
                        metronome.setTimeSignature(timeSignature);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// 添加播放按钮
class PlayButton extends StatelessWidget {
  const PlayButton({super.key});

  @override
  Widget build(BuildContext context) {
    final metronome = context.watch<MetronomeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: metronome.togglePlaying,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getButtonColor(context, metronome),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          icon: Icon(_getButtonIcon(metronome)),
          label: Text(
            _getButtonText(metronome),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getButtonColor(BuildContext context, MetronomeProvider metronome) {
    if (metronome.isDelaying) {
      return Colors.orange;
    }
    return metronome.isPlaying 
        ? Colors.red 
        : Theme.of(context).primaryColor;
  }

  IconData _getButtonIcon(MetronomeProvider metronome) {
    if (metronome.isDelaying) {
      return Icons.timer_outlined;
    }
    return metronome.isPlaying 
        ? Icons.stop_rounded
        : Icons.play_arrow_rounded;
  }

  String _getButtonText(MetronomeProvider metronome) {
    if (metronome.isDelaying) {
      final seconds = metronome.delayDuration.inSeconds;
      return '延迟开始 ($seconds 秒)';
    }
    return metronome.isPlaying ? '停止' : '开始';
  }
}

// 其他组件代码... 