import 'package:backpackr/features/waves/models/wave.dart';
import 'package:backpackr/features/waves/repositories/wave_repository.dart';
import 'package:flutter/foundation.dart';

class WaveController extends ChangeNotifier {
  WaveController({WaveRepository? repository})
    : _repository = repository ?? WaveRepository();

  final WaveRepository _repository;

  List<Wave> waves = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadWaves() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      waves = await _repository.getUserWaves();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptWave(String waveId) async {
    await _repository.acceptWave(waveId);
    await loadWaves();
  }
}
