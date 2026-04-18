// ignore_for_file: avoid_print

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
// import 'notification_service.dart';
import 'auth_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Database references
  DatabaseReference get _chatsRef => _database.ref('chats');
  DatabaseReference get _messagesRef => _database.ref('messages');
  DatabaseReference get _usersRef => _database.ref('users');

  // Public getter for chats reference
  DatabaseReference get chatsRef => _chatsRef;

  /// Create a new conversation between two users
  Future<String> createConversation({
    required String otherUserId,
    required String otherUserName,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final currentUserData = await _authService.getUserData();
    final currentUserName = currentUserData['name'] ?? 'Unknown User';
    final currentUserEmail = currentUserData['email'] ?? '';

    // Save user data to Firebase for chat purposes
    await _saveUserDataToFirebase(
      currentUserId!,
      currentUserName,
      currentUserEmail,
    );

    // Check if conversation already exists
    final existingConversationId = await _findExistingConversation(otherUserId);
    if (existingConversationId != null) {
      return existingConversationId;
    }

    final conversationId = _chatsRef.push().key!;
    final now = DateTime.now();

    final conversation = Conversation(
      id: conversationId,
      participants: {currentUserId!: true, otherUserId: true},
      participantNames: {
        currentUserId!: currentUserName,
        otherUserId: otherUserName,
      },
      lastMessageId: '',
      lastMessageContent: 'Conversation started',
      lastMessageSenderId: currentUserId!,
      lastMessageTimestamp: now,
      createdAt: now,
      updatedAt: now,
    );

    await _chatsRef.child(conversationId).set(conversation.toMap());

    // Send initial system message
    await sendMessage(
      conversationId: conversationId,
      content: 'Conversation started',
      type: MessageType.system,
    );

    return conversationId;
  }

  /// Find existing conversation between two users
  Future<String?> _findExistingConversation(String otherUserId) async {
    if (currentUserId == null) return null;

    try {
      // Get all chats and filter client-side to avoid index requirement
      final snapshot = await _chatsRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> allChats =
            snapshot.value as Map<dynamic, dynamic>;

        for (final entry in allChats.entries) {
          final conversationData = Map<String, dynamic>.from(
            entry.value as Map<dynamic, dynamic>,
          );
          final participants = conversationData['participants'] as Map?;

          // Check if both current user and other user are participants
          if (participants != null &&
              participants[currentUserId] == true &&
              participants[otherUserId] == true) {
            return entry.key as String;
          }
        }
      }
    } catch (e) {
      print('Error finding existing conversation: $e');
    }

    return null;
  }

  /// Send a message to a conversation
  Future<String> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final currentUserData = await _authService.getUserData();
    final currentUserName = currentUserData['name'] ?? 'Unknown User';
    final currentUserEmail = currentUserData['email'] ?? '';

    // Save user data to Firebase for chat purposes
    await _saveUserDataToFirebase(
      currentUserId!,
      currentUserName,
      currentUserEmail,
    );

    final messageId = _messagesRef.child(conversationId).push().key!;
    final now = DateTime.now();

    final message = ChatMessage(
      id: messageId,
      conversationId: conversationId,
      senderId: currentUserId!,
      senderName: currentUserName,
      content: content,
      timestamp: now,
      type: type,
      replyToMessageId: replyToMessageId,
      metadata: metadata,
    );

    // Save message
    await _messagesRef
        .child(conversationId)
        .child(messageId)
        .set(message.toMap());

    // Update conversation
    await _updateConversation(
      conversationId: conversationId,
      messageId: messageId,
      content: content,
      senderId: currentUserId!,
      timestamp: now,
    );

    // Send notification to other participants
    await _sendNotificationToOtherParticipants(
      conversationId: conversationId,
      message: message,
    );

    return messageId;
  }

  /// Update conversation with latest message info
  Future<void> _updateConversation({
    required String conversationId,
    required String messageId,
    required String content,
    required String senderId,
    required DateTime timestamp,
  }) async {
    final conversationRef = _chatsRef.child(conversationId);

    await conversationRef.update({
      'lastMessageId': messageId,
      'lastMessageContent': content,
      'lastMessageSenderId': senderId,
      'lastMessageTimestamp': timestamp.toIso8601String(),
      'updatedAt': timestamp.toIso8601String(),
    });

    // Increment unread count for other participants
    final conversationSnapshot = await conversationRef.get();
    if (conversationSnapshot.exists) {
      final conversationData = Map<String, dynamic>.from(
        conversationSnapshot.value as Map<dynamic, dynamic>,
      );
      final participants = Map<String, bool>.from(
        conversationData['participants'] ?? {},
      );
      final unreadCounts = Map<String, int>.from(
        conversationData['unreadCounts'] ?? {},
      );
      final deletedBy = Map<String, dynamic>.from(
        conversationData['deletedBy'] ?? {},
      );

      // Restore conversation for any user who had deleted it
      // (new message should bring back the conversation)
      for (final participantId in participants.keys) {
        if (participantId != senderId) {
          unreadCounts[participantId] = (unreadCounts[participantId] ?? 0) + 1;
          // Remove from deletedBy if it was there
          if (deletedBy.containsKey(participantId)) {
            deletedBy.remove(participantId);
          }
        }
      }

      await conversationRef.update({
        'unreadCounts': unreadCounts,
        'deletedBy': deletedBy.isEmpty ? null : deletedBy,
      });
    }
  }

  /// Save user data to Firebase for chat purposes
  Future<void> _saveUserDataToFirebase(
    String userId,
    String userName,
    String email,
  ) async {
    await _usersRef.child(userId).set({
      'name': userName,
      'email': email,
      'lastSeen': DateTime.now().toIso8601String(),
    });
  }

  /// Send notification to other participants
  Future<void> _sendNotificationToOtherParticipants({
    required String conversationId,
    required ChatMessage message,
  }) async {
    final conversationSnapshot = await _chatsRef.child(conversationId).get();
    if (!conversationSnapshot.exists) return;

    // final conversationData = Map<String, dynamic>.from(
    //   conversationSnapshot.value as Map<dynamic, dynamic>,
    // );
    // final participants = Map<String, bool>.from(
    //   conversationData['participants'] ?? {},
    // );

    // Do NOT trigger local notifications from the sender's device.
    // Local notifications here would only ever show on the sender device,
    // causing the "self-notification" bug that users reported.
    // Push notifications (FCM) should be triggered from backend, or receivers
    // should display local notifications when they receive new messages via stream.
    return;
  }

  /// Get all conversations for current user
  Stream<List<Conversation>> getConversations() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // Get all chats and filter client-side to avoid index requirement
    return _chatsRef.onValue.map((event) {
      if (event.snapshot.value == null) return <Conversation>[];

      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      final conversations = <Conversation>[];

      for (final entry in data.entries) {
        try {
          final conversationData = Map<String, dynamic>.from(
            entry.value as Map<dynamic, dynamic>,
          );

          final participants = conversationData['participants'] as Map?;
          final deletedBy = conversationData['deletedBy'] as Map?;

          // Check if current user has deleted this conversation
          final isDeletedByCurrentUser =
              deletedBy != null && deletedBy[currentUserId] == true;

          // Only include conversations where current user is a participant
          // AND hasn't deleted it
          if (participants != null &&
              participants[currentUserId] == true &&
              !isDeletedByCurrentUser) {
            conversations.add(Conversation.fromMap(conversationData));
          }
        } catch (e) {
          print('Error parsing conversation: $e');
        }
      }

      // Sort by last message timestamp (newest first)
      conversations.sort(
        (a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp),
      );
      return conversations;
    });
  }

  /// Get messages for a specific conversation
  Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _messagesRef
        .child(conversationId)
        .orderByChild('timestamp')
        .onValue
        .map((event) {
          if (event.snapshot.value == null) return <ChatMessage>[];

          final Map<dynamic, dynamic> data =
              event.snapshot.value as Map<dynamic, dynamic>;
          final messages = <ChatMessage>[];

          for (final entry in data.entries) {
            final messageData = Map<String, dynamic>.from(
              entry.value as Map<dynamic, dynamic>,
            );
            messages.add(ChatMessage.fromMap(messageData));
          }

          // Sort by timestamp (oldest first for chat display)
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  /// Mark messages as read in a conversation
  Future<void> markMessagesAsRead(String conversationId) async {
    if (currentUserId == null) return;

    // Reset unread count for current user
    await _chatsRef.child(conversationId).update({
      'unreadCounts/$currentUserId': 0,
      'readStatus/$currentUserId': true,
    });
  }

  /// Get total unread message count for current user
  Stream<int> getTotalUnreadCount() {
    if (currentUserId == null) {
      return Stream.value(0);
    }

    // Get all chats and filter client-side to avoid index requirement
    return _chatsRef.onValue.map((event) {
      if (event.snapshot.value == null) return 0;

      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      int totalUnread = 0;

      for (final entry in data.entries) {
        try {
          final conversationData = entry.value as Map<dynamic, dynamic>;
          final participants = conversationData['participants'] as Map?;
          final deletedBy = conversationData['deletedBy'] as Map?;

          // Check if current user has deleted this conversation
          final isDeletedByCurrentUser =
              deletedBy != null && deletedBy[currentUserId] == true;

          // Only count if current user is a participant AND hasn't deleted it
          if (participants != null &&
              participants[currentUserId] == true &&
              !isDeletedByCurrentUser) {
            final unreadCounts = Map<String, int>.from(
              conversationData['unreadCounts'] ?? {},
            );
            totalUnread += unreadCounts[currentUserId] ?? 0;
          }
        } catch (e) {
          print('Error counting unread messages: $e');
        }
      }

      return totalUnread;
    });
  }

  /// Delete a conversation (soft delete - only for current user)
  Future<void> deleteConversation(String conversationId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Check if conversation exists
      final conversationSnapshot = await _chatsRef.child(conversationId).get();
      if (!conversationSnapshot.exists) {
        throw Exception('Conversation not found');
      }

      final conversationData = Map<String, dynamic>.from(
        conversationSnapshot.value as Map<dynamic, dynamic>,
      );
      final participants = Map<String, bool>.from(
        conversationData['participants'] ?? {},
      );
      final deletedBy = Map<String, bool>.from(
        conversationData['deletedBy'] ?? {},
      );

      // Check if user was ever a participant OR is already in deletedBy
      // (allows deletion even after leaving a group)
      final isOrWasParticipant =
          participants[currentUserId] == true ||
          deletedBy.containsKey(currentUserId);

      if (!isOrWasParticipant) {
        // Check if user's ID exists in participantNames (for groups they left)
        final participantNames = Map<String, String>.from(
          conversationData['participantNames'] ?? {},
        );
        if (!participantNames.containsKey(currentUserId)) {
          throw Exception('You are not associated with this conversation');
        }
      }

      // Mark as deleted for current user
      deletedBy[currentUserId!] = true;

      // Get all participants (current + past)
      final allParticipants = participants.keys.toSet();
      allParticipants.addAll(deletedBy.keys);

      // Check if all participants have deleted
      final allDeleted = allParticipants.every((uid) => deletedBy[uid] == true);

      if (allDeleted) {
        // If all users deleted it, permanently delete the conversation
        await _messagesRef.child(conversationId).remove();
        await _chatsRef.child(conversationId).remove();
      } else {
        // Otherwise, just mark as deleted for this user
        await _chatsRef.child(conversationId).update({
          'deletedBy/$currentUserId': true,
        });
      }
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception(
          'You do not have permission to delete this conversation',
        );
      }
      rethrow;
    }
  }

  /// Block a user (prevent new conversations)
  Future<void> blockUser(String userId) async {
    if (currentUserId == null) return;

    await _usersRef
        .child(currentUserId!)
        .child('blockedUsers')
        .child(userId)
        .set(DateTime.now().toIso8601String());
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    if (currentUserId == null) return;

    await _usersRef
        .child(currentUserId!)
        .child('blockedUsers')
        .child(userId)
        .remove();
  }

  /// Get blocked users list
  Future<List<String>> getBlockedUsers() async {
    if (currentUserId == null) return [];

    final snapshot = await _usersRef
        .child(currentUserId!)
        .child('blockedUsers')
        .get();

    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    return data.keys.cast<String>().toList();
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    final blockedUsers = await getBlockedUsers();
    return blockedUsers.contains(userId);
  }

  /// Search conversations by participant name
  Future<List<Conversation>> searchConversations(String query) async {
    if (currentUserId == null) return [];

    final conversationsSnapshot = await _chatsRef.get();
    if (!conversationsSnapshot.exists) return [];

    final Map<dynamic, dynamic> data =
        conversationsSnapshot.value as Map<dynamic, dynamic>;
    final matchingConversations = <Conversation>[];

    for (final entry in data.entries) {
      final conversationData = Map<String, dynamic>.from(
        entry.value as Map<dynamic, dynamic>,
      );
      final participants = Map<String, bool>.from(
        conversationData['participants'] ?? {},
      );
      final participantNames = Map<String, String>.from(
        conversationData['participantNames'] ?? {},
      );

      if (participants[currentUserId] == true) {
        // Check if any participant name matches the query
        final hasMatch = participantNames.values.any(
          (name) => name.toLowerCase().contains(query.toLowerCase()),
        );

        if (hasMatch) {
          matchingConversations.add(Conversation.fromMap(conversationData));
        }
      }
    }

    return matchingConversations;
  }

  /// Create a group chat with multiple users (mutual connections only)
  Future<String> createGroupChat({
    required String groupName,
    required List<String> participantIds,
    required Map<String, String> participantNames,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (participantIds.length < 2) {
      throw Exception('Group chat requires at least 2 participants');
    }

    // Add current user if not already in the list
    if (!participantIds.contains(currentUserId)) {
      participantIds.add(currentUserId!);
    }

    final currentUserData = await _authService.getUserData();
    final currentUserName = currentUserData['name'] ?? 'Unknown User';

    // Add current user's name to participant names
    participantNames[currentUserId!] = currentUserName;

    final groupId = _chatsRef.push().key!;
    final now = DateTime.now();

    // Create participants map
    final Map<String, bool> participants = {};
    for (final id in participantIds) {
      participants[id] = true;
    }

    final conversation = Conversation(
      id: groupId,
      participants: participants,
      participantNames: participantNames,
      lastMessageId: '',
      lastMessageContent: 'Group created',
      lastMessageSenderId: currentUserId!,
      lastMessageTimestamp: now,
      createdAt: now,
      updatedAt: now,
      isGroup: true,
      groupName: groupName,
      createdBy: currentUserId,
      admins: [currentUserId!],
    );

    await _chatsRef.child(groupId).set(conversation.toMap());

    // Send initial system message
    await sendMessage(
      conversationId: groupId,
      content: '$currentUserName created the group "$groupName"',
      type: MessageType.system,
    );

    return groupId;
  }

  /// Get mutual connections for creating group chats
  Future<List<Map<String, String>>> getMutualConnections() async {
    if (currentUserId == null) return [];

    try {
      final wavesSnapshot = await _database
          .ref('userProfiles')
          .child(currentUserId!)
          .child('waves')
          .get();

      if (!wavesSnapshot.exists) return [];

      final List<Map<String, String>> mutualConnections = [];
      final Set<String> addedUsers = {};

      for (final child in wavesSnapshot.children) {
        try {
          final waveData = Map<String, dynamic>.from(
            child.value as Map<dynamic, dynamic>,
          );

          // Only include accepted waves (mutual connections)
          if (waveData['status'] == 'accepted') {
            String otherUserId;
            String otherUserName;

            if (waveData['senderId'] == currentUserId) {
              otherUserId = waveData['receiverId'] as String;
              otherUserName = waveData['receiverName'] as String;
            } else {
              otherUserId = waveData['senderId'] as String;
              otherUserName = waveData['senderName'] as String;
            }

            // Avoid duplicates
            if (!addedUsers.contains(otherUserId)) {
              mutualConnections.add({'id': otherUserId, 'name': otherUserName});
              addedUsers.add(otherUserId);
            }
          }
        } catch (e) {
          print('Error parsing wave for mutual connections: $e');
        }
      }

      return mutualConnections;
    } catch (e) {
      print('Error fetching mutual connections: $e');
      return [];
    }
  }

  /// Add participant to group chat (admin only)
  Future<void> addParticipantToGroup({
    required String conversationId,
    required String participantId,
    required String participantName,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final conversationRef = _chatsRef.child(conversationId);
    final snapshot = await conversationRef.get();

    if (!snapshot.exists) {
      throw Exception('Group not found');
    }

    final conversationData = Map<String, dynamic>.from(
      snapshot.value as Map<dynamic, dynamic>,
    );
    final conversation = Conversation.fromMap(conversationData);

    if (!conversation.isGroup) {
      throw Exception('This is not a group chat');
    }

    if (!conversation.isAdmin(currentUserId!)) {
      throw Exception('Only admins can add participants');
    }

    await conversationRef.update({
      'participants/$participantId': true,
      'participantNames/$participantId': participantName,
    });

    // Send system message
    final currentUserName =
        conversation.participantNames[currentUserId] ?? 'Someone';
    await sendMessage(
      conversationId: conversationId,
      content: '$currentUserName added $participantName to the group',
      type: MessageType.system,
    );
  }

  /// Remove participant from group chat (admin only or self)
  Future<void> removeParticipantFromGroup({
    required String conversationId,
    required String participantId,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final conversationRef = _chatsRef.child(conversationId);
    final snapshot = await conversationRef.get();

    if (!snapshot.exists) {
      throw Exception('Group not found');
    }

    final conversationData = Map<String, dynamic>.from(
      snapshot.value as Map<dynamic, dynamic>,
    );
    final conversation = Conversation.fromMap(conversationData);

    if (!conversation.isGroup) {
      throw Exception('This is not a group chat');
    }

    // Allow if user is admin or removing themselves
    if (currentUserId != participantId &&
        !conversation.isAdmin(currentUserId!)) {
      throw Exception('Only admins can remove participants');
    }

    final participantName =
        conversation.participantNames[participantId] ?? 'Someone';

    // Send system message BEFORE removing participant
    String systemMessage;
    if (currentUserId == participantId) {
      systemMessage = '$participantName left the group';
    } else {
      final currentUserName =
          conversation.participantNames[currentUserId] ?? 'Someone';
      systemMessage =
          '$currentUserName removed $participantName from the group';
    }

    // Create and save system message directly (bypassing sendMessage to avoid auth issues)
    try {
      final messageId = _messagesRef.child(conversationId).push().key!;
      final now = DateTime.now();

      await _messagesRef.child(conversationId).child(messageId).set({
        'id': messageId,
        'conversationId': conversationId,
        'senderId': 'system',
        'senderName': 'System',
        'content': systemMessage,
        'timestamp': now.toIso8601String(),
        'type': 'system',
      });

      // Update conversation's last message
      await conversationRef.update({
        'lastMessageId': messageId,
        'lastMessageContent': systemMessage,
        'lastMessageSenderId': 'system',
        'lastMessageTimestamp': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
    } catch (e) {
      print('Error sending system message: $e');
    }

    // Now remove the participant
    await conversationRef.update({
      'participants/$participantId': null,
      'participantNames/$participantId': null,
    });
  }
}
