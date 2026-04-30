// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'storage_service.dart';

class AppFlowService {
  static final AppFlowService _instance = AppFlowService._internal();
  factory AppFlowService() => _instance;
  AppFlowService._internal();

  final StorageService _storage = StorageService();

  // Check if user has seen intro screen
  Future<bool> hasSeenIntro() async {
    try {
      return await _storage.hasSeenIntro();
    } catch (e) {
      print('Error checking intro status: $e');
      return false;
    }
  }

  // Mark intro as seen
  Future<void> markIntroAsSeen() async {
    try {
      await _storage.setIntroSeen(true);
    } catch (e) {
      print('Error marking intro as seen: $e');
    }
  }

  // Get the appropriate initial screen based on user state
  Future<String> getInitialRoute() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final hasSeenIntro = await this.hasSeenIntro();

      // If user is not logged in
      if (user == null) {
        // If user hasn't seen intro, show intro first
        if (!hasSeenIntro) {
          return '/intro';
        }
        // Otherwise, show login directly
        return '/login';
      }

      // If user is logged in, always go to home first
      // Business setup will be checked and shown if needed
      return '/home';
    } catch (e) {
      print('Error determining initial route: $e');
      return '/login';
    }
  }

  // Check if user should see intro screen
  Future<bool> shouldShowIntro() async {
    final user = FirebaseAuth.instance.currentUser;
    final hasSeenIntro = await this.hasSeenIntro();

    // Show intro only if user is not logged in and hasn't seen intro
    return user == null && !hasSeenIntro;
  }

  // Check if user should see login screen
  Future<bool> shouldShowLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    final hasSeenIntro = await this.hasSeenIntro();

    // Show login if user is not logged in and has seen intro
    return user == null && hasSeenIntro;
  }

  // Clear all app data (for logout)
  Future<void> clearAppData() async {
    try {
      // Get the intro status and setup completion status before clearing
      final hasSeenIntro = await _storage.hasSeenIntro();
      final setupCompleted = await _storage.isProfileSetupCompleted();

      // Clear all data
      await _storage.clearAllData();

      // Restore the intro status so user doesn't see intro again after logout
      if (hasSeenIntro) {
        await _storage.setIntroSeen(true);
      }

      // Restore the setup completion status so user doesn't see setup popup again after logout
      if (setupCompleted) {
        await _storage.setProfileSetupCompleted(true);
      }
    } catch (e) {
      print('Error clearing app data: $e');
    }
  }
}
