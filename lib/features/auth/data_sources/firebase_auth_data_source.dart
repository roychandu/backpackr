import 'package:backpackr/features/auth/repositories/auth_service.dart';
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
}
