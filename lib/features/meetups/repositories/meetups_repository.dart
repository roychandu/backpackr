import 'package:backpackr/features/meetups/data_sources/firebase_meetups_data_source.dart';
import 'package:backpackr/features/meetups/models/meetup.dart';

class MeetupsRepository {
  MeetupsRepository({FirebaseMeetupsDataSource? dataSource})
    : _dataSource = dataSource ?? FirebaseMeetupsDataSource();

  final FirebaseMeetupsDataSource _dataSource;

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
}
