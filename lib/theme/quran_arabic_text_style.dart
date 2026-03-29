import 'package:flutter/material.dart';

import 'alfawz_colors.dart';

/// Police **Uthmanic Hafs v18** (Quran Foundation — même ligne que quran.com en mode Unicode).
///
/// Source : https://verses.quran.foundation/fonts/quran/hafs/uthmanic_hafs/UthmanicHafs1Ver18.ttf
class QuranArabicStyle {
  QuranArabicStyle._();

  static const String fontFamily = 'UthmanicHafs';

  static TextStyle ayah(double fontSize, {Color? color, double height = 1.9}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: height,
      color: color ?? AlfawzColors.onSurface,
    );
  }
}
