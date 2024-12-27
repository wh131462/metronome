import 'dart:math';
import 'package:flutter/material.dart';

class MetronomePainter extends CustomPainter {
  final int currentBeat;
  final int totalBeats;
  final double angle;

  MetronomePainter({
    required this.currentBeat,
    required this.totalBeats,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.8);
    final length = size.height * 0.7;
    
    // 绘制外壳阴影
    final shadowPath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.9)
      ..lineTo(size.width * 0.8, size.height * 0.9)
      ..lineTo(size.width * 0.65, size.height * 0.1)
      ..lineTo(size.width * 0.35, size.height * 0.1)
      ..close();

    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 绘制木纹底色
    final baseWoodPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.brown[800]!,
          Colors.brown[600]!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(shadowPath, baseWoodPaint);

    // 绘制木纹纹理
    final grainPaint = Paint()
      ..color = Colors.brown[900]!.withOpacity(0.1)
      ..strokeWidth = 1;

    final random = Random(42); // 固定种子以保持纹理一致
    for (int i = 0; i < 100; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final length = random.nextDouble() * 50 + 20;
      final angle = random.nextDouble() * pi / 6 - pi / 12;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(
          startX + cos(angle) * length,
          startY + sin(angle) * length,
        ),
        grainPaint,
      );
    }

    // 绘制高光效果
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(shadowPath, highlightPaint);

    // 绘制刻度背景
    _drawTicksBackground(canvas, size);
    
    // 绘制刻度
    _drawTicks(canvas, size);

    // 绘制摆针
    _drawPendulum(canvas, size, center, length);
  }

  void _drawTicksBackground(Canvas canvas, Size size) {
    final ticksBgPaint = Paint()
      ..color = Colors.brown[900]!
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.18,
        size.width * 0.5,
        size.height * 0.1,
      ),
      ticksBgPaint,
    );
  }

  void _drawTicks(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2;

    // 主要刻度
    for (int i = 0; i <= 8; i++) {
      final x = size.width * (0.3 + i * 0.05);
      final height = i % 2 == 0 ? size.height * 0.06 : size.height * 0.04;
      canvas.drawLine(
        Offset(x, size.height * 0.2),
        Offset(x, size.height * 0.2 + height),
        tickPaint,
      );
    }
  }

  void _drawPendulum(Canvas canvas, Size size, Offset center, double length) {
    // 绘制摆针支点
    final pivotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, pivotPaint);

    // 绘制摆针
    final needlePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // 调整摆针的绘制位置，使其垂直向上时角度为0
    final needleEnd = Offset(
      center.dx + length * sin(angle),
      center.dy - length * cos(angle),
    );

    canvas.drawLine(center, needleEnd, needlePaint);

    // 绘制重锤
    final weightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.grey[800]!,
          Colors.black,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          center.dx + (length * 0.7) * sin(angle),
          center.dy - (length * 0.7) * cos(angle),
        ),
        radius: 12,
      ));

    final weightPosition = Offset(
      center.dx + (length * 0.7) * sin(angle),
      center.dy - (length * 0.7) * cos(angle),
    );
    
    // 绘制重锤阴影
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    canvas.drawCircle(
      weightPosition.translate(2, 2),  // 阴影偏移
      14, 
      shadowPaint
    );
    
    // 绘制重锤本体
    canvas.drawCircle(weightPosition, 12, weightPaint);
  }

  @override
  bool shouldRepaint(MetronomePainter oldDelegate) {
    return oldDelegate.currentBeat != currentBeat ||
        oldDelegate.angle != angle;
  }
} 