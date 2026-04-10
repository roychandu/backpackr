enum MeetupCategory { work, culture, adventure, food, nightlife, sports, other }

class Meetup {
  final String id;
  final String hostId;
  final String hostName;
  final String? hostAvatarUrl;
  final String title;
  final String description;
  final MeetupCategory category;
  final DateTime dateTime;
  final String location; // Event location (text: e.g., "Le Marais, Paris")
  final double? latitude; // Organizer's latitude (not event location)
  final double? longitude; // Organizer's longitude (not event location)
  final int maxCapacity;
  final List<String> attendeeIds;
  final List<String> pendingRequests; // Users who requested to join
  final DateTime createdAt;
  final bool isActive;

  const Meetup({
    required this.id,
    required this.hostId,
    required this.hostName,
    this.hostAvatarUrl,
    required this.title,
    required this.description,
    required this.category,
    required this.dateTime,
    required this.location,
    this.latitude,
    this.longitude,
    required this.maxCapacity,
    required this.attendeeIds,
    this.pendingRequests = const [],
    required this.createdAt,
    this.isActive = true,
  });

  factory Meetup.fromMap(Map<String, dynamic> map) {
    return Meetup(
      id: map['id'] ?? '',
      hostId: map['hostId'] ?? '',
      hostName: map['hostName'] ?? '',
      hostAvatarUrl: map['hostAvatarUrl'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: MeetupCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => MeetupCategory.other,
      ),
      dateTime: DateTime.parse(map['dateTime']),
      location: map['location'] ?? '',
      latitude: map['latitude'] != null
          ? double.tryParse(map['latitude'].toString()) ?? 0.0
          : null,
      longitude: map['longitude'] != null
          ? double.tryParse(map['longitude'].toString()) ?? 0.0
          : null,
      maxCapacity: map['maxCapacity'] ?? 10,
      attendeeIds: map['attendeeIds'] != null
          ? List<String>.from(map['attendeeIds'])
          : [],
      pendingRequests: map['pendingRequests'] != null
          ? List<String>.from(map['pendingRequests'])
          : [],
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    print('DEBUG Meetup.toMap - latitude: $latitude, longitude: $longitude');
    final map = {
      'id': id,
      'hostId': hostId,
      'hostName': hostName,
      'hostAvatarUrl': hostAvatarUrl,
      'title': title,
      'description': description,
      'category': category.name,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'maxCapacity': maxCapacity,
      'attendeeIds': attendeeIds,
      'pendingRequests': pendingRequests,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
    print(
      'DEBUG Meetup.toMap - map contains latitude: ${map.containsKey('latitude')}, longitude: ${map.containsKey('longitude')}',
    );
    return map;
  }

  Meetup copyWith({
    String? id,
    String? hostId,
    String? hostName,
    String? hostAvatarUrl,
    String? title,
    String? description,
    MeetupCategory? category,
    DateTime? dateTime,
    String? location,
    double? latitude,
    double? longitude,
    int? maxCapacity,
    List<String>? attendeeIds,
    List<String>? pendingRequests,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Meetup(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostAvatarUrl: hostAvatarUrl ?? this.hostAvatarUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper getters
  int get currentAttendees => attendeeIds.length;
  bool get isFull => currentAttendees >= maxCapacity;
  bool get isPast => dateTime.isBefore(DateTime.now());

  String get categoryDisplayName {
    switch (category) {
      case MeetupCategory.work:
        return 'Work';
      case MeetupCategory.culture:
        return 'Culture';
      case MeetupCategory.adventure:
        return 'Adventure';
      case MeetupCategory.food:
        return 'Food';
      case MeetupCategory.nightlife:
        return 'Nightlife';
      case MeetupCategory.sports:
        return 'Sports';
      case MeetupCategory.other:
        return 'Other';
    }
  }

  String get formattedDateTime {
    final weekday = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][dateTime.weekday - 1];
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][dateTime.month - 1];
    final day = dateTime.day;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$weekday, $month $day at $hour:$minute';
  }

  String get capacityDisplay => '$currentAttendees/$maxCapacity';
}
