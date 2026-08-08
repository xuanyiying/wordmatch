import 'dart:async';
import 'package:flutter/services.dart';

/// 震动反馈工具
class HapticUtil {
  HapticUtil._();

  /// 匹配成功：中等震动
  static void matchSuccess() {
    HapticFeedback.mediumImpact();
  }

  /// 匹配失败：轻震动
  static void matchFail() {
    HapticFeedback.lightImpact();
  }

  /// Combo 连击：重震动
  static void comboHit() {
    HapticFeedback.heavyImpact();
  }

  /// 关卡完成：连续震动
  static void levelComplete() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.heavyImpact();
    });
  }

  /// 按钮点击：轻反馈
  static void buttonTap() {
    HapticFeedback.selectionClick();
  }
}
