import 'dart:async';
import 'package:flutter/material.dart';
import 'package:blocks_guide/core/theme/app_theme.dart';

/// An animated gradient background that smoothly transitions between colors
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final Duration transitionDuration;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.transitionDuration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground> {
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.transitionDuration, (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % AppColors.gradientSets.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.gradientSets[_currentIndex];

    return AnimatedContainer(
      duration: widget.transitionDuration,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: widget.child,
    );
  }

  // Expose current colors for external use (e.g., AppBar)
  List<Color> get currentColors => AppColors.gradientSets[_currentIndex];
}

/// A provider widget to share gradient state across the app
class GradientProvider extends InheritedWidget {
  final Color topColor;
  final Color bottomColor;

  const GradientProvider({
    super.key,
    required this.topColor,
    required this.bottomColor,
    required super.child,
  });

  static GradientProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GradientProvider>();
  }

  @override
  bool updateShouldNotify(GradientProvider oldWidget) {
    return topColor != oldWidget.topColor || bottomColor != oldWidget.bottomColor;
  }
}
