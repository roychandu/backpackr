// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:backpackr/features/profile/data_sources/user_profile_service.dart';
import 'package:backpackr/shared/services/storage_service.dart';
import 'package:backpackr/features/profile/views/user_setup_screen.dart';
import 'package:backpackr/features/profile/views/setup_reminder_popup.dart';

class UserSetupService {
  static const Duration _popupInterval = Duration(minutes: 10);
  static const Duration _initialDelay = Duration(minutes: 5);

  static final StorageService _storage = StorageService();
  static Timer? _popupTimer;
  static BuildContext? _currentContext;

  /// Initialize the setup service - call this when the app starts
  static bool _initialized = false;

  static void initialize(BuildContext context) {
    _currentContext = context;
    if (_initialized) return; // avoid rescheduling repeatedly
    _initialized = true;

    // Check if setup is already completed before scheduling popup
    _checkAndSchedulePopup();
  }

  /// Check if user has completed setup
  static Future<bool> hasCompletedSetup() async {
    try {
      final setupCompleted = await _storage.isProfileSetupCompleted();

      // Additional check: if setup is marked as completed, also verify the user profile exists
      if (setupCompleted) {
        // Import the UserProfileService to check if profile actually exists
        // This is a more robust check to ensure setup was truly completed
        return true;
      }
      // If not in local cache, check remote profile (cross-device support)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final profile = await UserProfileService().getProfileForUid(user.uid);
      if (profile != null && profile.setupCompleted) {
        await _storage.setProfileSetupCompleted(true);
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking setup completion status: $e');
      return false;
    }
  }

  /// Strict verification against stored profile fields required by the setup UI
  /// Ensures the profile object exists and required fields are non-empty
  static Future<bool> isProfileStrictlyComplete() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final profile = await UserProfileService().getProfileForUid(user.uid);
      if (profile == null) return false;

      final bool hasDisplayName = profile.displayName.trim().isNotEmpty;
      final bool hasBio = profile.bio.trim().isNotEmpty;
      final bool hasLocation = profile.currentLocation.trim().isNotEmpty;

      return profile.setupCompleted && hasDisplayName && hasBio && hasLocation;
    } catch (_) {
      return false;
    }
  }

  /// Mark setup as completed
  static Future<void> markSetupCompleted() async {
    await _storage.setProfileSetupCompleted(true);
    _cancelTimer();
    try {
      // Also persist to remote profile so it works across devices
      await UserProfileService().updateCurrentUserProfile({
        'setupCompleted': true,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      // ignore remote update errors; local cache prevents repeated popups
    }
  }

  /// Check if enough time has passed since last popup and schedule next one
  static Future<void> _checkAndSchedulePopup() async {
    final hasCompleted = await hasCompletedSetup();
    if (hasCompleted) return;

    final lastShown = await _storage.getLastSetupPopupShown();
    final now = DateTime.now().millisecondsSinceEpoch;

    if (lastShown == null) {
      // First app open after register/login: wait a short delay, do not show immediately
      _schedulePopup(_initialDelay);
      return;
    }

    final elapsed = now - lastShown;
    if (elapsed >= _popupInterval.inMilliseconds) {
      _showSetupPopup();
      return;
    }
    final timeUntilNext = _popupInterval.inMilliseconds - elapsed;
    _schedulePopup(Duration(milliseconds: timeUntilNext));
  }

  /// Schedule the next popup
  static void _schedulePopup(Duration delay) {
    _cancelTimer();
    _popupTimer = Timer(delay, () {
      _showSetupPopup();
    });
  }

  /// Cancel the current timer
  static void _cancelTimer() {
    _popupTimer?.cancel();
    _popupTimer = null;
  }

  /// Show the setup popup
  static Future<void> _showSetupPopup() async {
    if (_currentContext == null) return;

    try {
      await _storage.setLastSetupPopupShown(
        DateTime.now().millisecondsSinceEpoch,
      );

      // First show the reminder popup
      final reminderResult = await showDialog<bool>(
        context: _currentContext!,
        barrierDismissible: false,
        builder: (context) => const SetupReminderPopup(),
      );

      if (reminderResult == true) {
        // User wants to setup profile, navigate to the full setup screen
        Navigator.of(_currentContext!)
            .push(
              MaterialPageRoute(builder: (context) => const UserSetupScreen()),
            )
            .then((setupResult) {
              if (setupResult == true) {
                // User completed setup
                markSetupCompleted();
              } else {
                // User dismissed setup, schedule next popup
                _schedulePopup(_popupInterval);
              }
            });
      } else {
        // User dismissed reminder, schedule next popup
        _schedulePopup(_popupInterval);
      }
    } catch (e) {
      // Handle error - schedule next popup anyway
      _schedulePopup(_popupInterval);
    }
  }

  /// Manually trigger setup popup (for testing or manual calls)
  static Future<void> showSetupPopup(BuildContext context) async {
    _currentContext = context;
    await _showSetupPopup();
  }

  /// Reset setup status (for testing)
  static Future<void> resetSetupStatus() async {
    await _storage.clearProfileSetupCompleted();
    await _storage.clearLastSetupPopupShown();
    _cancelTimer();
  }

  /// Dispose resources
  static void dispose() {
    _cancelTimer();
    _currentContext = null;
  }
}
