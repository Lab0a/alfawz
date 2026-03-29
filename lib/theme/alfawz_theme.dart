import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'alfawz_colors.dart';

abstract final class AlfawzTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        surface: AlfawzColors.surface,
        onSurface: AlfawzColors.onSurface,
        primary: AlfawzColors.primary,
        onPrimary: AlfawzColors.onPrimary,
        primaryContainer: AlfawzColors.primaryContainer,
        onPrimaryContainer: AlfawzColors.onPrimaryContainer,
        secondary: AlfawzColors.secondary,
        secondaryContainer: AlfawzColors.secondaryContainer,
        onSecondaryContainer: AlfawzColors.onSecondaryContainer,
        tertiary: AlfawzColors.tertiaryContainer,
        tertiaryContainer: AlfawzColors.tertiaryContainer,
        outline: AlfawzColors.outline,
        outlineVariant: AlfawzColors.outlineVariant,
        error: AlfawzColors.error,
        errorContainer: AlfawzColors.errorContainer,
      ),
      scaffoldBackgroundColor: AlfawzColors.surface,
      dividerColor: Colors.transparent,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AlfawzColors.surface.withValues(alpha: 0.82),
        foregroundColor: AlfawzColors.primary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.notoSerif(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AlfawzColors.primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AlfawzColors.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AlfawzColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AlfawzColors.secondary.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
        hintStyle: GoogleFonts.manrope(color: AlfawzColors.outline),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AlfawzColors.primary,
        inactiveTrackColor: AlfawzColors.surfaceContainerHigh,
        thumbColor: AlfawzColors.primary,
        overlayColor: AlfawzColors.primary.withValues(alpha: 0.12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return AlfawzColors.onPrimary;
          return AlfawzColors.surfaceContainerHighest;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return AlfawzColors.primary;
          return AlfawzColors.surfaceContainerHighest;
        }),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: GoogleFonts.notoSerif(
        fontWeight: FontWeight.w700,
        color: AlfawzColors.primary,
      ),
      headlineLarge: GoogleFonts.notoSerif(
        fontWeight: FontWeight.w700,
        color: AlfawzColors.primary,
      ),
      headlineMedium: GoogleFonts.notoSerif(
        fontWeight: FontWeight.w600,
        color: AlfawzColors.onSurface,
      ),
      titleLarge: GoogleFonts.notoSerif(
        fontWeight: FontWeight.w600,
        color: AlfawzColors.primary,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        color: AlfawzColors.onSurfaceVariant,
        height: 1.55,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(color: AlfawzColors.onSurface),
      labelLarge: GoogleFonts.manrope(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AlfawzColors.onSurfaceVariant,
      ),
      labelMedium: GoogleFonts.manrope(
        fontSize: 11,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w700,
        color: AlfawzColors.secondary,
      ),
    );
  }
}
