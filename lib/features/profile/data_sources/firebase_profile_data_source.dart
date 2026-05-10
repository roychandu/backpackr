import 'package:backpackr/features/profile/data_sources/user_profile_service.dart';
import 'package:backpackr/features/travelers/models/user_profile.dart';

class FirebaseProfileDataSource {
  FirebaseProfileDataSource({UserProfileService? userProfileService})
    : _userProfileService = userProfileService ?? UserProfileService();

  final UserProfileService _userProfileService;

  Future<UserProfile?> getCurrentUserProfile() {
    return _userProfileService.getCurrentUserProfile();
  }

  Future<void> setCurrentUserProfile(UserProfile profile) {
    return _userProfileService.setCurrentUserProfile(profile);
  }

  Future<void> updateCurrentUserProfile(Map<String, dynamic> partial) {
    return _userProfileService.updateCurrentUserProfile(partial);
  }

  Stream<UserProfile?> watchCurrentUserProfile() {
    return _userProfileService.watchCurrentUserProfile();
  }
}
