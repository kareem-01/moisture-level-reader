import 'package:flutter/services.dart';

class SystemBarsUtil {
  static Color? _statusBarColor, _navBarColor;
  static Brightness? _statusBarBrightness,
      _navBarBrightness,
      _statusBarIconBrightness;
  static bool? _isBlackIcons;

  static void changeStatusBarColor(Color color, {bool? isBlackIcons}) {
    _statusBarColor = color;
    _setColors(isBlackIcons);
  }
  static void changeNavigationBar(Color color, {bool? isBlackIcons}) {
    _navBarColor = color;
    _setColors(isBlackIcons);
  }

  static void changeStatusAndNavigationBars(
      {Color? navBarColor, Color? statusBarColor, bool? isBlackIcons}) {
    if (navBarColor != null) {
      _navBarColor = navBarColor;
    }
    if (statusBarColor != null) {
      _statusBarColor = statusBarColor;
    }
    _setColors(isBlackIcons);
  }

  static void _setColors(bool? isBlackIcons) {
    if (isBlackIcons != null) {
      _isBlackIcons = isBlackIcons;
      _navBarBrightness =
          (_isBlackIcons ?? true) ? Brightness.light : Brightness.dark;
      _statusBarIconBrightness =
          (_isBlackIcons ?? true) ? Brightness.dark : Brightness.light;
      _statusBarBrightness =
          (_isBlackIcons ?? true) ? Brightness.light : Brightness.dark;
    }

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: _navBarColor,
      systemNavigationBarIconBrightness: _navBarBrightness,
      statusBarColor: _statusBarColor,
      statusBarIconBrightness: _statusBarIconBrightness,
      statusBarBrightness: _statusBarBrightness,
    ));
  }
}
