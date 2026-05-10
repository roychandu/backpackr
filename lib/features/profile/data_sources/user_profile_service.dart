import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:backpackr/features/travelers/models/user_profile.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  DatabaseReference _profileRefForUid(String uid) =>
      FirebaseDatabase.instance.ref('userProfiles/$uid');

  Future<UserProfile?> getProfileForUid(String uid) async {
    final snap = await _profileRefForUid(uid).get();
    if (!snap.exists || snap.value == null) return null;
    if (snap.value is Map) {
      return UserProfile.fromMap(snap.value as Map);
    }
    return null;
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getProfileForUid(user.uid);
  }

  Future<void> setProfileForUid(String uid, UserProfile profile) async {
    await _profileRefForUid(uid).set(profile.toMap());
  }

  Future<void> setCurrentUserProfile(UserProfile profile) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    // Get existing profile to preserve travelingBlogs
    final existingProfile = await getCurrentUserProfile();

    if (existingProfile != null) {
      // Instead of using set(), we'll update specific fields to preserve travelingBlogs
      await _profileRefForUid(user.uid).update({
        'displayName': profile.displayName,
        'bio': profile.bio,
        'currentLocation': profile.currentLocation,
        'latitude': profile.latitude,
        'longitude': profile.longitude,
        'avatarUrl': profile.avatarUrl,
        'tags': profile.tags,
        'destinations': profile.destinations.map((d) => d.toMap()).toList(),
        'setupCompleted': profile.setupCompleted,
        'lastUpdated': profile.lastUpdated,
      });
    } else {
      // If no existing profile, use the original set method
      await setProfileForUid(user.uid, profile);
    }
  }

  Future<void> updateProfileForUid(
    String uid,
    Map<String, dynamic> partial,
  ) async {
    await _profileRefForUid(uid).update(partial);
  }

  Future<void> updateCurrentUserProfile(Map<String, dynamic> partial) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    await updateProfileForUid(user.uid, partial);
  }

  Stream<UserProfile?> watchProfileForUid(String uid) {
    return _profileRefForUid(uid).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return null;
      final value = event.snapshot.value;
      if (value is Map) {
        return UserProfile.fromMap(value);
      }
      return null;
    });
  }

  Stream<UserProfile?> watchCurrentUserProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      // Emit null once if not logged in
      return Stream<UserProfile?>.value(null);
    }
    return watchProfileForUid(user.uid);
  }
}
