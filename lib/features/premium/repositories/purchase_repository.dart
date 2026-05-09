import 'package:backpackr/features/premium/data_sources/in_app_purchase_data_source.dart';

class PurchaseRepository {
  PurchaseRepository({InAppPurchaseDataSource? dataSource})
    : _dataSource = dataSource ?? InAppPurchaseDataSource();

  final InAppPurchaseDataSource _dataSource;

  bool get isPremiumMember => _dataSource.isPremiumMember;

  Future<bool> restorePurchases() => _dataSource.restorePurchases();
}
