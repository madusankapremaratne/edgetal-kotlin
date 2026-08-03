import 'package:flutter/material.dart';

/// Raw brand palette for EdgeTal.
///
/// A calm, minimal Indigo + Slate system chosen for a European HR / employer
/// audience: trustworthy, enterprise-neutral, and easy on the eyes during long
/// review sessions. Emerald is reserved as the "privacy / on-device" accent.
class AppPalette {
  AppPalette._();

  // EdgeTal Official Brand Palette (extracted from assets/logos/edgetal.png)
  static const Color midnightNavy = Color(0xFF133046);   // #133046 Header/Dark Surface/Primary Text
  static const Color oceanTeal = Color(0xFF4B9CB3);      // #4B9CB3 Primary Interactive Brand Accent
  static const Color softIceBlue = Color(0xFFA9D0E5);     // #A9D0E5 Card Surface Tint & Search Border
  static const Color warmGold = Color(0xFFEFBB47);        // #EFBB47 High Fit Score & Ratings
  static const Color vibrantAmber = Color(0xFFE8842E);    // #E8842E Insights & Action Highlights
  static const Color privacyEmerald = Color(0xFF2E9E5B);  // #2E9E5B 100% On-Device Privacy Badge

  // Brand — Indigo
  static const Color indigo50 = Color(0xFFEEF1FF);
  static const Color indigo100 = Color(0xFFE0E5FF);
  static const Color indigo200 = Color(0xFFC4CDFF);
  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo700 = Color(0xFF4338CA);
  static const Color indigo900 = Color(0xFF312E81);

  // Privacy / success — Emerald
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);

  // Warning — Amber
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);

  // Error — Rose/Red
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);

  // Info — Blue
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);

  // Neutral — Slate
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  static const Color white = Color(0xFFFFFFFF);

  // Dark surfaces (hand-tuned slate-navy, warmer than pure slate-950)
  static const Color darkBg = Color(0xFF0A0E1A);
  static const Color darkSurface = Color(0xFF111726);
  static const Color darkSurfaceSubtle = Color(0x49182030);
  static const Color darkSurfaceElevated = Color(0xFF1B2435);
  static const Color darkBorder = Color(0xFF273449);
}
