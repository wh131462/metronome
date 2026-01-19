import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'metronome_screen.dart';
import '../utils/web_splash.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _lineController;
  late AnimationController _logoController;

  double _drawProgress = 0.0;
  bool _showLogo = false;

  @override
  void initState() {
    super.initState();

    // Remove web HTML splash screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removeWebSplash();
    });

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // 线条绘制动画
    _lineController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..addListener(() {
        setState(() => _drawProgress = _lineController.value);
      });

    // Logo 动画
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    await _lineController.forward();

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() => _showLogo = true);
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 1000));
    _navigateToHome();
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MetronomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _lineController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A).withOpacity(0.9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildWaveLine(),
            const SizedBox(height: 80),
            _buildLogo(),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveLine() {
    return SizedBox(
      width: 300,
      height: 100,
      child: CustomPaint(
        painter: _PulseLinePainter(
          drawProgress: _drawProgress,
          lineColor: const Color(0xFFFF4757),
          glowColor: const Color(0xFFFF6B7A),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        final opacity = _showLogo ? _logoController.value : 0.0;
        final translateY = 30.0 * (1 - Curves.easeOut.transform(_logoController.value));

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Column(
              children: [
                Text(
                  'Metronome',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 36,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 10,
                  ),
                ),
                const SizedBox(height: 20),
                // 描述词
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTag('TEMPO'),
                    _buildDot(),
                    _buildTag('RHYTHM'),
                    _buildDot(),
                    _buildTag('FLOW'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTag(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.35),
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFFF4757).withOpacity(0.5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _PulseLinePainter extends CustomPainter {
  final double drawProgress;
  final Color lineColor;
  final Color glowColor;

  _PulseLinePainter({
    required this.drawProgress,
    required this.lineColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    const startX = 20.0;
    final endX = size.width - 20;
    final totalWidth = endX - startX;

    // 波形参数
    const waveStartRatio = 0.25;
    const waveEndRatio = 0.75;
    const peakCount = 4;
    const amplitude = 35.0;

    // 计算当前绘制位置
    final currentX = startX + totalWidth * drawProgress;

    // 构建路径
    final path = Path();
    path.moveTo(startX, centerY);

    // 生成路径点
    const steps = 200;
    for (int i = 0; i <= steps; i++) {
      final ratio = i / steps;
      if (ratio > drawProgress) break;

      final x = startX + totalWidth * ratio;
      var y = centerY;

      // 在波形区域内产生折角波动
      if (ratio >= waveStartRatio && ratio <= waveEndRatio) {
        final waveRatio = (ratio - waveStartRatio) / (waveEndRatio - waveStartRatio);
        // 三角波形（折角效果）
        final wavePhase = waveRatio * peakCount * 2;
        final triangleWave = (wavePhase % 2 < 1)
            ? (wavePhase % 2) * 2 - 1
            : 1 - ((wavePhase % 2) - 1) * 2;

        // 波形包络（两端渐弱）
        final envelope = math.sin(waveRatio * math.pi);

        y = centerY - triangleWave * amplitude * envelope;
      }

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // 绘制线条发光
    if (drawProgress > 0) {
      final glowPaint = Paint()
        ..color = glowColor.withOpacity(0.3)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawPath(path, glowPaint);
    }

    // 绘制主线条
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // 绘制线头发光点
    if (drawProgress > 0 && drawProgress < 1) {
      final headX = currentX;
      var headY = centerY;

      // 计算线头 Y 位置
      final ratio = drawProgress;
      if (ratio >= waveStartRatio && ratio <= waveEndRatio) {
        final waveRatio = (ratio - waveStartRatio) / (waveEndRatio - waveStartRatio);
        final wavePhase = waveRatio * peakCount * 2;
        final triangleWave = (wavePhase % 2 < 1)
            ? (wavePhase % 2) * 2 - 1
            : 1 - ((wavePhase % 2) - 1) * 2;
        final envelope = math.sin(waveRatio * math.pi);
        headY = centerY - triangleWave * amplitude * envelope;
      }

      // 外层大光晕
      final outerGlow = Paint()
        ..color = glowColor.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(Offset(headX, headY), 15, outerGlow);

      // 内层光晕
      final innerGlow = Paint()
        ..color = lineColor.withOpacity(0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(headX, headY), 8, innerGlow);

      // 核心亮点
      final corePaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(headX, headY), 3, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseLinePainter oldDelegate) {
    return oldDelegate.drawProgress != drawProgress;
  }
}
