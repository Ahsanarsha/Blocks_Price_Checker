import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:blocks_guide/core/theme/app_theme.dart';

/// A modern custom app bar with solid blue background
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isConnected;
  final bool isKioskModeEnabled;
  final VoidCallback onSettingsPressed;
  final VoidCallback? onDoubleTap;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.isConnected,
    this.isKioskModeEnabled = false,
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
          color: AppColors.primaryBlue,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.3),
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

                // Settings button with kiosk mode indicator
                _SettingsButton(
                  onPressed: onSettingsPressed,
                  isKioskModeEnabled: isKioskModeEnabled,
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
  final bool isKioskModeEnabled;

  const _SettingsButton({
    required this.onPressed,
    required this.isKioskModeEnabled,
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
            color: isKioskModeEnabled
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10.r),
            border: isKioskModeEnabled
                ? Border.all(
                    color: AppColors.success.withValues(alpha: 0.5),
                    width: 1.5,
                  )
                : null,
          ),
          child: Icon(
            isKioskModeEnabled ? Icons.lock_rounded : Icons.settings_rounded,
            color: isKioskModeEnabled ? AppColors.success : AppColors.white,
            size: 16.sp,
          ),
        ),
      ),
    );
  }
}
