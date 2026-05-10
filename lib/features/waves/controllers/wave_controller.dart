import 'package:backpackr/features/chat/models/conversation.dart';
import 'package:backpackr/features/chat/repositories/chat_repository.dart';
import 'package:backpackr/features/waves/models/wave.dart';
import 'package:backpackr/features/waves/repositories/wave_repository.dart';
import 'package:flutter/foundation.dart';

class WaveController extends ChangeNotifier {
  WaveController({WaveRepository? repository, ChatRepository? chatRepository})
    : _repository = repository ?? WaveRepository(),
      _chatRepository = chatRepository ?? ChatRepository();

  final WaveRepository _repository;
  final ChatRepository _chatRepository;

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

  String? get currentUserId => _repository.currentUserId;

  Future<Map<WaveType, List<Wave>>> getWavesByType() {
    return _repository.getWavesByType();
  }

  Future<void> ignoreWave(String waveId) {
    return _repository.ignoreWave(waveId);
  }

  Future<void> deleteWave(String waveId) {
    return _repository.deleteWave(waveId);
  }

  Future<Conversation> startConversation({
    required String otherUserId,
    required String otherUserName,
  }) async {
    final conversationId = await _chatRepository.createConversation(
      otherUserId: otherUserId,
      otherUserName: otherUserName,
    );
    final conversations = await _chatRepository.getConversations().first;
    return conversations.firstWhere(
      (conversation) => conversation.id == conversationId,
      orElse: () => throw Exception('Conversation not found'),
    );
  }
}
