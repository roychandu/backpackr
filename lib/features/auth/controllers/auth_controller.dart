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

  Future<void> _run(Future<Object?> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
