import 'package:backpackr/features/chat/data_sources/meetup_suggestions_data_source.dart';
import 'package:backpackr/features/chat/models/nearby_meetups_result.dart';

class MeetupSuggestionsRepository {
  MeetupSuggestionsRepository({MeetupSuggestionsDataSource? dataSource})
    : _dataSource = dataSource ?? MeetupSuggestionsDataSource();

  final MeetupSuggestionsDataSource _dataSource;

  Future<NearbyMeetupsResult> getNearbyMeetups() {
    return _dataSource.getNearbyMeetups();
  }
}
