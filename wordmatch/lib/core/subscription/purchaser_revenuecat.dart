import 'purchaser.dart';
import 'subscription_tier.dart';

class RevenueCatPurchaser implements Purchaser {
  final String apiKey;
  RevenueCatPurchaser(this.apiKey);

  @override
  Future<void> init() async {}

  @override
  Future<PurchaseResult> purchase(SubscriptionTier tier) async {
    return PurchaseSuccess(tier);
  }

  @override
  Future<PurchaseResult> restore() async {
    return PurchaseRestored(null);
  }

  @override
  void dispose() {}
}
