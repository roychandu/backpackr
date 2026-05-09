import 'package:hive/hive.dart';

part 'conversation.g.dart';

@HiveType(typeId: 4)
class Conversation {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final Map<String, bool> participants;
  @HiveField(2)
  final Map<String, String> participantNames;
  @HiveField(3)
  final String lastMessageId;
  @HiveField(4)
  final String lastMessageContent;
  @HiveField(5)
  final String lastMessageSenderId;
  @HiveField(6)
  final DateTime lastMessageTimestamp;
  @HiveField(7)
  final bool isActive;
  @HiveField(8)
  final DateTime createdAt;
  @HiveField(9)
  final DateTime updatedAt;
  @HiveField(10)
  final Map<String, bool> readStatus;
  @HiveField(11)
  final Map<String, int> unreadCounts;
  @HiveField(12)
  final bool isGroup;
  @HiveField(13)
  final String? groupName;
  @HiveField(14)
  final String? groupAvatarUrl;
  @HiveField(15)
  final String? createdBy;
  @HiveField(16)
  final List<String> admins;

  Conversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.lastMessageId,
    required this.lastMessageContent,
    required this.lastMessageSenderId,
    required this.lastMessageTimestamp,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.readStatus = const {},
    this.unreadCounts = const {},
    this.isGroup = false,
    this.groupName,
    this.groupAvatarUrl,
    this.createdBy,
    this.admins = const [],
  });

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] ?? '',
      participants: Map<String, bool>.from(map['participants'] ?? {}),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      lastMessageId: map['lastMessageId'] ?? '',
      lastMessageContent: map['lastMessageContent'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      lastMessageTimestamp: DateTime.parse(map['lastMessageTimestamp']),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      readStatus: Map<String, bool>.from(map['readStatus'] ?? {}),
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      isGroup: map['isGroup'] ?? false,
      groupName: map['groupName'],
      groupAvatarUrl: map['groupAvatarUrl'],
      createdBy: map['createdBy'],
      admins: map['admins'] != null ? List<String>.from(map['admins']) : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'participantNames': participantNames,
      'lastMessageId': lastMessageId,
      'lastMessageContent': lastMessageContent,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTimestamp': lastMessageTimestamp.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'readStatus': readStatus,
      'unreadCounts': unreadCounts,
      'isGroup': isGroup,
      if (groupName != null) 'groupName': groupName,
      if (groupAvatarUrl != null) 'groupAvatarUrl': groupAvatarUrl,
      if (createdBy != null) 'createdBy': createdBy,
      'admins': admins,
    };
  }

  String getOtherParticipantId(String currentUserId) {
    return participants.keys.firstWhere((id) => id != currentUserId);
  }

  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantNames[otherId] ?? 'Unknown User';
  }

  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  bool hasUnreadMessages(String userId) {
    return getUnreadCount(userId) > 0;
  }

  Conversation copyWith({
    String? id,
    Map<String, bool>? participants,
    Map<String, String>? participantNames,
    String? lastMessageId,
    String? lastMessageContent,
    String? lastMessageSenderId,
    DateTime? lastMessageTimestamp,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, bool>? readStatus,
    Map<String, int>? unreadCounts,
    bool? isGroup,
    String? groupName,
    String? groupAvatarUrl,
    String? createdBy,
    List<String>? admins,
  }) {
    return Conversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readStatus: readStatus ?? this.readStatus,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      isGroup: isGroup ?? this.isGroup,
      groupName: groupName ?? this.groupName,
      groupAvatarUrl: groupAvatarUrl ?? this.groupAvatarUrl,
      createdBy: createdBy ?? this.createdBy,
      admins: admins ?? this.admins,
    );
  }

  /// Get display name for conversation (group name or other user's name)
  String getDisplayName(String currentUserId) {
    if (isGroup) {
      return groupName ?? 'Group Chat';
    }
    return getOtherParticipantName(currentUserId);
  }

  /// Check if current user is admin
  bool isAdmin(String userId) {
    return admins.contains(userId) || createdBy == userId;
  }

  /// Get participant count
  int get participantCount => participants.length;
}
