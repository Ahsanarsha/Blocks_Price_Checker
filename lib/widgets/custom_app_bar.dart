import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:blocks_guide/core/theme/app_theme.dart';

/// A modern custom app bar with gradient background
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color topColor;
  final Color bottomColor;
  final bool isConnected;
  final VoidCallback onSettingsPressed;
  final VoidCallback? onDoubleTap;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.topColor,
    required this.bottomColor,
    required this.isConnected,
    required this.onSettingsPressed,
    this.onDoubleTap,
  });

  @override
  Size get preferredSize => Size.fromHeight(50.h);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [topColor, bottomColor],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          child: Row(
            children: [
              // Logo/Icon area
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.white,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),

              // Title
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              // Connection status indicator
              _ConnectionIndicator(isConnected: isConnected),
              SizedBox(width: 10.w),

              // Settings button
              _SettingsButton(
                onPressed: onSettingsPressed,
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  final bool isConnected;

  const _ConnectionIndicator({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: (isConnected ? AppColors.success : AppColors.error)
            .withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: (isConnected ? AppColors.success : AppColors.error)
              .withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: isConnected ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isConnected ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: 5.w),
          Text(
            isConnected ? 'Connected' : 'Offline',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 6.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SettingsButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.settings_rounded,
            color: AppColors.white,
            size: 16.sp,
          ),
        ),
      ),
    );
  }
}
