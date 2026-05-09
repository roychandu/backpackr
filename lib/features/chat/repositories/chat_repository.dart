import 'package:backpackr/features/chat/data_sources/firebase_chat_data_source.dart';
import 'package:backpackr/features/chat/models/chat_message.dart';
import 'package:backpackr/features/chat/models/conversation.dart';

class ChatRepository {
  ChatRepository({FirebaseChatDataSource? dataSource})
    : _dataSource = dataSource ?? FirebaseChatDataSource();

  final FirebaseChatDataSource _dataSource;

  Stream<List<Conversation>> getConversations() {
    return _dataSource.getConversations();
  }

  Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _dataSource.getMessages(conversationId);
  }

  Future<String> createConversation({
    required String otherUserId,
    required String otherUserName,
  }) {
    return _dataSource.createConversation(
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
    return _dataSource.sendMessage(
      conversationId: conversationId,
      content: content,
      type: type,
      replyToMessageId: replyToMessageId,
      metadata: metadata,
    );
  }
}
