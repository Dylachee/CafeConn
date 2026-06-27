import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static const String fontMain = 'Inter';
  static const String fontMono = 'JetBrainsMono';

  static TextStyle h1 = const TextStyle(
    fontFamily: fontMain,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: AppColors.ink,
  );

  static TextStyle h2 = const TextStyle(
    fontFamily: fontMain,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: AppColors.ink,
  );

  static TextStyle h3 = const TextStyle(
    fontFamily: fontMain,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.ink,
  );

  static TextStyle body = const TextStyle(
    fontFamily: fontMain,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static TextStyle bodySmall = const TextStyle(
    fontFamily: fontMain,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.ink55,
  );

  static TextStyle label = const TextStyle(
    fontFamily: fontMain,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.ink55,
  );

  static TextStyle mono = const TextStyle(
    fontFamily: fontMono,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );
  
  static TextStyle price = mono.copyWith(fontSize: 16);
  static TextStyle timer = mono.copyWith(fontSize: 14);
}
