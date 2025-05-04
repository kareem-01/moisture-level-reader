import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFE1F4FB);
  static const Color darkGrey = Color.fromARGB(255, 45, 45, 45);
  static const Color background = Color(0xFFF5F5F5);
  static const Color transparent = Colors.transparent;
  static const Color navigationBorder = Color.fromARGB(0, 255, 255, 255);
  static const Color grey = Color.fromARGB(255, 139, 139, 139);
  static Color onBackground = Color.fromARGB(255, 255, 255, 255);

  static Color get shadowColor => grey.withValues(alpha: 0.3);

  static Color get text => AppColors.darkGrey;

  static Color get seedColor => onBackground;
}
