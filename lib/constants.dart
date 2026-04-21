import 'package:flutter/material.dart';

// 吉卜力風格配色 - 柔和、自然、手繪感
class GameConstants {
  // Grid settings
  static const int gridWidth = 24;
  static const int gridHeight = 24;
  static const double cellSize = 20.0;

  // Game speed
  static const int initialSpeed = 180;
  static const int speedIncrease = 8;

  // Evolution thresholds (score needed to evolve)
  static const int dragonLevel2Score = 30;
  static const int dragonLevel3Score = 80;
  static const int dragonLevel4Score = 150;
  static const int dragonLevel5Score = 250;

  // Ghibli-inspired color palette
  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color forestGreen = Color(0xFF228B22);
  static const Color warmBrown = Color(0xFF8B4513);
  static const Color sunsetOrange = Color(0xFFFF7F50);
  static const Color cloudWhite = Color(0xFFFFF8DC);
  static const Color nightSky = Color(0xFF1A1A2E);
  static const Color grassGreen = Color(0xFF90EE90);
  static const Color riverBlue = Color(0xFF4169E1);
  static const Color mountainPurple = Color(0xFF9370DB);
  static const Color sunYellow = Color(0xFFFFD700);

  // Dragon evolution colors
  static const List<Color> dragonColors = [
    Color(0xFF4CAF50), // Level 1 - 綠色小蛇
    Color(0xFF66BB6A), // Level 2 - 淺綠進化
    Color(0xFF42A5F5), // Level 3 - 藍色飛龍
    Color(0xFFAB47BC), // Level 4 - 紫色神龍
    Color(0xFFFFD700), // Level 5 - 金色龍王
  ];

  // Background gradients for stages
  static List<Color> getBackgroundGradient(int level) {
    switch (level) {
      case 1:
        return [const Color(0xFFFFF8DC), const Color(0xFF90EE90)]; // 草地
      case 2:
        return [const Color(0xFF87CEEB), const Color(0xFF228B22)]; // 森林
      case 3:
        return [const Color(0xFFFF7F50), const Color(0xFF4169E1)]; // 黃昏
      case 4:
        return [const Color(0xFF1A1A2E), const Color(0xFF9370DB)]; // 夜空
      case 5:
        return [const Color(0xFFFFD700), const Color(0xFFFF6347)]; // 龍王光芒
      default:
        return [const Color(0xFFFFF8DC), const Color(0xFF90EE90)];
    }
  }

  static String getDragonName(int level) {
    switch (level) {
      case 1:
        return '小蛇';
      case 2:
        return '青龍';
      case 3:
        return '飛龍';
      case 4:
        return '神龍';
      case 5:
        return '龍王';
      default:
        return '小蛇';
    }
  }
}
