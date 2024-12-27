import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/metronome_provider.dart';

class TimingControlPanel extends StatelessWidget {
  const TimingControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('定时控制'),
      leading: const Icon(Icons.timer),
      children: [
        const DelayControl(),
        const DurationControl(),
        const ContinuousPlayControl(),
      ],
    );
  }
}

class DelayControl extends StatelessWidget {
  const DelayControl({super.key});

  @override
  Widget build(BuildContext context) {
    final metronome = context.watch<MetronomeProvider>();

    return ListTile(
      leading: const Icon(Icons.timer_outlined),
      title: const Text('延迟开始'),
      subtitle: Text('${metronome.delayDuration.inSeconds} 秒'),
      trailing: SizedBox(
        width: 120,
        child: DropdownButton<int>(
          isExpanded: true,
          value: metronome.delayDuration.inSeconds,
          items: [0, 3, 5, 10, 15, 30, 60].map((seconds) {
            return DropdownMenuItem(
              value: seconds,
              child: Text('$seconds 秒'),
            );
          }).toList(),
          onChanged: (seconds) {
            if (seconds != null) {
              metronome.setDelay(Duration(seconds: seconds));
            }
          },
        ),
      ),
    );
  }
}

class DurationControl extends StatelessWidget {
  const DurationControl({super.key});

  @override
  Widget build(BuildContext context) {
    final metronome = context.watch<MetronomeProvider>();

    return ListTile(
      leading: const Icon(Icons.schedule),
      title: const Text('播放时长'),
      subtitle: Text(
        metronome.playDuration.inSeconds == 0 
            ? '持续播放' 
            : '${metronome.playDuration.inMinutes} 分钟'
      ),
      trailing: SizedBox(
        width: 120,
        child: DropdownButton<int>(
          isExpanded: true,
          value: metronome.playDuration.inMinutes,
          items: [0, 1, 2, 5, 10, 15, 30, 60].map((minutes) {
            return DropdownMenuItem(
              value: minutes,
              child: Text(minutes == 0 ? '持续' : '$minutes 分钟'),
            );
          }).toList(),
          onChanged: (minutes) {
            if (minutes != null) {
              metronome.setPlayDuration(Duration(minutes: minutes));
            }
          },
        ),
      ),
    );
  }
}

class ContinuousPlayControl extends StatelessWidget {
  const ContinuousPlayControl({super.key});

  @override
  Widget build(BuildContext context) {
    final metronome = context.watch<MetronomeProvider>();

    return ListTile(
      leading: const Icon(Icons.repeat),
      title: const Text('循环播放'),
      subtitle: const Text('播放结束后重新开始'),
      trailing: Switch(
        value: metronome.continuousPlay,
        onChanged: metronome.setContinuousPlay,
      ),
    );
  }
} 