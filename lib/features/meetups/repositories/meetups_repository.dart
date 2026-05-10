import 'package:backpackr/features/meetups/data_sources/firebase_meetups_data_source.dart';
import 'package:backpackr/features/meetups/models/meetup.dart';

class MeetupsRepository {
  MeetupsRepository({FirebaseMeetupsDataSource? dataSource})
    : _dataSource = dataSource ?? FirebaseMeetupsDataSource();

  final FirebaseMeetupsDataSource _dataSource;

  String? get currentUserId => _dataSource.currentUserId;

  Future<List<Meetup>> getAllMeetups() => _dataSource.getAllMeetups();

  Stream<List<Meetup>> watchMeetups() => _dataSource.watchMeetups();

  Future<String> createMeetup({
    required String title,
    required String description,
    required MeetupCategory category,
    required DateTime dateTime,
    required String location,
    required int maxCapacity,
  }) {
    return _dataSource.createMeetup(
      title: title,
      description: description,
      category: category,
      dateTime: dateTime,
      location: location,
      maxCapacity: maxCapacity,
    );
  }

  Future<void> requestToJoinMeetup(String meetupId) {
    return _dataSource.requestToJoinMeetup(meetupId);
  }

  Future<void> cancelMeetup(String meetupId) {
    return _dataSource.cancelMeetup(meetupId);
  }

  Future<void> cancelJoinRequest(String meetupId) {
    return _dataSource.cancelJoinRequest(meetupId);
  }

  Future<void> leaveMeetup(String meetupId) {
    return _dataSource.leaveMeetup(meetupId);
  }

  Future<Meetup?> getMeetupById(String meetupId) {
    return _dataSource.getMeetupById(meetupId);
  }

  Stream<List<Map<String, dynamic>>> getMeetupNotificationsStream() {
    return _dataSource.getMeetupNotificationsStream();
  }

  Future<void> clearMeetupNotifications() {
    return _dataSource.clearMeetupNotifications();
  }

  Future<void> deleteNotification(String notificationId) {
    return _dataSource.deleteNotification(notificationId);
  }

  Stream<int> getPendingHostRequestsCount() {
    return _dataSource.getPendingHostRequestsCount();
  }

  Future<List<Map<String, dynamic>>> getAttendeesData(List<String> userIds) {
    return _dataSource.getAttendeesData(userIds);
  }

  Future<void> approveJoinRequest(String meetupId, String userId) {
    return _dataSource.approveJoinRequest(meetupId, userId);
  }

  Future<void> rejectJoinRequest(String meetupId, String userId) {
    return _dataSource.rejectJoinRequest(meetupId, userId);
  }

  Future<void> removeAttendee(String meetupId, String userId) {
    return _dataSource.removeAttendee(meetupId, userId);
  }

  Future<void> updateMeetup({
    required String meetupId,
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    required int maxCapacity,
  }) {
    return _dataSource.updateMeetup(
      meetupId: meetupId,
      title: title,
      description: description,
      dateTime: dateTime,
      location: location,
      maxCapacity: maxCapacity,
    );
  }

  Future<MeetupUserLocation?> getCurrentUserLocation() {
    return _dataSource.getCurrentUserLocation();
  }
}
