import 'package:flutter/material.dart';

class AppTheme {
  // Purple colors from Tawfik logo (الهوية البصرية — ثابتة في الوضعين)
  static const Color primaryPurple = Color(0xFF7B2CBF);
  static const Color lightPurple = Color(0xFF9D4EDD);
  static const Color darkPurple = Color(0xFF5A189A);
  static const Color accentPurple = Color(0xFFC77DFF);

  // Status colors (ثابتة في الوضعين)
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);

  // ── ألوان الوضع الفاتح ──────────────────────────────────────────────
  static const Color _lightBackground = Color(0xFFF8F9FA);
  static const Color _lightSurface = Colors.white;
  static const Color _lightTextPrimary = Color(0xFF212529);
  static const Color _lightTextSecondary = Color(0xFF6C757D);
  static const Color _lightBorder = Color(0xFFDEE2E6);

  // ── ألوان الوضع الليلي ──────────────────────────────────────────────
  static const Color _darkBackground = Color(0xFF14121C);
  static const Color _darkSurface = Color(0xFF1F1B2E);
  static const Color _darkTextPrimary = Color(0xFFF2EEFA);
  static const Color _darkTextSecondary = Color(0xFFA89FC2);
  static const Color _darkBorder = Color(0xFF35304A);

  // الألوان المتبدّلة حسب الوضع تُقرأ من السياق عبر `context.appColors`
  // (انظر [AppColors] و[AppColorsContext] في أسفل الملف). الاعتماد على
  // `Theme.of(context)` يضمن إعادة بناء كل الشاشات فور تبديل الثيم.

  static ThemeData get lightTheme => _build(dark: false);
  static ThemeData get darkTheme => _build(dark: true);

  static ThemeData _build({required bool dark}) {
    final bg = dark ? _darkBackground : _lightBackground;
    final surface = dark ? _darkSurface : _lightSurface;
    final txtPrimary = dark ? _darkTextPrimary : _lightTextPrimary;
    final txtSecondary = dark ? _darkTextSecondary : _lightTextSecondary;
    final brd = dark ? _darkBorder : _lightBorder;

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      fontFamily: 'IBMPlexSansArabic',
      scaffoldBackgroundColor: bg,

      extensions: <ThemeExtension<dynamic>>[
        dark ? AppColors.dark : AppColors.light,
      ],

      colorScheme: (dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: primaryPurple,
        secondary: accentPurple,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: txtPrimary,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: txtPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
      ),

      dividerColor: brd.withOpacity(0.5),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryPurple.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryPurple,
          side: const BorderSide(color: primaryPurple, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brd),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brd, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryPurple, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 2.5),
        ),
        labelStyle: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          color: txtSecondary,
          fontSize: 15,
        ),
        hintStyle: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          color: txtSecondary.withOpacity(0.6),
          fontSize: 15,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryPurple,
        unselectedItemColor: txtSecondary,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'IBMPlexSansArabic',
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: txtPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: txtPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 16,
          color: txtPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 14,
          color: txtPrimary,
        ),
        bodySmall: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 12,
          color: txtSecondary,
        ),
      ),
    );
  }
}

/// الألوان المتبدّلة حسب الوضع (فاتح/ليلي). تُسجَّل كـ ThemeExtension في كل
/// من [AppTheme.lightTheme] و[AppTheme.darkTheme]، وتُقرأ في الشاشات عبر
/// `context.appColors`. لأنها تمرّ عبر `Theme.of(context)` تُعاد بناء كل
/// عنصر يستعملها تلقائياً عند تبديل الثيم.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color cardBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  const AppColors({
    required this.background,
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  static const AppColors light = AppColors(
    background: AppTheme._lightBackground,
    cardBackground: AppTheme._lightSurface,
    textPrimary: AppTheme._lightTextPrimary,
    textSecondary: AppTheme._lightTextSecondary,
    border: AppTheme._lightBorder,
  );

  static const AppColors dark = AppColors(
    background: AppTheme._darkBackground,
    cardBackground: AppTheme._darkSurface,
    textPrimary: AppTheme._darkTextPrimary,
    textSecondary: AppTheme._darkTextSecondary,
    border: AppTheme._darkBorder,
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? cardBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
  }) {
    return AppColors(
      background: background ?? this.background,
      cardBackground: cardBackground ?? this.cardBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  /// الألوان المتبدّلة حسب الوضع الحالي للثيم.
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
