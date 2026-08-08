import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'subscription_tier.dart';
import 'subscription_service.dart';

final tierProvider = FutureProvider<SubscriptionTier>((ref) async {
  return SubscriptionService.getTier();
});

final aiQuotaProvider = FutureProvider<(int, int)>((ref) async {
  return SubscriptionService.getAiQuota();
});
