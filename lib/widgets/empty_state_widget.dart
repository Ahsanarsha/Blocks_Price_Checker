import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:blocks_guide/core/theme/app_theme.dart';

/// Modern empty state widget displayed when no product is scanned
class EmptyStateWidget extends StatelessWidget {
  final bool isConnected;

  const EmptyStateWidget({
    super.key,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.cardDecoration,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon container with gradient
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isConnected
                          ? [AppColors.accentBlue.withValues(alpha: 0.2), AppColors.accentTeal.withValues(alpha: 0.2)]
                          : [AppColors.error.withValues(alpha: 0.2), AppColors.errorLight.withValues(alpha: 0.2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isConnected ? Icons.qr_code_scanner_rounded : Icons.cloud_off_rounded,
                    size: 32.sp,
                    color: isConnected ? AppColors.accentBlue : AppColors.error,
                  ),
                ),
                SizedBox(height: 12.h),

                // Title
                Text(
                  isConnected ? 'Ready to Scan' : 'Not Connected',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? AppColors.textPrimary : AppColors.error,
                  ),
                ),
                SizedBox(height: 6.h),

                // Description
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Text(
                    isConnected
                        ? 'Scan a product barcode or QR code to view pricing information'
                        : 'Please connect to your database server to start scanning products',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8.sp,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),

                if (!isConnected) ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 10.sp,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Tap settings to configure connection',
                          style: TextStyle(
                            fontSize: 6.sp,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
