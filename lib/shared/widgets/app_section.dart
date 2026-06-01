import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class AppSection extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? cardPadding;
  final double? borderRadius;

  const AppSection({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding,
    this.cardPadding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? AppSpacing.only(b: AppSpacing.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.pageHorizontal,
                bottom: AppSpacing.sm + AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.secondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
            child: child,
          ),
        ],
      ),
    );
  }
}
