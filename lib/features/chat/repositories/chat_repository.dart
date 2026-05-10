import 'package:backpackr/features/chat/data_sources/firebase_chat_data_source.dart';
import 'package:backpackr/features/chat/models/chat_message.dart';
import 'package:backpackr/features/chat/models/conversation.dart';

class ChatRepository {
  ChatRepository({FirebaseChatDataSource? dataSource})
    : _dataSource = dataSource ?? FirebaseChatDataSource();

  final FirebaseChatDataSource _dataSource;

  String? get currentUserId => _dataSource.currentUserId;

  Stream<List<Conversation>> getConversations() {
    return _dataSource.getConversations();
  }

  Stream<int> getTotalUnreadCount() {
    return _dataSource.getTotalUnreadCount();
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

  Future<void> markMessagesAsRead(String conversationId) {
    return _dataSource.markMessagesAsRead(conversationId);
  }

  Future<void> deleteConversation(String conversationId) {
    return _dataSource.deleteConversation(conversationId);
  }

  Future<void> blockUser(String userId) {
    return _dataSource.blockUser(userId);
  }

  Future<void> removeParticipantFromGroup({
    required String conversationId,
    required String participantId,
  }) {
    return _dataSource.removeParticipantFromGroup(
      conversationId: conversationId,
      participantId: participantId,
    );
  }

  Future<List<Map<String, String>>> getMutualConnections() {
    return _dataSource.getMutualConnections();
  }

  Future<String> createGroupChat({
    required String groupName,
    required List<String> participantIds,
    required Map<String, String> participantNames,
  }) {
    return _dataSource.createGroupChat(
      groupName: groupName,
      participantIds: participantIds,
      participantNames: participantNames,
    );
  }

  Future<void> addParticipantToGroup({
    required String conversationId,
    required String participantId,
    required String participantName,
  }) {
    return _dataSource.addParticipantToGroup(
      conversationId: conversationId,
      participantId: participantId,
      participantName: participantName,
    );
  }
}
