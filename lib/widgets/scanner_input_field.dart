import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:blocks_guide/core/theme/app_theme.dart';

/// Modern scanner input field with glassmorphism effect
class ScannerInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showKeyboard;
  final Function(String) onSubmitted;
  final Function(KeyEvent) onKeyEvent;
  final VoidCallback onTap;

  const ScannerInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.showKeyboard,
    required this.onSubmitted,
    required this.onKeyEvent,
    required this.onTap,
  });

  @override
  State<ScannerInputField> createState() => _ScannerInputFieldState();
}

class _ScannerInputFieldState extends State<ScannerInputField>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    widget.focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isFocused ? _pulseAnimation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: (_isFocused ? AppColors.accentTeal : AppColors.white)
                      .withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: _isFocused ? 1 : 0,
                ),
              ],
            ),
            child: KeyboardListener(
              focusNode: widget.focusNode,
              autofocus: true,
              onKeyEvent: widget.onKeyEvent,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _isFocused
                        ? AppColors.accentTeal
                        : AppColors.white.withValues(alpha: 0.25),
                    width: _isFocused ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Scanner icon
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.accentTeal,
                        size: 16.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // Text field
                    Expanded(
                      child: TextFormField(
                        controller: widget.controller,
                        autofocus: false,
                        readOnly: !widget.showKeyboard,
                        showCursor: true,
                        // keyboardType: TextInputType.number,
                        // inputFormatters: [
                        //   FilteringTextInputFormatter.digitsOnly
                        // ],
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                        onTap: widget.onTap,
                        onFieldSubmitted: widget.onSubmitted,
                        decoration: InputDecoration(
                          hintText: 'Scan or enter barcode...',
                          hintStyle: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.5),
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                          isDense: true,
                        ),
                      ),
                    ),

                    // Keyboard toggle indicator
                    if (widget.showKeyboard)
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Icon(
                          Icons.keyboard_rounded,
                          color: AppColors.success,
                          size: 12.sp,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
