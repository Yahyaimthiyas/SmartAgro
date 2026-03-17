import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final bool hasBorder;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 12,
    this.opacity = 0.1,
    this.borderRadius,
    this.color,
    this.padding,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);
    
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withOpacity(opacity),
            borderRadius: radius,
            border: hasBorder 
              ? Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.5,
                )
              : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
