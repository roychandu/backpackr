import 'package:backpackr/features/meetups/models/meetup.dart';
import 'package:backpackr/features/meetups/repositories/meetups_repository.dart';
import 'package:flutter/foundation.dart';

class MeetupsController extends ChangeNotifier {
  MeetupsController({MeetupsRepository? repository})
    : _repository = repository ?? MeetupsRepository();

  final MeetupsRepository _repository;

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
}
