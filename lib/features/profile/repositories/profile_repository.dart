import 'package:backpackr/features/profile/data_sources/firebase_profile_data_source.dart';
import 'package:backpackr/features/travelers/models/user_profile.dart';

class ProfileRepository {
  ProfileRepository({FirebaseProfileDataSource? dataSource})
    : _dataSource = dataSource ?? FirebaseProfileDataSource();

  final FirebaseProfileDataSource _dataSource;

  Future<UserProfile?> getCurrentUserProfile() {
    return _dataSource.getCurrentUserProfile();
  }

  Future<void> setCurrentUserProfile(UserProfile profile) {
    return _dataSource.setCurrentUserProfile(profile);
  }

  Future<void> updateCurrentUserProfile(Map<String, dynamic> partial) {
    return _dataSource.updateCurrentUserProfile(partial);
  }

  Stream<UserProfile?> watchCurrentUserProfile() {
    return _dataSource.watchCurrentUserProfile();
  }
}
