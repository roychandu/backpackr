import 'package:backpackr/features/waves/data_sources/firebase_wave_data_source.dart';
import 'package:backpackr/features/waves/models/wave.dart';

class WaveRepository {
  WaveRepository({FirebaseWaveDataSource? dataSource})
    : _dataSource = dataSource ?? FirebaseWaveDataSource();

  final FirebaseWaveDataSource _dataSource;

  String? get currentUserId => _dataSource.currentUserId;

  Future<List<Wave>> getUserWaves() => _dataSource.getUserWaves();

  Stream<List<Wave>> getWavesStream() => _dataSource.getWavesStream();

  Stream<int> getPendingReceivedWavesCount() {
    return _dataSource.getPendingReceivedWavesCount();
  }

  Future<String> sendWave({
    required String receiverId,
    required String receiverName,
    required String receiverLocation,
    String? message,
  }) {
    return _dataSource.sendWave(
      receiverId: receiverId,
      receiverName: receiverName,
      receiverLocation: receiverLocation,
      message: message,
    );
  }

  Future<void> acceptWave(String waveId) => _dataSource.acceptWave(waveId);

  Future<void> ignoreWave(String waveId) => _dataSource.ignoreWave(waveId);

  Future<void> deleteWave(String waveId) => _dataSource.deleteWave(waveId);

  Future<Map<WaveType, List<Wave>>> getWavesByType() {
    return _dataSource.getWavesByType();
  }
}
