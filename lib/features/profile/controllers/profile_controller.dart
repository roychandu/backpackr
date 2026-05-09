import 'package:backpackr/features/profile/repositories/profile_repository.dart';
import 'package:backpackr/features/travelers/models/user_profile.dart';
import 'package:flutter/foundation.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({ProfileRepository? repository})
    : _repository = repository ?? ProfileRepository();

  final ProfileRepository _repository;

  UserProfile? profile;
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadProfile() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      profile = await _repository.getCurrentUserProfile();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile(UserProfile nextProfile) async {
    await _repository.setCurrentUserProfile(nextProfile);
    profile = nextProfile;
    notifyListeners();
  }
}
