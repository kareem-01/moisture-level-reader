import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'App.dart';

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  Future.delayed(Duration(milliseconds: 600)).then((_) {
    FlutterNativeSplash.remove();
  });
  runApp(const App());
}
