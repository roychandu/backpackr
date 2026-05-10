import 'package:backpackr/features/chat/models/chat_message.dart';
import 'package:backpackr/features/chat/models/conversation.dart';
import 'package:backpackr/features/chat/repositories/chat_repository.dart';
import 'package:backpackr/shared/services/user_setup_service.dart';
import 'package:flutter/foundation.dart';

class ChatController extends ChangeNotifier {
  ChatController({ChatRepository? repository})
    : _repository = repository ?? ChatRepository();

  final ChatRepository _repository;

  bool isSending = false;
  String? errorMessage;
  int conversationRefreshToken = 0;
  List<Map<String, String>> mutualConnections = [];
  List<Map<String, String>> availableConnections = [];
  final Set<String> selectedParticipantIds = {};
  bool isLoadingConnections = false;
  bool isCreatingGroup = false;
  bool isAddingParticipants = false;

  String? get currentUserId => _repository.currentUserId;

  Stream<List<Conversation>> get conversations =>
      _repository.getConversations();

  Stream<List<ChatMessage>> messagesFor(String conversationId) {
    return _repository.getMessages(conversationId);
  }

  Future<bool> hasCompletedProfileSetup() {
    return UserSetupService.hasCompletedSetup();
  }

  String displayNameFor(Conversation conversation) {
    final userId = currentUserId;
    if (userId == null) return '';
    return conversation.getDisplayName(userId);
  }

  bool hasUnreadMessages(Conversation conversation) {
    final userId = currentUserId;
    if (userId == null) return false;
    return conversation.hasUnreadMessages(userId);
  }

  int unreadCountFor(Conversation conversation) {
    final userId = currentUserId;
    if (userId == null) return 0;
    return conversation.getUnreadCount(userId);
  }

  String titleFor(Conversation conversation) {
    final userId = currentUserId;
    if (conversation.isGroup) {
      return conversation.groupName ?? 'Group Chat';
    }
    if (userId == null) return '';
    return conversation.getOtherParticipantName(userId);
  }

  String otherParticipantIdFor(Conversation conversation) {
    final userId = currentUserId;
    if (userId == null || conversation.isGroup) return '';
    return conversation.getOtherParticipantId(userId);
  }

  bool isCurrentUser(String userId) => currentUserId == userId;

  bool isCurrentUserMessage(ChatMessage message) {
    return message.senderId == currentUserId;
  }

  bool isCurrentUserAdmin(Conversation conversation) {
    final userId = currentUserId;
    return userId != null && conversation.isAdmin(userId);
  }

  String formatConversationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }

  String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }

  void refreshConversations() {
    conversationRefreshToken++;
    notifyListeners();
  }

  Future<void> markMessagesAsRead(String conversationId) {
    return _repository.markMessagesAsRead(conversationId);
  }

  Future<void> sendConversationMessage({
    required String conversationId,
    required String content,
  }) {
    return _repository.sendMessage(
      conversationId: conversationId,
      content: content,
    );
  }

  Future<void> blockConversationUser(Conversation conversation) {
    final otherUserId = otherParticipantIdFor(conversation);
    if (otherUserId.isEmpty) {
      throw Exception('Unable to find user to block');
    }
    return _repository.blockUser(otherUserId);
  }

  Future<void> deleteConversation(String conversationId) {
    return _repository.deleteConversation(conversationId);
  }

  Future<void> leaveGroup(Conversation conversation) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _repository.removeParticipantFromGroup(
      conversationId: conversation.id,
      participantId: userId,
    );
    await _repository.deleteConversation(conversation.id);
  }

  Future<List<Map<String, String>>> getMutualConnections() {
    return _repository.getMutualConnections();
  }

  Future<void> loadMutualConnectionsForGroupCreation() async {
    isLoadingConnections = true;
    errorMessage = null;
    notifyListeners();

    try {
      mutualConnections = await _repository.getMutualConnections();
      selectedParticipantIds.clear();
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoadingConnections = false;
      notifyListeners();
    }
  }

  Future<void> loadAvailableConnectionsForGroup(
    Conversation conversation,
  ) async {
    isLoadingConnections = true;
    errorMessage = null;
    notifyListeners();

    try {
      final allConnections = await _repository.getMutualConnections();
      availableConnections = availableConnectionsForGroup(
        connections: allConnections,
        conversation: conversation,
      );
      selectedParticipantIds.clear();
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoadingConnections = false;
      notifyListeners();
    }
  }

  void toggleParticipant(String participantId, bool selected) {
    if (selected) {
      selectedParticipantIds.add(participantId);
    } else {
      selectedParticipantIds.remove(participantId);
    }
    notifyListeners();
  }

  List<Map<String, String>> availableConnectionsForGroup({
    required List<Map<String, String>> connections,
    required Conversation conversation,
  }) {
    return connections.where((connection) {
      final userId = connection['id'];
      return userId != null && !conversation.participants.containsKey(userId);
    }).toList();
  }

  Map<String, String> participantNamesFor({
    required Iterable<String> participantIds,
    required List<Map<String, String>> connections,
  }) {
    final participantNames = <String, String>{};
    for (final participantId in participantIds) {
      final connection = connections.firstWhere(
        (connection) => connection['id'] == participantId,
      );
      participantNames[participantId] = connection['name']!;
    }
    return participantNames;
  }

  Future<Conversation> createGroup({
    required String groupName,
    required Iterable<String> selectedParticipantIds,
    required List<Map<String, String>> connections,
  }) async {
    final participantNames = participantNamesFor(
      participantIds: selectedParticipantIds,
      connections: connections,
    );
    final groupId = await _repository.createGroupChat(
      groupName: groupName,
      participantIds: selectedParticipantIds.toList(),
      participantNames: participantNames,
    );
    final conversations = await _repository.getConversations().first;
    return conversations.firstWhere(
      (conversation) => conversation.id == groupId,
    );
  }

  Future<Conversation> createSelectedGroup(String groupName) async {
    if (groupName.isEmpty) {
      throw Exception('Please enter a group name');
    }

    if (selectedParticipantIds.length < 2) {
      throw Exception('Please select at least 2 participants');
    }

    isCreatingGroup = true;
    errorMessage = null;
    notifyListeners();

    try {
      return await createGroup(
        groupName: groupName,
        selectedParticipantIds: selectedParticipantIds,
        connections: mutualConnections,
      );
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isCreatingGroup = false;
      notifyListeners();
    }
  }

  Future<void> addParticipantsToGroup({
    required Conversation conversation,
    required Iterable<String> selectedParticipantIds,
    required List<Map<String, String>> connections,
  }) async {
    for (final participantId in selectedParticipantIds) {
      final connection = connections.firstWhere(
        (connection) => connection['id'] == participantId,
      );
      await _repository.addParticipantToGroup(
        conversationId: conversation.id,
        participantId: participantId,
        participantName: connection['name']!,
      );
    }
  }

  Future<void> addSelectedParticipantsToGroup(Conversation conversation) async {
    if (selectedParticipantIds.isEmpty) {
      throw Exception('Please select at least one participant');
    }

    isAddingParticipants = true;
    errorMessage = null;
    notifyListeners();

    try {
      await addParticipantsToGroup(
        conversation: conversation,
        selectedParticipantIds: selectedParticipantIds,
        connections: availableConnections,
      );
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isAddingParticipants = false;
      notifyListeners();
    }
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
