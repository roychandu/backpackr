import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // App settings keys
  static const String _themeKey = 'app_theme';
  static const String _languageKey = 'app_language';
  static const String _firstLaunchKey = 'first_launch';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _profileSetupCompletedKey = 'userSetupCompleted';

  // Backpackr flow keys
  static const String _introSeenKey = 'has_seen_intro';
  static const String _lastSetupPopupShownKey = 'lastSetupPopupShown';
  static const String _isPremiumMemberKey = 'isPremiumMember';
  static const String _isPurchasedKey = 'is_purchased';

  // Traveler profile cache keys
  static const String _profileDisplayNameKey = 'profile_display_name';
  static const String _profileBioKey = 'profile_bio';
  static const String _profileCurrentLocationKey = 'profile_current_location';
  static const String _profileAvatarUrlKey = 'profile_avatar_url';
  static const String _travelerTagsKey = 'traveler_tags';

  // Get SharedPreferences instance
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // App Settings
  Future<void> setTheme(String theme) async {
    final prefs = await _prefs;
    await prefs.setString(_themeKey, theme);
  }

  Future<String?> getTheme() async {
    final prefs = await _prefs;
    return prefs.getString(_themeKey);
  }

  Future<void> setLanguage(String language) async {
    final prefs = await _prefs;
    await prefs.setString(_languageKey, language);
  }

  Future<String?> getLanguage() async {
    final prefs = await _prefs;
    return prefs.getString(_languageKey);
  }

  Future<void> setFirstLaunch(bool isFirstLaunch) async {
    final prefs = await _prefs;
    await prefs.setBool(_firstLaunchKey, isFirstLaunch);
  }

  Future<bool> isFirstLaunch() async {
    final prefs = await _prefs;
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await _prefs;
    await prefs.setBool(_onboardingCompletedKey, completed);
  }

  Future<bool> isOnboardingCompleted() async {
    final prefs = await _prefs;
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> setProfileSetupCompleted(bool completed) async {
    final prefs = await _prefs;
    await prefs.setBool(_profileSetupCompletedKey, completed);
  }

  Future<bool> isProfileSetupCompleted() async {
    final prefs = await _prefs;
    return prefs.getBool(_profileSetupCompletedKey) ?? false;
  }

  Future<void> clearProfileSetupCompleted() async {
    final prefs = await _prefs;
    await prefs.remove(_profileSetupCompletedKey);
  }

  // Backpackr flow
  Future<void> setIntroSeen(bool seen) async {
    final prefs = await _prefs;
    await prefs.setBool(_introSeenKey, seen);
  }

  Future<bool> hasSeenIntro() async {
    final prefs = await _prefs;
    return prefs.getBool(_introSeenKey) ?? false;
  }

  Future<void> setLastSetupPopupShown(int timestamp) async {
    final prefs = await _prefs;
    await prefs.setInt(_lastSetupPopupShownKey, timestamp);
  }

  Future<int?> getLastSetupPopupShown() async {
    final prefs = await _prefs;
    return prefs.getInt(_lastSetupPopupShownKey);
  }

  Future<void> clearLastSetupPopupShown() async {
    final prefs = await _prefs;
    await prefs.remove(_lastSetupPopupShownKey);
  }

  Future<void> setPremiumMember(bool isPremium) async {
    final prefs = await _prefs;
    await prefs.setBool(_isPremiumMemberKey, isPremium);
  }

  Future<bool> isPremiumMember() async {
    final prefs = await _prefs;
    return prefs.getBool(_isPremiumMemberKey) ?? false;
  }

  Future<void> setPurchased(bool isPurchased) async {
    final prefs = await _prefs;
    await prefs.setBool(_isPurchasedKey, isPurchased);
  }

  Future<bool> isPurchased() async {
    final prefs = await _prefs;
    return prefs.getBool(_isPurchasedKey) ?? false;
  }

  // Traveler profile cache
  Future<void> setProfileDisplayName(String name) async {
    final prefs = await _prefs;
    await prefs.setString(_profileDisplayNameKey, name);
  }

  Future<String?> getProfileDisplayName() async {
    final prefs = await _prefs;
    return prefs.getString(_profileDisplayNameKey);
  }

  Future<void> setProfileBio(String bio) async {
    final prefs = await _prefs;
    await prefs.setString(_profileBioKey, bio);
  }

  Future<String?> getProfileBio() async {
    final prefs = await _prefs;
    return prefs.getString(_profileBioKey);
  }

  Future<void> setProfileCurrentLocation(String location) async {
    final prefs = await _prefs;
    await prefs.setString(_profileCurrentLocationKey, location);
  }

  Future<String?> getProfileCurrentLocation() async {
    final prefs = await _prefs;
    return prefs.getString(_profileCurrentLocationKey);
  }

  Future<void> setProfileAvatarUrl(String avatarUrl) async {
    final prefs = await _prefs;
    await prefs.setString(_profileAvatarUrlKey, avatarUrl);
  }

  Future<String?> getProfileAvatarUrl() async {
    final prefs = await _prefs;
    return prefs.getString(_profileAvatarUrlKey);
  }

  Future<void> setTravelerTags(List<String> tags) async {
    final prefs = await _prefs;
    await prefs.setStringList(_travelerTagsKey, tags);
  }

  Future<List<String>> getTravelerTags() async {
    final prefs = await _prefs;
    return prefs.getStringList(_travelerTagsKey) ?? <String>[];
  }

  // Generic methods for any key-value storage
  Future<void> setString(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  Future<void> setInt(String key, int value) async {
    final prefs = await _prefs;
    await prefs.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final prefs = await _prefs;
    return prefs.getInt(key);
  }

  Future<void> setDouble(String key, double value) async {
    final prefs = await _prefs;
    await prefs.setDouble(key, value);
  }

  Future<double?> getDouble(String key) async {
    final prefs = await _prefs;
    return prefs.getDouble(key);
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final prefs = await _prefs;
    return prefs.getBool(key);
  }

  Future<void> setStringList(String key, List<String> value) async {
    final prefs = await _prefs;
    await prefs.setStringList(key, value);
  }

  Future<List<String>?> getStringList(String key) async {
    final prefs = await _prefs;
    return prefs.getStringList(key);
  }

  // Remove specific key
  Future<void> remove(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }

  // Clear all data (except auth data)
  Future<void> clearAllData() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  // Check if key exists
  Future<bool> containsKey(String key) async {
    final prefs = await _prefs;
    return prefs.containsKey(key);
  }

  // Get all keys
  Future<Set<String>> getKeys() async {
    final prefs = await _prefs;
    return prefs.getKeys();
  }
}
