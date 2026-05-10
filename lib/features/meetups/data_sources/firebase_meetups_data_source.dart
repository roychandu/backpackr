import 'package:backpackr/features/meetups/models/meetup.dart';
import 'package:backpackr/features/meetups/data_sources/meetup_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class MeetupUserLocation {
  const MeetupUserLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class FirebaseMeetupsDataSource {
  FirebaseMeetupsDataSource({MeetupService? meetupService})
    : _meetupService = meetupService ?? MeetupService();

  final MeetupService _meetupService;

  String? get currentUserId => _meetupService.currentUserId;

  Future<List<Meetup>> getAllMeetups() => _meetupService.getAllMeetups();

  Stream<List<Meetup>> watchMeetups() => _meetupService.getMeetupsStream();

  Future<String> createMeetup({
    required String title,
    required String description,
    required MeetupCategory category,
    required DateTime dateTime,
    required String location,
    required int maxCapacity,
  }) {
    return _meetupService.createMeetup(
      title: title,
      description: description,
      category: category,
      dateTime: dateTime,
      location: location,
      maxCapacity: maxCapacity,
    );
  }

  Future<void> requestToJoinMeetup(String meetupId) {
    return _meetupService.requestToJoinMeetup(meetupId);
  }

  Future<void> cancelMeetup(String meetupId) {
    return _meetupService.cancelMeetup(meetupId);
  }

  Future<void> cancelJoinRequest(String meetupId) {
    return _meetupService.cancelJoinRequest(meetupId);
  }

  Future<void> leaveMeetup(String meetupId) {
    return _meetupService.leaveMeetup(meetupId);
  }

  Future<Meetup?> getMeetupById(String meetupId) {
    return _meetupService.getMeetupById(meetupId);
  }

  Stream<List<Map<String, dynamic>>> getMeetupNotificationsStream() {
    return _meetupService.getMeetupNotificationsStream();
  }

  Future<void> clearMeetupNotifications() {
    return _meetupService.clearMeetupNotifications();
  }

  Future<void> deleteNotification(String notificationId) {
    return _meetupService.deleteNotification(notificationId);
  }

  Stream<int> getPendingHostRequestsCount() {
    return _meetupService.getPendingHostRequestsCount();
  }

  Future<List<Map<String, dynamic>>> getAttendeesData(List<String> userIds) {
    return _meetupService.getAttendeesData(userIds);
  }

  Future<void> approveJoinRequest(String meetupId, String userId) {
    return _meetupService.approveJoinRequest(meetupId, userId);
  }

  Future<void> rejectJoinRequest(String meetupId, String userId) {
    return _meetupService.rejectJoinRequest(meetupId, userId);
  }

  Future<void> removeAttendee(String meetupId, String userId) {
    return _meetupService.removeAttendee(meetupId, userId);
  }

  Future<void> updateMeetup({
    required String meetupId,
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    required int maxCapacity,
  }) {
    return _meetupService.updateMeetup(
      meetupId: meetupId,
      title: title,
      description: description,
      dateTime: dateTime,
      location: location,
      maxCapacity: maxCapacity,
    );
  }

  Future<MeetupUserLocation?> getCurrentUserLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final profileSnap = await FirebaseDatabase.instance
          .ref('userProfiles')
          .child(user.uid)
          .get();

      if (profileSnap.exists && profileSnap.value is Map) {
        final profileData = profileSnap.value as Map<dynamic, dynamic>;
        final lat = profileData['latitude'];
        final lng = profileData['longitude'];

        if (lat != null && lng != null) {
          final latitude = double.tryParse(lat.toString());
          final longitude = double.tryParse(lng.toString());
          if (latitude != null && longitude != null) {
            return MeetupUserLocation(latitude: latitude, longitude: longitude);
          }
        }
      }
    } catch (_) {
      // Fall back to GPS.
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    return MeetupUserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
