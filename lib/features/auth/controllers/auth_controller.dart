import 'package:backpackr/features/auth/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

class AuthController extends ChangeNotifier {
  AuthController({AuthRepository? repository})
    : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  bool isLoading = false;
  String? errorMessage;

  Future<void> login({required String email, required String password}) async {
    await _run(() => _repository.login(email: email, password: password));
  }

  Future<void> register({
    required String email,
    required String password,
    String? name,
  }) async {
    await _run(
      () => _repository.register(email: email, password: password, name: name),
    );
  }

  Future<void> continueAsGuest() async {
    await _run(_repository.continueAsGuest);
  }

  Future<void> logout() async {
    await _run(_repository.logout);
  }

  Future<void> signInWithApple() async {
    await _run(_repository.signInWithApple);
  }

  Future<void> signInWithGoogle() async {
    await _run(_repository.signInWithGoogle);
  }

  Future<Map<String, dynamic>> getUserData() {
    return _repository.getUserData();
  }

  Future<bool> hasAcceptedEula() {
    return _repository.hasAcceptedEula();
  }

  Future<void> acceptEula() {
    return _repository.acceptEula();
  }

  Future<void> updateUserProfile({String? displayName, String? photoURL}) {
    return _repository.updateUserProfile(
      displayName: displayName,
      photoURL: photoURL,
    );
  }

  Future<void> updateUserData(Map<String, dynamic> data) {
    return _repository.updateUserData(data);
  }

  Future<void> updatePremiumStatus(bool isPremium) {
    return _repository.updatePremiumStatus(isPremium);
  }

  Future<void> deleteAccount() {
    return _repository.deleteAccount();
  }

  Future<void> ensureUserDataInFirebase() {
    return _repository.ensureUserDataInFirebase();
  }

  Future<void> _run(Future<Object?> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
