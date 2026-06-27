import 'package:flutter/material.dart';

class AppColors {
  // App background (warm cream)
  static const Color bg = Color(0xFFF2EFE8);
  
  // Cards, sheets
  static const Color surface = Color(0xFFFFFFFF);
  
  // Filter backgrounds, collapsed sections, sunken fills
  static const Color sunken = Color(0xFFEBE6DB);
  
  // Primary text
  static const Color ink = Color(0xFF1E1B16);
  
  // Secondary text (55%)
  static const Color ink55 = Color(0x8C1E1B16);
  
  // Tertiary text / de-emphasized (40%)
  static const Color ink40 = Color(0x661E1B16);
  
  // Dividers, borders
  static const Color hairline = Color(0xFFE7E2D8);
  
  // Primary action: buttons, active nav, send, grand totals
  static const Color espresso = Color(0xFF221F1A);
  
  // Kitchen zone (orange)
  static const Color kitchen = Color(0xFFE0823A);
  
  // Bar zone (blue)
  static const Color bar = Color(0xFF3C7BCF);
  
  // Ready/OK (green)
  static const Color ok = Color(0xFF3E9C63);
  static const Color ready = Color(0xFF3E9C63);
  
  // Late/danger (red)
  static const Color late = Color(0xFFD9564A);
  static const Color danger = Color(0xFFD9564A);
  
  // Manager / #1 / bonus accents
  static const Color gold = Color(0xFFB98A3C);
  
  // Attention: guest seated (blue)
  static const Color arrived = Color(0xFF3E78C9);
  
  // Attention: calling waiter (amber)
  static const Color call = Color(0xFFE0823A);
  
  // Attention: bill requested (purple)
  static const Color bill = Color(0xFF8A6FC0);
  
  // Free/empty table (grey)
  static const Color free = Color(0xFFB8B1A3);

  // Helper for status tints (15% opacity)
  static Color tint(Color color) => color.withValues(alpha: 0.15);
}
