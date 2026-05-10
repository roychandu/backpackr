import 'package:backpackr/features/auth/data_sources/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  User? get currentUser => _authService.currentUser;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? name,
  }) {
    return _authService.signUpWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
    );
  }

  Future<UserCredential?> signInAnonymously() {
    return _authService.signInAnonymously();
  }

  Future<void> signOut() {
    return _authService.signOut();
  }

  Future<UserCredential?> signInWithApple() {
    return _authService.signInWithApple();
  }

  Future<UserCredential?> signInWithGoogle() {
    return _authService.signInWithGoogle();
  }

  Future<Map<String, dynamic>> getUserData() {
    return _authService.getUserData();
  }

  Future<bool> hasAcceptedEula() {
    return _authService.hasAcceptedEula();
  }

  Future<void> acceptEula() {
    return _authService.acceptEula();
  }

  Future<void> updateUserProfile({String? displayName, String? photoURL}) {
    return _authService.updateUserProfile(
      displayName: displayName,
      photoURL: photoURL,
    );
  }

  Future<void> updateUserData(Map<String, dynamic> data) {
    return _authService.updateUserData(data);
  }

  Future<void> updatePremiumStatus(bool isPremium) {
    return _authService.updatePremiumStatus(isPremium);
  }

  Future<void> deleteAccount() {
    return _authService.deleteAccount();
  }

  Future<void> ensureUserDataInFirebase() {
    return _authService.ensureUserDataInFirebase();
  }
}
