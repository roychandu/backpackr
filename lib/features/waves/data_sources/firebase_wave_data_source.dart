import 'package:backpackr/features/waves/models/wave.dart';
import 'package:backpackr/features/waves/data_sources/wave_service.dart';

class FirebaseWaveDataSource {
  FirebaseWaveDataSource({WaveService? waveService})
    : _waveService = waveService ?? WaveService();

  final WaveService _waveService;

  String? get currentUserId => _waveService.currentUserId;

  Future<List<Wave>> getUserWaves() => _waveService.getUserWaves();

  Stream<List<Wave>> getWavesStream() => _waveService.getWavesStream();

  Stream<int> getPendingReceivedWavesCount() {
    return _waveService.getPendingReceivedWavesCount();
  }

  Future<String> sendWave({
    required String receiverId,
    required String receiverName,
    required String receiverLocation,
    String? message,
  }) {
    return _waveService.sendWave(
      receiverId: receiverId,
      receiverName: receiverName,
      receiverLocation: receiverLocation,
      message: message,
    );
  }

  Future<void> acceptWave(String waveId) => _waveService.acceptWave(waveId);

  Future<void> ignoreWave(String waveId) => _waveService.ignoreWave(waveId);

  Future<void> deleteWave(String waveId) => _waveService.deleteWave(waveId);

  Future<Map<WaveType, List<Wave>>> getWavesByType() {
    return _waveService.getWavesByType();
  }
}
