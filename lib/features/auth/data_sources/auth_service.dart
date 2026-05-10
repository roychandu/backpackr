// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:backpackr/shared/services/app_flow_service.dart';
import 'package:flutter/material.dart';
import 'package:backpackr/shared/services/storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storage = StorageService();
  static const String _userKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _eulaAcceptedKey = 'eula_accepted';

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Save user data to SharedPreferences
  Future<void> saveUserData({
    required String userId,
    required String email,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userId);
    await prefs.setString(_userEmailKey, email);
    if (name != null) {
      await prefs.setString(_userNameKey, name);
    }
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Get user data from SharedPreferences
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedUserId = prefs.getString(_userKey);
    String? email = prefs.getString(_userEmailKey);
    String? name = prefs.getString(_userNameKey);
    String? photoURL;

    // Merge in FirebaseAuth live values
    if (currentUser != null) {
      email = currentUser!.email ?? email;
      name = currentUser!.displayName ?? name;
      photoURL = currentUser!.photoURL ?? photoURL;
    }

    // Merge in Realtime Database values if present
    if (currentUser != null) {
      try {
        final DataSnapshot snap = await FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(currentUser!.uid)
            .get();
        if (snap.exists && snap.value is Map) {
          final map = Map<String, dynamic>.from(snap.value as Map);
          if (map['name'] is String) name = map['name'] as String;
          if (map['photoURL'] is String) photoURL = map['photoURL'] as String;
          if (map['email'] is String) email = map['email'] as String;
        }
      } catch (_) {
        // ignore DB read errors, fall back to prefs/auth
      }

      // Also check user profile data for avatar URL if not found in user data
      if (photoURL == null || photoURL.isEmpty) {
        try {
          final profileSnap = await FirebaseDatabase.instance
              .ref()
              .child('userProfiles')
              .child(currentUser!.uid)
              .get();
          if (profileSnap.exists && profileSnap.value is Map) {
            final profileMap = Map<String, dynamic>.from(
              profileSnap.value as Map,
            );
            if (profileMap['avatarUrl'] is String &&
                (profileMap['avatarUrl'] as String).isNotEmpty) {
              photoURL = profileMap['avatarUrl'] as String;
            }
          }
        } catch (_) {
          // ignore profile read errors, keep existing photoURL
        }
      }
    }

    return {
      'userId': cachedUserId ?? currentUser?.uid,
      'email': email,
      'name': name,
      'photoURL': photoURL,
      'isPremiumMember': await _storage.isPremiumMember(),
    };
  }

  // Update premium membership status
  Future<void> updatePremiumStatus(bool isPremium) async {
    await _storage.setPremiumMember(isPremium);
    await _storage.setPurchased(isPremium);
  }

  // Clear user data from SharedPreferences
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Save user data to Firebase Realtime Database
  Future<void> _saveUserDataToFirebase(
    String userId,
    String userName,
    String email,
  ) async {
    try {
      await FirebaseDatabase.instance.ref('users').child(userId).set({
        'name': userName,
        'email': email,
        'lastSeen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Log error but don't throw - registration should still succeed
      debugPrint('Failed to save user data to Firebase: $e');
    }
  }

  // Ensure current user data exists in Firebase (for existing users)
  Future<void> ensureUserDataInFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData = await getUserData();
        await _saveUserDataToFirebase(
          user.uid,
          userData['name'] ??
              user.displayName ??
              user.email?.split('@').first ??
              'User',
          userData['email'] ?? user.email ?? '',
        );
      }
    } catch (e) {
      debugPrint('Failed to ensure user data in Firebase: $e');
    }
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (name != null && credential.user != null) {
        await credential.user!.updateDisplayName(name);
      }

      // Save user data to SharedPreferences
      await saveUserData(
        userId: credential.user!.uid,
        email: email,
        name: name,
      );

      // Save user data to Firebase Realtime Database
      await _saveUserDataToFirebase(
        credential.user!.uid,
        name ?? credential.user!.displayName ?? email.split('@').first,
        email,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to SharedPreferences
      await saveUserData(
        userId: credential.user!.uid,
        email: email,
        name: credential.user!.displayName,
      );

      // Ensure user data exists in Firebase Realtime Database
      await _saveUserDataToFirebase(
        credential.user!.uid,
        credential.user!.displayName ?? email.split('@').first,
        email,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in anonymously
  Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();

      // Save user data to SharedPreferences for anonymous user
      await saveUserData(
        userId: credential.user!.uid,
        email: 'guest@anonymous.com', // Placeholder email for anonymous users
        name: 'Guest User',
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await clearUserData();

      // Clear app flow data (intro status, etc.)
      final appFlowService = AppFlowService();
      await appFlowService.clearAppData();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      if (currentUser != null) {
        await currentUser!.updateDisplayName(displayName);
        if (photoURL != null) {
          await currentUser!.updatePhotoURL(photoURL);
        }

        // Update SharedPreferences if display name changed
        if (displayName != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userNameKey, displayName);
        }
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update user data in Realtime Database under users/<uid>
  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }
    final String uid = currentUser!.uid;
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(uid)
          .update(data);
      // Keep SharedPreferences name in sync if provided
      if (data.containsKey('name') && data['name'] is String) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userNameKey, data['name'] as String);
      }
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Delete user account
  Future<void> deleteUserAccount() async {
    try {
      if (currentUser != null) {
        await currentUser!.delete();
        await clearUserData();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Delete account (alias for deleteUserAccount)
  Future<void> deleteAccount() async {
    await deleteUserAccount();
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  // Check if email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      if (currentUser != null && !currentUser!.emailVerified) {
        await currentUser!.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Re-authenticate user (required for sensitive operations)
  Future<void> reAuthenticateUser(String password) async {
    try {
      if (currentUser != null && currentUser!.email != null) {
        final credential = EmailAuthProvider.credential(
          email: currentUser!.email!,
          password: password,
        );
        await currentUser!.reauthenticateWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Save user data
      await saveUserData(
        userId: userCredential.user!.uid,
        email: userCredential.user?.email ?? 'apple@user.com',
        name:
            userCredential.user?.displayName ??
            [
              appleCredential.givenName,
              appleCredential.familyName,
            ].whereType<String>().join(' ').trim(),
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Apple Sign-In failed: $e');
      throw _handleAuthException(e);
    } catch (e) {
      print('Apple Sign-In failed: $e');
      throw Exception('Apple Sign-In failed: $e');
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        // Save user data to SharedPreferences
        await saveUserData(
          userId: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          name: userCredential.user!.displayName,
        );

        // Save user data to Firebase Realtime Database
        await _saveUserDataToFirebase(
          userCredential.user!.uid,
          userCredential.user!.displayName ??
              userCredential.user!.email?.split('@').first ??
              'User',
          userCredential.user!.email ?? '',
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In failed: $e');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // Check if user has accepted EULA
  Future<bool> hasAcceptedEula() async {
    // Fast path: check local cache first
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getBool(_eulaAcceptedKey) ?? false;
    if (cached) return true;

    if (currentUser == null) return false;
    try {
      final DataSnapshot snap = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(currentUser!.uid)
          .child('eulaAccepted')
          .get();
      final bool accepted = snap.value == true;
      if (accepted) {
        await prefs.setBool(_eulaAcceptedKey, true);
      }
      return accepted;
    } catch (_) {
      return false;
    }
  }

  // Mark EULA as accepted
  Future<void> acceptEula() async {
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(currentUser!.uid)
          .update({
            'eulaAccepted': true,
            'eulaAcceptedAt': DateTime.now().toIso8601String(),
          });
      // Also set local cache for instant subsequent checks
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_eulaAcceptedKey, true);
    } catch (e) {
      throw Exception('Failed to save EULA acceptance: $e');
    }
  }
}
