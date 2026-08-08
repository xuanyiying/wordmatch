import 'package:flutter/foundation.dart';
import 'purchaser.dart';
import 'subscription_tier.dart';

class MockPurchaser implements Purchaser {
  @override
  Future<void> init() async {}

  @override
  Future<PurchaseResult> purchase(SubscriptionTier tier) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (kDebugMode) return PurchaseSuccess(tier);
    if (DateTime.now().millisecondsSinceEpoch % 20 == 0) {
      return PurchaseFailed('Mock network error');
    }
    return PurchaseSuccess(tier);
  }

  @override
  Future<PurchaseResult> restore() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return PurchaseRestored(null);
  }

  @override
  void dispose() {}
}
