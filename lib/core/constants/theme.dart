import 'package:flutter/material.dart';

/// Warna utama Fina
class FinaColors {
  FinaColors._();

  static const bg = Color(0xFF0C0E13);
  static const surface = Color(0xFF13161C);
  static const surface2 = Color(0xFF1A1E27);
  static const glass = Color(0x0AFFFFFF);
  static const border = Color(0x12FFFFFF);

  static const copper = Color(0xFFC8783A);
  static const copper2 = Color(0xFFE8945A);
  static const cream = Color(0xFFF0E6CF);
  static const cream2 = Color(0xFFC8B89A);

  static const green = Color(0xFF4CAF82);
  static const red = Color(0xFFE05C5C);
  static const blue = Color(0xFF5B8EE6);
  static const purple = Color(0xFFA078DC);

  static const text = Color(0xFFF0E6CF);
  static const text2 = Color(0x8CF0E6CF);
  static const muted = Color(0x59F0E6CF);

  static const icCopper = Color(0x26C8783A);
  static const icGreen = Color(0x264CAF82);
  static const icRed = Color(0x1FE05C5C);
  static const icBlue = Color(0x215B8EE6);
  static const icPurple = Color(0x21A078DC);

  static const pillGreen = Color(0x264CAF82);
  static const pillRed = Color(0x26E05C5C);
  static const pillCopper = Color(0x26C8783A);
  static const pillBlue = Color(0x265B8EE6);
}

class FinaTheme {
  FinaTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: FinaColors.bg,
        colorScheme: const ColorScheme.dark(
          surface: FinaColors.surface,
          primary: FinaColors.copper,
          secondary: FinaColors.copper2,
          error: FinaColors.red,
          onSurface: FinaColors.text,
          onPrimary: Colors.white,
        ),
        // Font fallback ke sistem jika DMSans belum di-setup
        // Ganti ke 'DMSans' setelah menambahkan file font
        fontFamily: null,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: FinaColors.text,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: FinaColors.text,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: FinaColors.text,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: FinaColors.text,
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: FinaColors.text,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: FinaColors.text),
          bodyMedium: TextStyle(fontSize: 14, color: FinaColors.text),
          bodySmall: TextStyle(fontSize: 12, color: FinaColors.text2),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: FinaColors.text2,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: FinaColors.bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: FinaColors.text),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: FinaColors.text,
          ),
        ),
        cardTheme: CardThemeData(
          color: FinaColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            side: BorderSide(color: FinaColors.border),
          ),
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: FinaColors.border,
          thickness: 1,
          space: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xE60D0F14),
          selectedItemColor: FinaColors.copper,
          unselectedItemColor: FinaColors.text2,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: FinaColors.surface2,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FinaColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FinaColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FinaColors.copper, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FinaColors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: FinaColors.red, width: 1.5),
          ),
          labelStyle: const TextStyle(color: FinaColors.text2, fontSize: 14),
          hintStyle: const TextStyle(color: FinaColors.muted, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: FinaColors.copper,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: FinaColors.text,
            side: const BorderSide(color: FinaColors.border),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: FinaColors.surface2,
          contentTextStyle: const TextStyle(color: FinaColors.text),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
