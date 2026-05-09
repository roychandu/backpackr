import 'package:backpackr/features/chat/models/chat_message.dart';
import 'package:backpackr/features/chat/models/conversation.dart';
import 'package:backpackr/features/chat/repositories/chat_repository.dart';
import 'package:flutter/foundation.dart';

class ChatController extends ChangeNotifier {
  ChatController({ChatRepository? repository})
    : _repository = repository ?? ChatRepository();

  final ChatRepository _repository;

  bool isSending = false;
  String? errorMessage;

  Stream<List<Conversation>> get conversations =>
      _repository.getConversations();

  Stream<List<ChatMessage>> messagesFor(String conversationId) {
    return _repository.getMessages(conversationId);
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    isSending = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.sendMessage(
        conversationId: conversationId,
        content: content,
        type: type,
        replyToMessageId: replyToMessageId,
        metadata: metadata,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
