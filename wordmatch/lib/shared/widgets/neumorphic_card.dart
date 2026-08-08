import 'package:flutter/material.dart';
import 'package:wordmatch/core/constants/app_sizes.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';

/// 新拟态风格卡片组件
///
/// 带有轻微阴影和圆角，点击时有明显的物理下压反馈
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double borderRadius;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderRadius = AppSizes.cardRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? colors.card,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: colors.border.withValues(alpha: 0.5),
              offset: const Offset(3, 3),
              blurRadius: 6,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.9),
              offset: const Offset(-3, -3),
              blurRadius: 6,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// 内凹式新拟态组件（用于按钮凹槽等）
class NeumorphicInset extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const NeumorphicInset({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppSizes.cardRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            offset: const Offset(3, 3),
            blurRadius: 6,
          ),
          BoxShadow(
            color: colors.border.withValues(alpha: 0.5),
            offset: const Offset(-3, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: child,
    );
  }
}
