import 'package:backpackr/features/travelers/repositories/travelers_repository.dart';
import 'package:flutter/foundation.dart';

class TravelersController extends ChangeNotifier {
  TravelersController({TravelersRepository? repository})
    : _repository = repository ?? TravelersRepository();

  final TravelersRepository _repository;

  Set<String> hiddenTravelerIds = {};
  Set<String> reportedTravelerIds = {};
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadPrivacyState(String currentUserId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      hiddenTravelerIds = await _repository.getHiddenTravelersForUser(
        currentUserId,
      );
      reportedTravelerIds = await _repository.getUsersReportedBy(currentUserId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> hideTraveler({
    required String currentUserId,
    required String travelerId,
  }) async {
    await _repository.hideTravelerForUser(
      userId: currentUserId,
      travelerId: travelerId,
    );
    hiddenTravelerIds = {...hiddenTravelerIds, travelerId};
    notifyListeners();
  }
}
