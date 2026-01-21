import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:blocks_guide/core/theme/app_theme.dart';

/// Modern product display card with animations
class ProductDisplayCard extends StatelessWidget {
  final String productName;
  final double retailPrice;
  final double? specialPrice;
  final String? mixAndMatch;
  final Uint8List? imageBytes;
  final Animation<double> scaleAnimation;
  final Animation<Color?> colorAnimation;

  const ProductDisplayCard({
    super.key,
    required this.productName,
    required this.retailPrice,
    this.specialPrice,
    this.mixAndMatch,
    this.imageBytes,
    required this.scaleAnimation,
    required this.colorAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.cardDecorationElevated,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Row(
          children: [
            // Product Image Section
            _ProductImageSection(imageBytes: imageBytes),

            // Divider
            Container(
              width: 1,
              height: double.infinity,
              margin: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.divider.withValues(alpha: 0.0),
                    AppColors.divider,
                    AppColors.divider.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),

            // Product Info Section
            Expanded(
              child: _ProductInfoSection(
                productName: productName,
                retailPrice: retailPrice,
                specialPrice: specialPrice,
                mixAndMatch: mixAndMatch,
                scaleAnimation: scaleAnimation,
                colorAnimation: colorAnimation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImageSection extends StatelessWidget {
  final Uint8List? imageBytes;

  const _ProductImageSection({this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: imageBytes != null
              ? Image.memory(
                  imageBytes!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                )
              : Image.asset(
                  'assets/images/sho.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
        ),
      ),
    );
  }
}

class _ProductInfoSection extends StatelessWidget {
  final String productName;
  final double retailPrice;
  final double? specialPrice;
  final String? mixAndMatch;
  final Animation<double> scaleAnimation;
  final Animation<Color?> colorAnimation;

  const _ProductInfoSection({
    required this.productName,
    required this.retailPrice,
    this.specialPrice,
    this.mixAndMatch,
    required this.scaleAnimation,
    required this.colorAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final hasMixMatch = mixAndMatch != null && mixAndMatch!.isNotEmpty;
    final hasSpecialPrice = specialPrice != null && specialPrice != 0.00;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Name
            _ProductNameBadge(name: productName),
            SizedBox(height: 6.h),

            // Retail Price - smaller when special price or mix & match exists, red only when special price exists
            _PriceDisplay(
              label: 'RETAIL PRICE',
              price: retailPrice,
              isSmall: hasSpecialPrice || hasMixMatch,
              useRedColor: hasSpecialPrice,
            ),

            // Mix and Match
            if (hasMixMatch) ...[
              SizedBox(height: 4.h),
              _MixMatchBadge(
                text: mixAndMatch!,
                scaleAnimation: scaleAnimation,
                colorAnimation: colorAnimation,
              ),
            ],

            // Special/Discounted Price - larger and green (hero price)
            if (hasSpecialPrice) ...[
              SizedBox(height: 4.h),
              _SpecialPriceDisplay(
                price: specialPrice!,
                scaleAnimation: scaleAnimation,
                colorAnimation: colorAnimation,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductNameBadge extends StatelessWidget {
  final String name;

  const _ProductNameBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primaryDark.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _PriceDisplay extends StatelessWidget {
  final String label;
  final double price;
  final bool isSmall;
  final bool useRedColor;

  const _PriceDisplay({
    required this.label,
    required this.price,
    this.isSmall = false,
    this.useRedColor = false,
  });

  @override
  Widget build(BuildContext context) {
    // When special price exists: retail becomes smaller and red
    // When no special price: retail is larger and green
    final decoration = useRedColor
        ? AppDecorations.specialPriceDecoration  // Red color
        : AppDecorations.priceTagDecoration;     // Green color

    final dollarSize = isSmall ? 10.sp : 14.sp;
    final priceSize = isSmall ? 14.sp : 22.sp;
    final horizontalPadding = isSmall ? 12.w : 18.w;
    final verticalPadding = isSmall ? 6.h : 10.h;
    final labelSize = isSmall ? 5.sp : 6.sp;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      decoration: decoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.9),
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: dollarSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                price.toStringAsFixed(2),
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: priceSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MixMatchBadge extends StatelessWidget {
  final String text;
  final Animation<double> scaleAnimation;
  final Animation<Color?> colorAnimation;

  const _MixMatchBadge({
    required this.text,
    required this.scaleAnimation,
    required this.colorAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.85 + (scaleAnimation.value * 0.15),
          child: AnimatedBuilder(
            animation: colorAnimation,
            builder: (context, child) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorAnimation.value ?? AppColors.success,
                      (colorAnimation.value ?? AppColors.success)
                          .withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: (colorAnimation.value ?? AppColors.success)
                          .withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_offer_rounded,
                      color: AppColors.white,
                      size: 14.sp,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        text,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SpecialPriceDisplay extends StatelessWidget {
  final double price;
  final Animation<double> scaleAnimation;
  final Animation<Color?> colorAnimation;

  const _SpecialPriceDisplay({
    required this.price,
    required this.scaleAnimation,
    required this.colorAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.92 + (scaleAnimation.value * 0.08),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            decoration: AppDecorations.priceTagDecoration, // Green color - this is the hero price
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.discount_rounded,
                      color: AppColors.white,
                      size: 10.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'SPECIAL PRICE',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.9),
                        fontSize: 6.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '\$',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      price.toStringAsFixed(2),
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
