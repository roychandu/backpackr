import 'package:backpackr/features/auth/repositories/auth_repository.dart';
import 'package:backpackr/features/meetups/data_sources/firebase_meetups_data_source.dart';
import 'package:backpackr/features/meetups/models/meetup.dart';
import 'package:backpackr/features/meetups/repositories/meetups_repository.dart';
import 'package:backpackr/features/travelers/repositories/travelers_repository.dart';
import 'package:backpackr/shared/services/user_setup_service.dart';
import 'package:flutter/material.dart';

class MeetupsController extends ChangeNotifier {
  MeetupsController({
    MeetupsRepository? repository,
    TravelersRepository? travelersRepository,
    AuthRepository? authRepository,
  }) : _repository = repository ?? MeetupsRepository(),
       _travelersRepository = travelersRepository ?? TravelersRepository(),
       _authRepository = authRepository ?? AuthRepository();

  final MeetupsRepository _repository;
  final TravelersRepository _travelersRepository;
  final AuthRepository _authRepository;

  List<Meetup> meetups = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadMeetups() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      meetups = await _repository.getAllMeetups();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestToJoin(String meetupId) async {
    await _repository.requestToJoinMeetup(meetupId);
    await loadMeetups();
  }

  String? get currentUserId => _repository.currentUserId;

  Future<List<Meetup>> getAllMeetups() => _repository.getAllMeetups();

  Stream<List<Meetup>> watchMeetups() => _repository.watchMeetups();

  Future<String> createMeetup({
    required String title,
    required String description,
    required MeetupCategory category,
    required DateTime dateTime,
    required String location,
    required int maxCapacity,
  }) {
    return _repository.createMeetup(
      title: title,
      description: description,
      category: category,
      dateTime: dateTime,
      location: location,
      maxCapacity: maxCapacity,
    );
  }

  Future<void> requestToJoinMeetup(String meetupId) {
    return _repository.requestToJoinMeetup(meetupId);
  }

  Future<void> cancelJoinRequest(String meetupId) {
    return _repository.cancelJoinRequest(meetupId);
  }

  Future<void> leaveMeetup(String meetupId) {
    return _repository.leaveMeetup(meetupId);
  }

  Future<void> cancelMeetup(String meetupId) {
    return _repository.cancelMeetup(meetupId);
  }

  Future<Meetup?> getMeetupById(String meetupId) {
    return _repository.getMeetupById(meetupId);
  }

  Stream<List<Map<String, dynamic>>> getMeetupNotificationsStream() {
    return _repository.getMeetupNotificationsStream();
  }

  Future<void> clearMeetupNotifications() {
    return _repository.clearMeetupNotifications();
  }

  Future<void> deleteNotification(String notificationId) {
    return _repository.deleteNotification(notificationId);
  }

  Stream<int> getPendingHostRequestsCount() {
    return _repository.getPendingHostRequestsCount();
  }

  Future<List<Map<String, dynamic>>> getAttendeesData(List<String> userIds) {
    return _repository.getAttendeesData(userIds);
  }

  Future<void> approveJoinRequest(String meetupId, String userId) {
    return _repository.approveJoinRequest(meetupId, userId);
  }

  Future<void> rejectJoinRequest(String meetupId, String userId) {
    return _repository.rejectJoinRequest(meetupId, userId);
  }

  Future<void> removeAttendee(String meetupId, String userId) {
    return _repository.removeAttendee(meetupId, userId);
  }

  Future<void> updateMeetup({
    required String meetupId,
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    required int maxCapacity,
  }) {
    return _repository.updateMeetup(
      meetupId: meetupId,
      title: title,
      description: description,
      dateTime: dateTime,
      location: location,
      maxCapacity: maxCapacity,
    );
  }

  Future<MeetupUserLocation?> getCurrentUserLocation() {
    return _repository.getCurrentUserLocation();
  }

  Future<Set<String>> getReportedUsers(String userId) {
    return _travelersRepository.getUsersReportedBy(userId);
  }

  Future<Set<String>> getHiddenUsers(String userId) {
    return _travelersRepository.getHiddenTravelersForUser(userId);
  }

  Future<void> reportUser({
    required String reporterUserId,
    required String reportedUserId,
    required String reason,
  }) {
    return _travelersRepository.reportUser(
      reporterUserId: reporterUserId,
      reportedUserId: reportedUserId,
      reason: reason,
    );
  }

  Future<void> hideTravelerForUser({
    required String userId,
    required String travelerId,
  }) {
    return _travelersRepository.hideTravelerForUser(
      userId: userId,
      travelerId: travelerId,
    );
  }

  Future<bool> hasAcceptedEula() {
    return _authRepository.hasAcceptedEula();
  }

  Future<void> acceptEula() {
    return _authRepository.acceptEula();
  }

  Future<bool> isProfileStrictlyComplete() {
    return UserSetupService.isProfileStrictlyComplete();
  }

  Future<void> showSetupPopup(BuildContext context) {
    return UserSetupService.showSetupPopup(context);
  }
}
