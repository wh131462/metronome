import 'package:flutter/material.dart';

/// 主题颜色配置
class AppColors {
  final Color background;
  final Color cardBackground;
  final Color cardBackgroundAlt;
  final Color border;
  final Color borderLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentGreen;
  final Color accentPurple;
  final Color accentOrange;
  final Color beatInactive;
  final Color beatBorder;

  const AppColors({
    required this.background,
    required this.cardBackground,
    required this.cardBackgroundAlt,
    required this.border,
    required this.borderLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentGreen,
    required this.accentPurple,
    required this.accentOrange,
    required this.beatInactive,
    required this.beatBorder,
  });

  /// 暗黑主题
  static const dark = AppColors(
    background: Color(0xFF0D0D1A),
    cardBackground: Color(0xFF1A1A2E),
    cardBackgroundAlt: Color(0xFF16213E),
    border: Color(0xFF2A3A5A),
    borderLight: Color(0x0DFFFFFF),
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    textMuted: Colors.white38,
    accent: Color(0xFFFF4757),
    accentGreen: Color(0xFF2ED573),
    accentPurple: Color(0xFF5352ED),
    accentOrange: Colors.orange,
    beatInactive: Color(0xFF1E2A4A),
    beatBorder: Color(0xFF2A3A5A),
  );

  /// 亮色主题
  static const light = AppColors(
    background: Color(0xFFF5F5F7),
    cardBackground: Colors.white,
    cardBackgroundAlt: Color(0xFFE8E8ED),
    border: Color(0xFFD0D0D5),
    borderLight: Color(0x15000000),
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF4A4A5A),
    textMuted: Color(0xFF8A8A9A),
    accent: Color(0xFFFF4757),
    accentGreen: Color(0xFF00B894),
    accentPurple: Color(0xFF6C5CE7),
    accentOrange: Color(0xFFFF9F43),
    beatInactive: Color(0xFFE0E0E8),
    beatBorder: Color(0xFFD0D0D8),
  );
}

/// 主题管理 Provider
class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;
  AppColors get colors => _isDarkMode ? AppColors.dark : AppColors.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      notifyListeners();
    }
  }
}
