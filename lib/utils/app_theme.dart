import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // رنگ‌های اصلی - پالت مینیمال و آرام
  static const Color primaryColor = Color(0xFF2196F3); // آبی روشن
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFFBBDEFB);

  static const Color secondaryColor = Color(0xFF4CAF50); // سبز
  static const Color secondaryDark = Color(0xFF388E3C);
  static const Color secondaryLight = Color(0xFFC8E6C9);

  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);

  // رنگ‌های متن
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // رنگ‌های مرز و تقسیم‌کننده
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color borderColor = Color(0xFFBDBDBD);

  // تنظیم ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // رنگ‌بندی
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLight,
        secondary: secondaryColor,
        secondaryContainer: secondaryLight,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: textOnPrimary,
        onSecondary: textOnPrimary,
        onSurface: textPrimary,
        onError: textOnPrimary,
      ),

      scaffoldBackgroundColor: backgroundColor,

      // فونت فارسی با Google Fonts
      textTheme: _buildTextTheme(),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.vazirmatn(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button Themes
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),

      // Input Decoration Theme
      inputDecorationTheme: _buildInputDecorationTheme(),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: textSecondary, size: 24),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 4,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.vazirmatn(
          fontSize: 14,
          color: textOnPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        titleTextStyle: GoogleFonts.vazirmatn(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.vazirmatn(
          fontSize: 16,
          color: textSecondary,
        ),
      ),
    );
  }

  // Text Theme با فونت فارسی
  static TextTheme _buildTextTheme() {
    return TextTheme(
      // Heading 1 - عناوین بزرگ
      displayLarge: GoogleFonts.vazirmatn(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.5,
      ),

      // Heading 2 - عناوین متوسط
      displayMedium: GoogleFonts.vazirmatn(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.5,
      ),

      // Heading 3 - عناوین کوچک
      displaySmall: GoogleFonts.vazirmatn(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.5,
      ),

      // Headline - عناوین بخش‌ها
      headlineMedium: GoogleFonts.vazirmatn(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.4,
      ),

      // Title - عناوین کارت‌ها
      titleLarge: GoogleFonts.vazirmatn(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.4,
      ),

      titleMedium: GoogleFonts.vazirmatn(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.4,
      ),

      titleSmall: GoogleFonts.vazirmatn(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.4,
      ),

      // Body - متن اصلی
      bodyLarge: GoogleFonts.vazirmatn(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimary,
        height: 1.6,
      ),

      bodyMedium: GoogleFonts.vazirmatn(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textPrimary,
        height: 1.6,
      ),

      bodySmall: GoogleFonts.vazirmatn(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textSecondary,
        height: 1.6,
      ),

      // Label - برچسب‌ها و دکمه‌ها
      labelLarge: GoogleFonts.vazirmatn(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.4,
      ),

      labelMedium: GoogleFonts.vazirmatn(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        height: 1.4,
      ),

      labelSmall: GoogleFonts.vazirmatn(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        height: 1.4,
      ),
    );
  }

  // Elevated Button Theme
  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.vazirmatn(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Outlined Button Theme
  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: const BorderSide(color: primaryColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.vazirmatn(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Text Button Theme
  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: GoogleFonts.vazirmatn(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Input Decoration Theme
  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      // Border - حالت عادی
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),

      // Enabled Border
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),

      // Focused Border
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),

      // Error Border
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),

      // Focused Error Border
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),

      // Label Style
      labelStyle: GoogleFonts.vazirmatn(fontSize: 14, color: textSecondary),

      // Floating Label Style
      floatingLabelStyle: GoogleFonts.vazirmatn(
        fontSize: 14,
        color: primaryColor,
      ),

      // Hint Style
      hintStyle: GoogleFonts.vazirmatn(fontSize: 14, color: textDisabled),

      // Error Style
      errorStyle: GoogleFonts.vazirmatn(fontSize: 12, color: errorColor),

      // Helper Style
      helperStyle: GoogleFonts.vazirmatn(fontSize: 12, color: textSecondary),
    );
  }
}
