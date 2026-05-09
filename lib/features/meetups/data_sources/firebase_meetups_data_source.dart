import 'package:backpackr/features/meetups/models/meetup.dart';
import 'package:backpackr/features/meetups/repositories/meetup_service.dart';

class FirebaseMeetupsDataSource {
  FirebaseMeetupsDataSource({MeetupService? meetupService})
    : _meetupService = meetupService ?? MeetupService();

  final MeetupService _meetupService;

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
}
