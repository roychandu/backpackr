import 'package:backpackr/features/chat/models/chat_message.dart';
import 'package:backpackr/features/chat/models/conversation.dart';
import 'package:backpackr/features/chat/repositories/chat_service.dart';

class FirebaseChatDataSource {
  FirebaseChatDataSource({ChatService? chatService})
    : _chatService = chatService ?? ChatService();

  final ChatService _chatService;

  Stream<List<Conversation>> getConversations() {
    return _chatService.getConversations();
  }

  Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _chatService.getMessages(conversationId);
  }

  Future<String> createConversation({
    required String otherUserId,
    required String otherUserName,
  }) {
    return _chatService.createConversation(
      otherUserId: otherUserId,
      otherUserName: otherUserName,
    );
  }

  Future<String> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) {
    return _chatService.sendMessage(
      conversationId: conversationId,
      content: content,
      type: type,
      replyToMessageId: replyToMessageId,
      metadata: metadata,
    );
  }
}
