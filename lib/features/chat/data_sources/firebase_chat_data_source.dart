import 'package:backpackr/features/chat/models/chat_message.dart';
import 'package:backpackr/features/chat/models/conversation.dart';
import 'package:backpackr/features/chat/data_sources/chat_service.dart';

class FirebaseChatDataSource {
  FirebaseChatDataSource({ChatService? chatService})
    : _chatService = chatService ?? ChatService();

  final ChatService _chatService;

  String? get currentUserId => _chatService.currentUserId;

  Stream<List<Conversation>> getConversations() {
    return _chatService.getConversations();
  }

  Stream<int> getTotalUnreadCount() {
    return _chatService.getTotalUnreadCount();
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

  Future<void> markMessagesAsRead(String conversationId) {
    return _chatService.markMessagesAsRead(conversationId);
  }

  Future<void> deleteConversation(String conversationId) {
    return _chatService.deleteConversation(conversationId);
  }

  Future<void> blockUser(String userId) {
    return _chatService.blockUser(userId);
  }

  Future<void> removeParticipantFromGroup({
    required String conversationId,
    required String participantId,
  }) {
    return _chatService.removeParticipantFromGroup(
      conversationId: conversationId,
      participantId: participantId,
    );
  }

  Future<List<Map<String, String>>> getMutualConnections() {
    return _chatService.getMutualConnections();
  }

  Future<String> createGroupChat({
    required String groupName,
    required List<String> participantIds,
    required Map<String, String> participantNames,
  }) {
    return _chatService.createGroupChat(
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
    return _chatService.addParticipantToGroup(
      conversationId: conversationId,
      participantId: participantId,
      participantName: participantName,
    );
  }
}
