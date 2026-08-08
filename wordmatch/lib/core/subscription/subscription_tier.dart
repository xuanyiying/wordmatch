enum SubscriptionTier { free, monthly, yearly, lifetime }

extension SubscriptionTierX on SubscriptionTier {
  bool get isPro => this != SubscriptionTier.free;

  String get displayName => switch (this) {
        SubscriptionTier.free => '免费版',
        SubscriptionTier.monthly => '月卡会员',
        SubscriptionTier.yearly => '年卡会员',
        SubscriptionTier.lifetime => '🔥 终身会员',
      };
}
