class TimeSignature {
  final int beats;       // 每小节的拍数
  final int beatUnit;    // 以几分音符为一拍
  final String name;     // 拍号名称（可选）

  const TimeSignature({
    required this.beats,
    required this.beatUnit,
    this.name = '',
  });

  String get display => '$beats/$beatUnit';

  @override
  String toString() => name.isEmpty ? display : '$name ($display)';
} 