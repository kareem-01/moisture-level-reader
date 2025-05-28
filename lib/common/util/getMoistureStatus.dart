import 'package:flutter/material.dart';

Color getMoistureColor(double value) {
  if (value < 30) {
    return Colors.red;
  } else if (value < 60) {
    return Colors.orange;
  } else {
    return Colors.green;
  }
}