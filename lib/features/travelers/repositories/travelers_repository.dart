import 'package:backpackr/features/travelers/data_sources/firebase_travelers_data_source.dart';

class TravelersRepository {
  TravelersRepository({FirebaseTravelersDataSource? dataSource})
    : _dataSource = dataSource ?? FirebaseTravelersDataSource();

  final FirebaseTravelersDataSource _dataSource;

  Future<void> hideTravelerForUser({
    required String userId,
    required String travelerId,
  }) {
    return _dataSource.hideTravelerForUser(
      userId: userId,
      travelerId: travelerId,
    );
  }

  Future<Set<String>> getHiddenTravelersForUser(String userId) {
    return _dataSource.getHiddenTravelersForUser(userId);
  }

  Future<void> reportUser({
    required String reporterUserId,
    required String reportedUserId,
    required String reason,
  }) {
    return _dataSource.reportUser(
      reporterUserId: reporterUserId,
      reportedUserId: reportedUserId,
      reason: reason,
    );
  }

  Future<Set<String>> getUsersReportedBy(String reporterUserId) {
    return _dataSource.getUsersReportedBy(reporterUserId);
  }
}
