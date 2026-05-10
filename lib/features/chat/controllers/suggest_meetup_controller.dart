import 'package:backpackr/features/chat/repositories/meetup_suggestions_repository.dart';
import 'package:backpackr/features/meetups/models/meetup.dart';
import 'package:flutter/foundation.dart';

class SuggestMeetupController extends ChangeNotifier {
  SuggestMeetupController({MeetupSuggestionsRepository? repository})
    : _repository = repository ?? MeetupSuggestionsRepository();

  final MeetupSuggestionsRepository _repository;

  List<Meetup> nearbyMeetups = [];
  Map<String, double> organizerDistances = {};
  bool isLoading = true;
  String? errorMessage;

  Future<void> loadNearbyMeetups() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getNearbyMeetups();
      nearbyMeetups = result.meetups;
      organizerDistances = result.organizerDistances;
    } catch (e) {
      errorMessage = 'Failed to load meetups: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
