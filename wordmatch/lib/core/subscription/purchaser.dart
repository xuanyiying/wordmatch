import 'subscription_tier.dart';

sealed class PurchaseResult {}

class PurchaseSuccess extends PurchaseResult {
  final SubscriptionTier tier;
  PurchaseSuccess(this.tier);
}

class PurchaseUserCancelled extends PurchaseResult {}

class PurchaseFailed extends PurchaseResult {
  final String error;
  PurchaseFailed(this.error);
}

class PurchaseRestored extends PurchaseResult {
  final SubscriptionTier? tier;
  PurchaseRestored(this.tier);
}

abstract class Purchaser {
  Future<void> init();
  Future<PurchaseResult> purchase(SubscriptionTier tier);
  Future<PurchaseResult> restore();

  /// 释放购买流等资源（应用完全退出时调用）。
  void dispose() {}
}

extension ProductIds on SubscriptionTier {
  String get productId => switch (this) {
        SubscriptionTier.monthly => 'com.wordmatch.pro.monthly',
        SubscriptionTier.yearly => 'com.wordmatch.pro.yearly',
        SubscriptionTier.lifetime => 'com.wordmatch.pro.lifetime',
        _ => throw UnsupportedError('Free tier has no product id'),
      };
}
