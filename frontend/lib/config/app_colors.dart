import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const brandRed = Color(0xFFCF0109);
  static const appBar = Color(0xFF222222);
  static final lightScheme = ColorScheme.fromSeed(
    seedColor: brandRed,
    brightness: Brightness.light,
  );
}
