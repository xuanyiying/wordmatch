import 'package:flutter/material.dart';
import 'package:wordmatch/core/constants/app_colors.dart';
import 'package:wordmatch/core/theme/app_color_scheme.dart';
import 'purchaser.dart';
import 'subscription_service.dart';
import 'subscription_tier.dart';

Future<bool?> showUpgradeProDialog(
  BuildContext context, {
  String? reason,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _UpgradeBottomSheet(),
  );
}

class _UpgradeBottomSheet extends StatefulWidget {
  const _UpgradeBottomSheet();

  @override
  State<_UpgradeBottomSheet> createState() => _UpgradeBottomSheetState();
}

class _UpgradeBottomSheetState extends State<_UpgradeBottomSheet> {
  SubscriptionTier _selected = SubscriptionTier.lifetime;
  bool _purchasing = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
          child: Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '解锁 WordMatch Pro',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          '9 家大模型无限 AI 助记 · 真人发音库 · 全部主题',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        _tierCard(
          tier: SubscriptionTier.monthly,
          price: '¥12',
          unit: '/月',
          desc: '想体验一个月',
          selected: _selected == SubscriptionTier.monthly,
          onTap: () => setState(() => _selected = SubscriptionTier.monthly),
        ),
        const SizedBox(height: 10),
        _tierCard(
          tier: SubscriptionTier.yearly,
          price: '¥88',
          unit: '/年',
          badge: '73% 用户选择',
          desc: '折 ¥7.3/月，性价比之王',
          selected: _selected == SubscriptionTier.yearly,
          onTap: () => setState(() => _selected = SubscriptionTier.yearly),
        ),
        const SizedBox(height: 10),
        _tierCard(
          tier: SubscriptionTier.lifetime,
          price: '¥108',
          unit: ' 终身',
          badge: '🔥 推荐',
          desc: '一次付费，终身更新，对标无痛单词 ¥68+权益',
          selected: _selected == SubscriptionTier.lifetime,
          onTap: () => setState(() => _selected = SubscriptionTier.lifetime),
          highlight: true,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.mintDeep, Color(0xFF3A6C28)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colors.mintDeep.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _purchasing
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      setState(() => _purchasing = true);
                      final ok = await SubscriptionService.purchase(_selected);
                      if (!mounted) return;
                      setState(() => _purchasing = false);
                      if (ok) navigator.pop(true);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _purchasing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      '立即开通 ${_selected.displayName}（${_priceOf(_selected)}）',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _purchasing
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _purchasing = true);
                      final r = await SubscriptionService.restorePurchases();
                      if (!mounted) return;
                      setState(() => _purchasing = false);
                      if (r is PurchaseRestored && r.tier != null) {
                        navigator.pop(true);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('✅ 已恢复 ${r.tier!.displayName}'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('没有找到历史购买记录')),
                        );
                      }
                    },
              child: Text(
                '恢复购买',
                style: TextStyle(
                  color: colors.mintDeep,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                '先用免费版',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
          ],
        ),
      ]),
    );
  }

  String _priceOf(SubscriptionTier t) => switch (t) {
        SubscriptionTier.monthly => '¥12',
        SubscriptionTier.yearly => '¥88',
        SubscriptionTier.lifetime => '¥108',
        _ => '',
      };

  Widget _tierCard({
    required SubscriptionTier tier,
    required String price,
    required String unit,
    required String desc,
    required bool selected,
    required VoidCallback onTap,
    bool highlight = false,
    String? badge,
  }) {
    final borderColor = highlight
        ? context.appColors.mintDeep
        : (selected ? context.appColors.mintDeep : Colors.grey[300]!);
    final bgColor = highlight
        ? context.appColors.mintDeep.withValues(alpha: 0.05)
        : (selected
            ? context.appColors.mintDeep.withValues(alpha: 0.03)
            : context.appColors.card);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: selected || highlight ? 2 : 1.2,
          ),
        ),
        child: Stack(
          children: [
            RadioGroup<SubscriptionTier>(
              groupValue: _selected,
              onChanged: (_) => onTap(),
              child: Row(children: [
                Radio<SubscriptionTier>(
                  value: tier,
                  activeColor: context.appColors.mintDeep,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: highlight
                                ? context.appColors.mintDeep
                                : context.appColors.ink,
                          ),
                        ),
                        Text(
                          unit,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            if (badge != null)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: highlight
                        ? const LinearGradient(
                            colors: [Color(0xFFDB2777), Color(0xFFF97316)],
                          )
                        : context.appColors.headerGradient,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
