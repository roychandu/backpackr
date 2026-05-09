import 'package:backpackr/features/premium/controllers/purchase_controller.dart';

class InAppPurchaseDataSource {
  InAppPurchaseDataSource({InAppPurchaseProvider? provider})
    : _provider = provider ?? InAppPurchaseProvider();

  final InAppPurchaseProvider _provider;

  bool get isPremiumMember => _provider.isPremiumMember;

  Future<bool> restorePurchases() => _provider.restorePurchases();
}
