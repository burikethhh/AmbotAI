import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final bool elevated;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.boxShadow,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? AppSpacing.cardInsets,
      decoration: BoxDecoration(
        color: backgroundColor ?? (elevated ? c.cardElevated : c.cardColor),
        borderRadius: BorderRadius.circular(borderRadius ?? 4),
        border: Border.all(
          color: borderColor ?? c.borderColor,
          width: 2,
        ),
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}
