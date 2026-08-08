import 'package:flutter/material.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart' show AppColorSchemeX;
import 'package:wordmatch/shared/utils/audio_player.dart';
import 'package:wordmatch/shared/utils/haptic_util.dart';

/// 可复用的朗读按钮。
///
/// 统一封装了「点击播放文本 + 触感反馈 + 失败提示」，避免各页面重复实现
/// 样式与播放逻辑。默认渲染为圆形喇叭图标按钮，也可通过 [label] 渲染成
/// 带文字的胶囊按钮（如口语对话的「播放」）。
///
/// 用法：
/// ```dart
/// // 圆形喇叭，播放单词/例句
/// SpeakButton(text: word.word, color: colors.mintDeep);
///
/// // 带文字按钮，点击播放并自定义失败回调
/// SpeakButton(
///   text: line.en,
///   label: '播放',
///   color: colors.mintDeep,
///   onError: (msg) => ...,
/// );
/// ```
class SpeakButton extends StatelessWidget {
  const SpeakButton({
    super.key,
    required this.text,
    this.color,
    this.size = 32,
    this.iconSize = 18,
    this.icon = Icons.volume_up_rounded,
    this.bgOpacity = 0.08,
    this.label,
    this.labelStyle,
    this.onTap,
    this.onError,
    this.tooltip,
  });

  /// 要朗读的文本。
  final String text;

  /// 图标/强调色；默认取当前主题的 `mintDeep`。
  final Color? color;

  /// 圆形按钮直径。
  final double size;

  /// 喇叭图标尺寸。
  final double iconSize;

  /// 喇叭图标。
  final IconData icon;

  /// 圆形背景的不透明度（基于 [color]）。
  final double bgOpacity;

  /// 非空时渲染为「图标 + 文字」的胶囊按钮。
  final String? label;

  /// 胶囊按钮的文字样式。
  final TextStyle? labelStyle;

  /// 自定义点击处理；默认朗读 [text]。
  final Future<void> Function()? onTap;

  /// 播放失败回调；默认用 SnackBar 提示。
  final void Function(String message)? onError;

  /// 无障碍/长按提示。
  final String? tooltip;

  Future<void> _handleTap(BuildContext context) async {
    HapticUtil.buttonTap();
    final custom = onTap;
    if (custom != null) {
      await custom();
      return;
    }
    final result = await AudioPlayerUtil.speakSentence(text);
    if (!result.success && context.mounted) {
      final msg = result.error ?? '播放失败';
      if (onError != null) {
        onError!(msg);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(msg),
              duration: const Duration(seconds: 2),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.appColors.mintDeep;

    // 带文字胶囊形态
    Widget pill;
    if (label != null) {
      pill = InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: bgOpacity),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: effectiveColor),
              const SizedBox(width: 4),
              Text(
                label!,
                style: labelStyle ??
                    TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: effectiveColor,
                    ),
              ),
            ],
          ),
        ),
      );
      return _wrapTooltip(pill);
    }

    // 默认圆形图标按钮
    final circle = InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: bgOpacity),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: iconSize, color: effectiveColor),
      ),
    );
    return _wrapTooltip(circle);
  }

  Widget _wrapTooltip(Widget child) {
    final t = tooltip;
    if (t == null || t.isEmpty) return child;
    return Tooltip(message: t, child: child);
  }
}
