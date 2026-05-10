import 'package:backpackr/features/auth/data_sources/firebase_auth_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository({FirebaseAuthDataSource? dataSource})
    : _dataSource = dataSource ?? FirebaseAuthDataSource();

  final FirebaseAuthDataSource _dataSource;

  User? get currentUser => _dataSource.currentUser;

  Stream<User?> get authStateChanges => _dataSource.authStateChanges;

  Future<UserCredential?> login({
    required String email,
    required String password,
  }) {
    return _dataSource.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> register({
    required String email,
    required String password,
    String? name,
  }) {
    return _dataSource.signUpWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
    );
  }

  Future<UserCredential?> continueAsGuest() {
    return _dataSource.signInAnonymously();
  }

  Future<void> logout() {
    return _dataSource.signOut();
  }

  Future<UserCredential?> signInWithApple() {
    return _dataSource.signInWithApple();
  }

  Future<UserCredential?> signInWithGoogle() {
    return _dataSource.signInWithGoogle();
  }

  Future<Map<String, dynamic>> getUserData() {
    return _dataSource.getUserData();
  }

  Future<bool> hasAcceptedEula() {
    return _dataSource.hasAcceptedEula();
  }

  Future<void> acceptEula() {
    return _dataSource.acceptEula();
  }

  Future<void> updateUserProfile({String? displayName, String? photoURL}) {
    return _dataSource.updateUserProfile(
      displayName: displayName,
      photoURL: photoURL,
    );
  }

  Future<void> updateUserData(Map<String, dynamic> data) {
    return _dataSource.updateUserData(data);
  }

  Future<void> updatePremiumStatus(bool isPremium) {
    return _dataSource.updatePremiumStatus(isPremium);
  }

  Future<void> deleteAccount() {
    return _dataSource.deleteAccount();
  }

  Future<void> ensureUserDataInFirebase() {
    return _dataSource.ensureUserDataInFirebase();
  }
}
