import 'package:backpackr/features/travelers/repositories/traveler_service.dart';

class FirebaseTravelersDataSource {
  FirebaseTravelersDataSource({TravelerService? travelerService})
    : _travelerService = travelerService ?? TravelerService();

  final TravelerService _travelerService;

  Future<void> hideTravelerForUser({
    required String userId,
    required String travelerId,
  }) {
    return _travelerService.hideTravelerForUser(
      userId: userId,
      travelerUserId: travelerId,
    );
  }

  Future<Set<String>> getHiddenTravelersForUser(String userId) {
    return _travelerService.getHiddenTravelersForUser(userId);
  }

  Future<void> reportUser({
    required String reporterUserId,
    required String reportedUserId,
    required String reason,
  }) {
    return _travelerService.reportUser(
      reporterUserId: reporterUserId,
      reportedUserId: reportedUserId,
      reason: reason,
    );
  }

  Future<Set<String>> getUsersReportedBy(String reporterUserId) {
    return _travelerService.getUsersReportedBy(reporterUserId);
  }
}
