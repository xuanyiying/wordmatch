import 'purchaser.dart';
import 'purchaser_mock.dart';
import 'purchaser_inapp.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'subscription_tier.dart';

class SubscriptionService {
  SubscriptionService._();

  // ============================================
  // 🔑 商业化总开关
  // ============================================
  // false：**暂时不对功能做任何限制**（用户看起来永远是终身会员 Pro）
  //        AI 额度无限、皮肤全解锁、真人发音无门槛
  //        不弹任何升级 Pro 弹窗，UI 上的"升级 Pro"按钮自动隐藏
  // true ：正式商业化（功能限制 + 升级弹窗按 tier 生效）
  //        发布收费版前把这个常量改成 true 即可，UI/Service 代码不用改
  static const bool kCommercialEnabled = false;
  // ============================================

  static const _kTierKey = 'sub_tier';
  static const _kUsedAiKey = 'sub_ai_used';
  static const _kResetDateKey = 'sub_reset_date';
  static const int dailyFreeAiQuota = 10;

  static final Purchaser _purchaser =
      kDebugMode ? MockPurchaser() : InAppPurchaser();
  static bool _purchaserInited = false;
  static Future<void> _ensurePurchaser() async {
    if (_purchaserInited) return;
    try {
      await _purchaser.init();
    } catch (_) {}
    _purchaserInited = true;
  }

  static Future<SubscriptionTier> getTier() async {
    // 如果商业化暂未启用：对外表现永远是终身会员 Pro，所有功能直接可用
    if (!kCommercialEnabled) return SubscriptionTier.lifetime;

    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_kTierKey);
      return switch (s) {
        'monthly' => SubscriptionTier.monthly,
        'yearly' => SubscriptionTier.yearly,
        'lifetime' => SubscriptionTier.lifetime,
        _ => SubscriptionTier.free,
      };
    } catch (_) {
      return SubscriptionTier.free;
    }
  }

  static Future<void> setTier(SubscriptionTier tier) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTierKey, tier.name);
  }

  static Future<void> _ensureResetIfNeeded(SharedPreferences p) async {
    final today = _dateKey(DateTime.now());
    final lastReset = p.getString(_kResetDateKey);
    if (lastReset != today) {
      await p.setInt(_kUsedAiKey, 0);
      await p.setString(_kResetDateKey, today);
    }
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<(int used, int total)> getAiQuota() async {
    // 商业化未启用：对外显示"AI 额度无限"
    if (!kCommercialEnabled) return (0, -1);
    final tier = await getTier();
    if (tier.isPro) return (0, -1);
    final p = await SharedPreferences.getInstance();
    await _ensureResetIfNeeded(p);
    return (p.getInt(_kUsedAiKey) ?? 0, dailyFreeAiQuota);
  }

  static Future<bool> consumeAiQuota({bool forceCheck = false}) async {
    // 商业化未启用：AI 功能永远放行，不计数
    if (!kCommercialEnabled) return true;
    if (!forceCheck && kDebugMode) return true;
    final tier = await getTier();
    if (tier.isPro) return true;
    final p = await SharedPreferences.getInstance();
    await _ensureResetIfNeeded(p);
    final used = p.getInt(_kUsedAiKey) ?? 0;
    if (used >= dailyFreeAiQuota) return false;
    await p.setInt(_kUsedAiKey, used + 1);
    return true;
  }

  static Future<PurchaseResult> purchaseTier(SubscriptionTier tier) async {
    await _ensurePurchaser();
    final r = await _purchaser.purchase(tier);
    if (r is PurchaseSuccess) {
      await setTier(r.tier);
    } else if (r is PurchaseRestored && r.tier != null) {
      await setTier(r.tier!);
    }
    return r;
  }

  static Future<PurchaseResult> restorePurchases() async {
    await _ensurePurchaser();
    final r = await _purchaser.restore();
    if (r is PurchaseRestored && r.tier != null) {
      await setTier(r.tier!);
    }
    return r;
  }

  static Future<bool> purchase(SubscriptionTier tier) async {
    final r = await purchaseTier(tier);
    return r is PurchaseSuccess;
  }

  /// 释放购买流订阅（应用完全退出时调用）。
  static void dispose() {
    _purchaser.dispose();
    _purchaserInited = false;
  }
}
