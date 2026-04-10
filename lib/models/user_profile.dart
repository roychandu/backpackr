class Destination {
  final String city;
  final String date; // MM/YYYY or free-text

  const Destination({required this.city, required this.date});

  factory Destination.fromMap(Map<dynamic, dynamic> map) {
    return Destination(
      city: (map['city'] as String?)?.trim() ?? '',
      date: (map['date'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'city': city, 'date': date};
}

class UserProfile {
  final String displayName;
  final String bio;
  final String currentLocation;
  final double? latitude;
  final double? longitude;
  final String? avatarUrl;
  final List<String> tags;
  final List<Destination> destinations;
  final bool setupCompleted;
  final int lastUpdated;

  // Wave statistics
  final int wavesSent;
  final int wavesReceived;
  final int mutualConnections;

  const UserProfile({
    required this.displayName,
    required this.bio,
    required this.currentLocation,
    required this.latitude,
    required this.longitude,
    required this.avatarUrl,
    required this.tags,
    required this.destinations,
    required this.setupCompleted,
    required this.lastUpdated,
    this.wavesSent = 0,
    this.wavesReceived = 0,
    this.mutualConnections = 0,
  });

  UserProfile copyWith({
    String? displayName,
    String? bio,
    String? currentLocation,
    double? latitude,
    double? longitude,
    String? avatarUrl,
    List<String>? tags,
    List<Destination>? destinations,
    bool? setupCompleted,
    int? lastUpdated,
    int? wavesSent,
    int? wavesReceived,
    int? mutualConnections,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      currentLocation: currentLocation ?? this.currentLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      tags: tags ?? this.tags,
      destinations: destinations ?? this.destinations,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      wavesSent: wavesSent ?? this.wavesSent,
      wavesReceived: wavesReceived ?? this.wavesReceived,
      mutualConnections: mutualConnections ?? this.mutualConnections,
    );
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      displayName: (map['displayName'] as String?)?.trim() ?? '',
      bio: (map['bio'] as String?)?.trim() ?? '',
      currentLocation: (map['currentLocation'] as String?)?.trim() ?? '',
      latitude: map['latitude'] != null
          ? double.tryParse(map['latitude'].toString())
          : null,
      longitude: map['longitude'] != null
          ? double.tryParse(map['longitude'].toString())
          : null,
      avatarUrl: (map['avatarUrl'] as String?),
      tags: (map['tags'] is List)
          ? List<String>.from((map['tags'] as List).whereType<String>())
          : const <String>[],
      destinations: (map['destinations'] is List)
          ? List<Destination>.from(
              (map['destinations'] as List).whereType<Map>().map(
                (m) => Destination.fromMap(m),
              ),
            )
          : const <Destination>[],
      setupCompleted: map['setupCompleted'] == true,
      lastUpdated: (map['lastUpdated'] is num)
          ? (map['lastUpdated'] as num).toInt()
          : DateTime.now().millisecondsSinceEpoch,
      wavesSent: (map['wavesSent'] is num)
          ? (map['wavesSent'] as num).toInt()
          : 0,
      wavesReceived: (map['wavesReceived'] is num)
          ? (map['wavesReceived'] as num).toInt()
          : 0,
      mutualConnections: (map['mutualConnections'] is num)
          ? (map['mutualConnections'] as num).toInt()
          : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'bio': bio,
      'currentLocation': currentLocation,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'avatarUrl': avatarUrl,
      'tags': tags,
      'destinations': destinations.map((d) => d.toMap()).toList(),
      'setupCompleted': setupCompleted,
      'lastUpdated': lastUpdated,
      'wavesSent': wavesSent,
      'wavesReceived': wavesReceived,
      'mutualConnections': mutualConnections,
    };
  }
}
