import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// App color palette - Clean, modern, professional colors
class AppColors {
  // Primary gradient colors - Clean dark blue theme
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color primaryMedium = Color(0xFF1E293B);
  static const Color primaryLight = Color(0xFF334155);

  // Accent colors - Fresh blue and teal
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentCyan = Color(0xFF06B6D4);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color warning = Color(0xFFF59E0B);

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shadowColor = Color(0x1A000000);

  // Gradient color sets for animated background - Clean blue tones
  static const List<List<Color>> gradientSets = [
    [Color(0xFF0F172A), Color(0xFF1E3A5F)],
    [Color(0xFF1E293B), Color(0xFF0F4C75)],
    [Color(0xFF0F172A), Color(0xFF1E293B)],
    [Color(0xFF1E3A5F), Color(0xFF0F172A)],
    [Color(0xFF0F4C75), Color(0xFF1E293B)],
  ];
}

/// App text styles
class AppTextStyles {
  static TextStyle get heading1 => TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    letterSpacing: 0.5,
  );

  static TextStyle get heading2 => TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  static TextStyle get heading3 => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: 10.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: 8.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static TextStyle get priceMain => TextStyle(
    fontSize: 32.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.success,
    letterSpacing: -0.5,
  );

  static TextStyle get priceLabel => TextStyle(
    fontSize: 10.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle get productName => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get scannerHint => TextStyle(
    fontSize: 8.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.white.withValues(alpha: 0.9),
  );
}

/// App decorations and shadows
class AppDecorations {
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(20.r),
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadowColor,
        blurRadius: 16,
        offset: Offset(0, 4),
        spreadRadius: 0,
      ),
    ],
  );

  static BoxDecoration get cardDecorationElevated => BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(20.r),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryDark.withValues(alpha: 0.12),
        blurRadius: 24,
        offset: const Offset(0, 8),
        spreadRadius: 2,
      ),
    ],
  );

  static BoxDecoration inputDecoration({bool isFocused = false}) => BoxDecoration(
    color: AppColors.white.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(12.r),
    border: Border.all(
      color: isFocused
          ? AppColors.accentTeal
          : AppColors.white.withValues(alpha: 0.25),
      width: isFocused ? 2 : 1,
    ),
  );

  static LinearGradient backgroundGradient(Color topColor, Color bottomColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [topColor, bottomColor],
      stops: const [0.0, 1.0],
    );
  }

  static BoxDecoration get priceTagDecoration => BoxDecoration(
    gradient: const LinearGradient(
      colors: [AppColors.success, AppColors.successLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(14.r),
    boxShadow: [
      BoxShadow(
        color: AppColors.success.withValues(alpha: 0.25),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get specialPriceDecoration => BoxDecoration(
    gradient: const LinearGradient(
      colors: [AppColors.error, AppColors.errorLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12.r),
    boxShadow: [
      BoxShadow(
        color: AppColors.error.withValues(alpha: 0.25),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

/// App spacing constants
class AppSpacing {
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
  static double get xxl => 48.w;
}

/// App animation durations
class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 700);
  static const Duration gradient = Duration(milliseconds: 2000);
}
