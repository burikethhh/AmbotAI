import 'package:flutter/material.dart';

class AppIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final Color? borderColor;
  final double borderWidth;

  const AppIcon({
    super.key,
    required this.icon,
    this.size = 48,
    required this.backgroundColor,
    required this.iconColor,
    this.borderColor,
    this.borderWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: Center(
        child: Icon(icon, color: iconColor, size: size * 0.48),
      ),
    );
  }
}
