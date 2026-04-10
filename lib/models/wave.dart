enum WaveStatus { pending, accepted, ignored, expired }

enum WaveType { sent, received, mutual }

class Wave {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String receiverName;
  final String senderLocation;
  final String receiverLocation;
  final String? message;
  final WaveStatus status;
  final WaveType type;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? avatarUrl; // Sender's avatar URL
  final String? receiverAvatarUrl; // Receiver's avatar URL
  final bool isVerified;

  const Wave({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.receiverName,
    required this.senderLocation,
    required this.receiverLocation,
    this.message,
    required this.status,
    required this.type,
    required this.createdAt,
    this.respondedAt,
    this.avatarUrl,
    this.receiverAvatarUrl,
    this.isVerified = false,
  });

  factory Wave.fromMap(Map<String, dynamic> map) {
    return Wave(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverName: map['receiverName'] ?? '',
      senderLocation: map['senderLocation'] ?? '',
      receiverLocation: map['receiverLocation'] ?? '',
      message: map['message'],
      status: WaveStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => WaveStatus.pending,
      ),
      type: WaveType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => WaveType.sent,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      respondedAt: map['respondedAt'] != null
          ? DateTime.parse(map['respondedAt'])
          : null,
      avatarUrl: map['avatarUrl'],
      receiverAvatarUrl: map['receiverAvatarUrl'],
      isVerified: map['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'receiverName': receiverName,
      'senderLocation': senderLocation,
      'receiverLocation': receiverLocation,
      'message': message,
      'status': status.name,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'avatarUrl': avatarUrl,
      'receiverAvatarUrl': receiverAvatarUrl,
      'isVerified': isVerified,
    };
  }

  Wave copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? senderName,
    String? receiverName,
    String? senderLocation,
    String? receiverLocation,
    String? message,
    WaveStatus? status,
    WaveType? type,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? avatarUrl,
    String? receiverAvatarUrl,
    bool? isVerified,
  }) {
    return Wave(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      senderName: senderName ?? this.senderName,
      receiverName: receiverName ?? this.receiverName,
      senderLocation: senderLocation ?? this.senderLocation,
      receiverLocation: receiverLocation ?? this.receiverLocation,
      message: message ?? this.message,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      receiverAvatarUrl: receiverAvatarUrl ?? this.receiverAvatarUrl,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7} weeks ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  bool get canRespond {
    return type == WaveType.received && status == WaveStatus.pending;
  }

  bool get isExpired {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays > 7; // Waves expire after 7 days
  }
}
