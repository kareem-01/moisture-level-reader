import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

showToast(String? message, {Color? bg}) {
  Fluttertoast.showToast(
    gravity: ToastGravity.TOP,
    backgroundColor: bg ?? Colors.black,
    textColor: Colors.white,
    msg: message.toString(),
    toastLength: Toast.LENGTH_SHORT,
    timeInSecForIosWeb: 2,
  );
}

showErrorToast(String message) {
  showToast(message, bg: Colors.red);
}

showSuccessToast(String message) {
  showToast(message, bg: Colors.green);
}