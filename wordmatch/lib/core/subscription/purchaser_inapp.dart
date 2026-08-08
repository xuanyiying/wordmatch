import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'purchaser.dart';
import 'subscription_tier.dart';

class InAppPurchaser implements Purchaser {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Completer<PurchaseResult> _completer = Completer();
  bool _initialized = false;
  // 防止并发发起多次购买/恢复时 _completer 被覆盖导致结果错乱
  bool _purchaseInFlight = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    _sub = _iap.purchaseStream.listen(_onPurchaseUpdate, onError: (e) {
      if (!_completer.isCompleted) {
        _completer.complete(PurchaseFailed(e.toString()));
      }
    });
    _initialized = true;
  }

  /// 释放购买流订阅（应用不再需要内购时调用）。
  /// 注意：购买流需在 App 生命周期内保持监听，仅完全退出时释放。
  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    _initialized = false;
  }

  void _onPurchaseUpdate(List<PurchaseDetails> list) {
    for (final d in list) {
      if (d.status == PurchaseStatus.pending) continue;
      if (d.status == PurchaseStatus.purchased ||
          d.status == PurchaseStatus.restored) {
        final t = _tierFromProductId(d.productID);
        if (t != null) {
          if (!_completer.isCompleted) {
            _completer.complete(
              d.status == PurchaseStatus.restored
                  ? PurchaseRestored(t)
                  : PurchaseSuccess(t),
            );
          }
        }
        if (d.pendingCompletePurchase) _iap.completePurchase(d);
      } else if (d.status == PurchaseStatus.error) {
        final msg = d.error?.message ?? 'Purchase error';
        if (msg.toLowerCase().contains('cancel')) {
          if (!_completer.isCompleted) {
            _completer.complete(PurchaseUserCancelled());
          }
        } else {
          if (!_completer.isCompleted) {
            _completer.complete(PurchaseFailed(msg));
          }
        }
      }
    }
  }

  SubscriptionTier? _tierFromProductId(String pid) {
    for (final t in [
      SubscriptionTier.monthly,
      SubscriptionTier.yearly,
      SubscriptionTier.lifetime,
    ]) {
      if (t.productId == pid) return t;
    }
    return null;
  }

  @override
  Future<PurchaseResult> purchase(SubscriptionTier tier) async {
    await init();
    if (_purchaseInFlight) {
      return PurchaseFailed('已有购买在进行中，请稍候');
    }
    _purchaseInFlight = true;
    _completer = Completer<PurchaseResult>();

    try {
      final response = await _iap.queryProductDetails({tier.productId});
      if (response.notFoundIDs.isNotEmpty) {
        return PurchaseFailed(
          'Product not found: ${response.notFoundIDs.join(',')}。请检查 App Store Connect 是否创建了正确的 Product ID。',
        );
      }
      final product = response.productDetails.first;
      final param = PurchaseParam(productDetails: product);
      final ok = await _iap.buyNonConsumable(purchaseParam: param);
      if (!ok) return PurchaseUserCancelled();
      return await _completer.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () => PurchaseFailed('购买超时，请稍后查看订单状态'),
      );
    } catch (e) {
      return PurchaseFailed(e.toString());
    } finally {
      _purchaseInFlight = false;
    }
  }

  @override
  Future<PurchaseResult> restore() async {
    await init();
    if (_purchaseInFlight) {
      return PurchaseFailed('已有恢复操作在进行中，请稍候');
    }
    _purchaseInFlight = true;
    _completer = Completer<PurchaseResult>();
    try {
      await _iap.restorePurchases();
      return await _completer.future.timeout(
        const Duration(minutes: 1),
        onTimeout: () => PurchaseRestored(null),
      );
    } catch (e) {
      return PurchaseFailed(e.toString());
    } finally {
      _purchaseInFlight = false;
    }
  }
}
