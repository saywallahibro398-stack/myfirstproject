import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class PastelCard extends StatelessWidget {
  const PastelCard({
    required this.child,
    this.color = AppPalette.white,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    super.key,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppPalette.line.withValues(alpha: .65)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
