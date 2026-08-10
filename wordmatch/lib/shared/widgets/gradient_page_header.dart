import 'package:flutter/material.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';

/// 页面渐变 Header（统一组件）
///
/// 用于需要返回按钮 + 主副标题的二级页面，也支持作为主页 Tab 的顶部 header
/// （通过 [leading] / [showBackButton] 控制左侧元素）。
/// 所有使用本组件的页面保证 header 高度、字号、间距完全一致，避免各页面
/// 各自实现导致视觉差异（字体大小 / header 高度不一致）。
///
/// 布局规格：
/// - 内边距 `LTRB(24, 20, 24, 24)`，底部圆角 28
/// - 左侧元素 40×40（返回按钮 / 自定义 [leading]）
/// - 标题 fontSize 22 bold，副标题 fontSize 13
class GradientPageHeader extends StatelessWidget {
  const GradientPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.leading,
    this.showBackButton = true,
    this.trailing,
  });

  /// 主标题
  final String title;

  /// 副标题（可选）
  final String? subtitle;

  /// 返回回调；为空时使用 [Navigator.maybePop]。
  /// 仅在显示返回按钮时生效。
  final VoidCallback? onBack;

  /// 自定义左侧元素（如 Logo、头像），传了则替代默认返回按钮。
  final Widget? leading;

  /// 是否显示返回按钮（未传 [leading] 时生效）。
  /// 主页 Tab 等无返回场景可设为 `false`。
  final bool showBackButton;

  /// 右侧操作按钮（可选），如删除 / 设置等
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: colors.headerGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          _buildLeading(context),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    // 自定义 leading 优先
    if (leading != null) return leading!;

    // 无返回按钮且无 leading：左侧留空占位，保持标题对齐
    if (!showBackButton) return const SizedBox(width: 0);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded,
            color: Colors.white, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: '返回',
      ),
    );
  }
}
