import 'package:firebase_database/firebase_database.dart';

class TravelerService {
  TravelerService();

  DatabaseReference get _db => FirebaseDatabase.instance.ref();

  Future<void> hideTravelerForUser({
    required String userId,
    required String travelerUserId,
  }) async {
    await _db
        .child('hiddenTravelers')
        .child(userId)
        .child(travelerUserId)
        .set(true);
  }

  Future<Set<String>> getHiddenTravelersForUser(String userId) async {
    final snap = await _db.child('hiddenTravelers').child(userId).get();
    if (!snap.exists) return <String>{};
    final result = <String>{};
    for (final child in snap.children) {
      result.add(child.key ?? '');
    }
    result.removeWhere((e) => e.isEmpty);
    return result;
  }

  Future<void> reportUser({
    required String reportedUserId,
    required String reporterUserId,
    required String reason,
  }) async {
    final reportRef = _db
        .child('userReports')
        .child(reporterUserId)
        .child(reportedUserId);
    await reportRef.set({'reason': reason, 'timestamp': ServerValue.timestamp});
  }

  Future<Set<String>> getUsersReportedBy(String reporterUserId) async {
    final snap = await _db.child('userReports').child(reporterUserId).get();
    if (!snap.exists) return <String>{};
    final result = <String>{};
    for (final child in snap.children) {
      result.add(child.key ?? '');
    }
    result.removeWhere((e) => e.isEmpty);
    return result;
  }
}
