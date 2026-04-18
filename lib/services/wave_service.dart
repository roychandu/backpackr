// ignore_for_file: avoid_print

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wave.dart';
import 'notification_service.dart';
import 'dart:math' as math;

class WaveService {
  static final WaveService _instance = WaveService._internal();
  factory WaveService() => _instance;
  WaveService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Database references
  DatabaseReference get _userProfilesRef => _database.ref('userProfiles');

  /// Send a wave to another user
  Future<String> sendWave({
    required String receiverId,
    required String receiverName,
    required String receiverLocation,
    String? message,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (currentUserId == receiverId) {
      throw Exception('Cannot send wave to yourself');
    }

    // Check if wave already exists
    final existingWave = await _findExistingWave(currentUserId!, receiverId);
    if (existingWave != null) {
      throw Exception('Wave already sent to this user');
    }

    // Get sender data
    final senderData = await _getUserData(currentUserId!);
    if (senderData == null) {
      throw Exception('Sender profile not found');
    }

    // Get receiver data for their avatar
    final receiverData = await _getUserData(receiverId);
    final receiverAvatarUrl = receiverData?['avatarUrl'] as String?;

    final waveId = _database.ref().push().key!;
    final now = DateTime.now();

    final wave = Wave(
      id: waveId,
      senderId: currentUserId!,
      receiverId: receiverId,
      senderName: senderData['displayName'] ?? 'Unknown User',
      receiverName: receiverName,
      senderLocation: senderData['currentLocation'] ?? '',
      receiverLocation: receiverLocation,
      message: message,
      status: WaveStatus.pending,
      type: WaveType.sent,
      createdAt: now,
      avatarUrl: senderData['avatarUrl'],
      receiverAvatarUrl: receiverAvatarUrl,
      isVerified: _isUserVerified(senderData),
    );

    // Save wave under sender's profile (current user)
    final senderWavesRef = _userProfilesRef
        .child(currentUserId!)
        .child('waves')
        .child(waveId);

    await senderWavesRef.set(wave.toMap());

    // Try to save wave under receiver's profile (may fail due to permissions)
    try {
      final receiverWavesRef = _userProfilesRef
          .child(receiverId)
          .child('waves')
          .child(waveId);
      await receiverWavesRef.set(wave.toMap());
    } catch (e) {
      print('Could not save wave to receiver profile: $e');
    }

    // Update wave statistics for both users
    await _updateWaveStatistics(currentUserId!, 'sent');
    await _updateWaveStatistics(receiverId, 'received');

    return waveId;
  }

  /// Accept a received wave
  Future<void> acceptWave(String waveId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Find the wave in current user's received waves
    final waveSnapshot = await _userProfilesRef
        .child(currentUserId!)
        .child('waves')
        .child(waveId)
        .get();

    if (!waveSnapshot.exists) {
      throw Exception('Wave not found');
    }

    final waveData = Map<String, dynamic>.from(
      waveSnapshot.value as Map<dynamic, dynamic>,
    );
    final wave = Wave.fromMap(waveData);

    if (wave.receiverId != currentUserId) {
      throw Exception('Not authorized to accept this wave');
    }

    if (wave.status != WaveStatus.pending) {
      throw Exception('Wave has already been responded to');
    }

    if (wave.isExpired) {
      throw Exception('Wave has expired');
    }

    final now = DateTime.now();

    // Update wave status in receiver's profile (current user only)
    final receiverWavesRef = _userProfilesRef
        .child(currentUserId!)
        .child('waves')
        .child(waveId);

    await receiverWavesRef.update({
      'status': WaveStatus.accepted.name,
      'respondedAt': now.toIso8601String(),
    });

    // Try to update sender's wave status (may fail due to permissions, that's ok)
    try {
      final senderWavesRef = _userProfilesRef
          .child(wave.senderId)
          .child('waves')
          .child(waveId);
      await senderWavesRef.update({
        'status': WaveStatus.accepted.name,
        'respondedAt': now.toIso8601String(),
      });
    } catch (e) {
      print('Could not update sender wave status: $e');
    }

    // Update mutual connection statistics (only for current user)
    await _updateWaveStatistics(currentUserId!, 'mutual');

    // Note: Do not trigger a local notification here as it would notify the receiver themselves.
    // If remote notifications are required, write a server-targeted notification for the sender
    // and let the sender device display it.
  }

  /// Ignore a received wave
  Future<void> ignoreWave(String waveId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final waveSnapshot = await _userProfilesRef
        .child(currentUserId!)
        .child('waves')
        .child(waveId)
        .get();

    if (!waveSnapshot.exists) {
      throw Exception('Wave not found');
    }

    final waveData = Map<String, dynamic>.from(
      waveSnapshot.value as Map<dynamic, dynamic>,
    );
    final wave = Wave.fromMap(waveData);

    if (wave.receiverId != currentUserId) {
      throw Exception('Not authorized to ignore this wave');
    }

    if (wave.status != WaveStatus.pending) {
      throw Exception('Wave has already been responded to');
    }

    final now = DateTime.now();

    // Update wave status in receiver's profile (current user only)
    final receiverWavesRef = _userProfilesRef
        .child(currentUserId!)
        .child('waves')
        .child(waveId);

    await receiverWavesRef.update({
      'status': WaveStatus.ignored.name,
      'respondedAt': now.toIso8601String(),
    });

    // Try to update sender's wave status (may fail due to permissions, that's ok)
    try {
      final senderWavesRef = _userProfilesRef
          .child(wave.senderId)
          .child('waves')
          .child(waveId);
      await senderWavesRef.update({
        'status': WaveStatus.ignored.name,
        'respondedAt': now.toIso8601String(),
      });
    } catch (e) {
      print('Could not update sender wave status: $e');
    }
  }

  /// Get all waves for the current user
  Future<List<Wave>> getUserWaves() async {
    if (currentUserId == null) {
      return [];
    }

    try {
      final snapshot = await _userProfilesRef
          .child(currentUserId!)
          .child('waves')
          .get();

      // Use a Map to track unique waves by ID
      final Map<String, Wave> uniqueWaves = {};

      if (snapshot.exists) {
        for (final child in snapshot.children) {
          try {
            final waveData = Map<String, dynamic>.from(
              child.value as Map<dynamic, dynamic>,
            );
            final wave = Wave.fromMap(waveData);

            // Only add if we haven't seen this wave ID before
            // or if this is a newer version of the wave
            if (!uniqueWaves.containsKey(wave.id) ||
                wave.createdAt.isAfter(uniqueWaves[wave.id]!.createdAt)) {
              uniqueWaves[wave.id] = wave;
            }
          } catch (e) {
            print('Error parsing wave data: $e');
            continue;
          }
        }
      }

      // Convert map values to list
      final List<Wave> waves = uniqueWaves.values.toList();

      // Sort by creation date (newest first)
      waves.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return waves;
    } catch (e) {
      print('Error fetching waves: $e');
      return [];
    }
  }

  /// Get waves grouped by type
  Future<Map<WaveType, List<Wave>>> getWavesByType() async {
    final allWaves = await getUserWaves();

    final Map<WaveType, List<Wave>> wavesByType = {
      WaveType.sent: [],
      WaveType.received: [],
      WaveType.mutual: [],
    };

    // Use Sets to track wave IDs in each category to prevent duplicates
    final Set<String> mutualIds = {};
    final Set<String> sentIds = {};
    final Set<String> receivedIds = {};

    for (final wave in allWaves) {
      // Determine the category based on status and user role
      if (wave.status == WaveStatus.accepted) {
        // Accepted waves go to mutual connections only
        if (!mutualIds.contains(wave.id)) {
          final mutualWave = wave.copyWith(type: WaveType.mutual);
          wavesByType[WaveType.mutual]!.add(mutualWave);
          mutualIds.add(wave.id);
        }
      } else if (wave.senderId == currentUserId && !sentIds.contains(wave.id)) {
        // Waves sent by current user (pending, ignored, or expired)
        wavesByType[WaveType.sent]!.add(wave);
        sentIds.add(wave.id);
      } else if (wave.receiverId == currentUserId &&
          wave.status == WaveStatus.pending &&
          !receivedIds.contains(wave.id)) {
        // Only show pending received waves (not ignored or expired)
        wavesByType[WaveType.received]!.add(wave);
        receivedIds.add(wave.id);
      }
    }

    // Debug logging
    print(
      'Waves loaded - Mutual: ${mutualIds.length}, Sent: ${sentIds.length}, Received: ${receivedIds.length}',
    );

    return wavesByType;
  }

  /// Find existing wave between two users
  Future<String?> _findExistingWave(String senderId, String receiverId) async {
    final snapshot = await _userProfilesRef
        .child(senderId)
        .child('waves')
        .orderByChild('receiverId')
        .equalTo(receiverId)
        .get();

    if (snapshot.exists) {
      for (final child in snapshot.children) {
        final waveData = Map<String, dynamic>.from(
          child.value as Map<dynamic, dynamic>,
        );
        if (waveData['receiverId'] == receiverId &&
            waveData['status'] == 'pending') {
          return child.key;
        }
      }
    }

    return null;
  }

  /// Get user data, preferring userProfiles, with fallback to users/<uid>
  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      // Primary: userProfiles/<uid>
      final profileSnap = await _userProfilesRef.child(userId).get();
      Map<String, dynamic>? profileMap;
      if (profileSnap.exists && profileSnap.value is Map) {
        profileMap = Map<String, dynamic>.from(
          profileSnap.value as Map<dynamic, dynamic>,
        );
      }

      // Fallback: users/<uid>
      Map<String, dynamic>? userMap;
      try {
        final usersSnap = await _database.ref('users').child(userId).get();
        if (usersSnap.exists && usersSnap.value is Map) {
          userMap = Map<String, dynamic>.from(
            usersSnap.value as Map<dynamic, dynamic>,
          );
        }
      } catch (_) {
        // ignore users fallback errors
      }

      if (profileMap == null && userMap == null) return null;

      // Merge: profile values take precedence; fill missing from users
      final merged = <String, dynamic>{};
      if (userMap != null) {
        merged['displayName'] = userMap['name'] ?? userMap['displayName'];
        merged['avatarUrl'] = userMap['photoURL'] ?? userMap['avatarUrl'];
        merged['currentLocation'] = userMap['currentLocation'] ?? '';
        merged['setupCompleted'] = userMap['setupCompleted'] ?? false;
      }
      if (profileMap != null) {
        merged.addAll(profileMap);
        // Normalize common fields
        merged['displayName'] =
            profileMap['displayName'] ??
            profileMap['name'] ??
            merged['displayName'];
        merged['avatarUrl'] = profileMap['avatarUrl'] ?? merged['avatarUrl'];
        merged['currentLocation'] =
            profileMap['currentLocation'] ?? merged['currentLocation'] ?? '';
      }

      return merged;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  /// Check if user is verified
  bool _isUserVerified(Map<String, dynamic> userData) {
    return userData['setupCompleted'] == true &&
        userData['avatarUrl'] != null &&
        (userData['avatarUrl'] as String).isNotEmpty;
  }

  /// Update wave statistics for a user
  Future<void> _updateWaveStatistics(String userId, String type) async {
    try {
      final userRef = _userProfilesRef.child(userId);
      final userSnapshot = await userRef.get();

      if (!userSnapshot.exists) return;

      final userData = Map<String, dynamic>.from(
        userSnapshot.value as Map<dynamic, dynamic>,
      );

      int wavesSent = userData['wavesSent'] ?? 0;
      int wavesReceived = userData['wavesReceived'] ?? 0;
      int mutualConnections = userData['mutualConnections'] ?? 0;

      switch (type) {
        case 'sent':
          wavesSent++;
          break;
        case 'received':
          wavesReceived++;
          break;
        case 'mutual':
          mutualConnections++;
          break;
      }

      await userRef.update({
        'wavesSent': wavesSent,
        'wavesReceived': wavesReceived,
        'mutualConnections': mutualConnections,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error updating wave statistics: $e');
    }
  }

  /// Delete a sent wave (if it hasn't been responded to)
  Future<void> deleteWave(String waveId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final waveRef = _userProfilesRef
        .child(currentUserId!)
        .child('waves')
        .child(waveId);
    final snapshot = await waveRef.get();

    if (!snapshot.exists) {
      throw Exception('Wave not found');
    }

    final waveData = Map<String, dynamic>.from(
      snapshot.value as Map<dynamic, dynamic>,
    );
    final wave = Wave.fromMap(waveData);

    if (wave.senderId != currentUserId) {
      throw Exception('Not authorized to delete this wave');
    }

    if (wave.status != WaveStatus.pending) {
      throw Exception('Cannot delete wave that has been responded to');
    }

    // Delete from sender's profile (current user)
    final senderWavesRef = _userProfilesRef
        .child(wave.senderId)
        .child('waves')
        .child(waveId);

    await senderWavesRef.remove();

    // Try to delete from receiver's profile (may fail due to permissions)
    try {
      final receiverWavesRef = _userProfilesRef
          .child(wave.receiverId)
          .child('waves')
          .child(waveId);
      await receiverWavesRef.remove();
    } catch (e) {
      print('Could not delete wave from receiver profile: $e');
    }

    // Decrement wave statistics (only for current user)
    await _decrementWaveStatistics(currentUserId!, 'sent');
  }

  /// Decrement wave statistics
  Future<void> _decrementWaveStatistics(String userId, String type) async {
    try {
      final userRef = _userProfilesRef.child(userId);
      final userSnapshot = await userRef.get();

      if (!userSnapshot.exists) return;

      final userData = Map<String, dynamic>.from(
        userSnapshot.value as Map<dynamic, dynamic>,
      );

      int wavesSent = userData['wavesSent'] ?? 0;
      int wavesReceived = userData['wavesReceived'] ?? 0;
      int mutualConnections = userData['mutualConnections'] ?? 0;

      switch (type) {
        case 'sent':
          wavesSent = math.max(0, wavesSent - 1);
          break;
        case 'received':
          wavesReceived = math.max(0, wavesReceived - 1);
          break;
        case 'mutual':
          mutualConnections = math.max(0, mutualConnections - 1);
          break;
      }

      await userRef.update({
        'wavesSent': wavesSent,
        'wavesReceived': wavesReceived,
        'mutualConnections': mutualConnections,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error decrementing wave statistics: $e');
    }
  }

  /// Get wave stream for real-time updates
  Stream<List<Wave>> getWavesStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _userProfilesRef.child(currentUserId!).child('waves').onValue.map((
      event,
    ) {
      if (event.snapshot.value == null) {
        return <Wave>[];
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final List<Wave> waves = [];

      for (final entry in data.entries) {
        final waveData = Map<String, dynamic>.from(
          entry.value as Map<dynamic, dynamic>,
        );
        final wave = Wave.fromMap(waveData);
        waves.add(wave);
      }

      // Sort by creation date (newest first)
      waves.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return waves;
    });
  }

  /// Get user wave statistics
  Future<Map<String, int>> getUserWaveStatistics(String userId) async {
    try {
      final snapshot = await _userProfilesRef.child(userId).get();
      if (!snapshot.exists) {
        return {'wavesSent': 0, 'wavesReceived': 0, 'mutualConnections': 0};
      }

      final userData = Map<String, dynamic>.from(
        snapshot.value as Map<dynamic, dynamic>,
      );

      return {
        'wavesSent': userData['wavesSent'] ?? 0,
        'wavesReceived': userData['wavesReceived'] ?? 0,
        'mutualConnections': userData['mutualConnections'] ?? 0,
      };
    } catch (e) {
      print('Error fetching wave statistics: $e');
      return {'wavesSent': 0, 'wavesReceived': 0, 'mutualConnections': 0};
    }
  }

  /// Get count of pending received waves (for badge display)
  Stream<int> getPendingReceivedWavesCount() {
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _userProfilesRef.child(currentUserId!).child('waves').onValue.map((
      event,
    ) {
      if (event.snapshot.value == null) return 0;

      try {
        final Map<dynamic, dynamic> wavesData =
            event.snapshot.value as Map<dynamic, dynamic>;
        int count = 0;

        for (final entry in wavesData.entries) {
          try {
            final waveData = Map<String, dynamic>.from(
              entry.value as Map<dynamic, dynamic>,
            );
            final wave = Wave.fromMap(waveData);

            // Count only pending waves received by current user
            if (wave.receiverId == currentUserId &&
                wave.status == WaveStatus.pending) {
              count++;
            }
          } catch (e) {
            print('Error parsing wave for count: $e');
          }
        }

        return count;
      } catch (e) {
        print('Error counting pending waves: $e');
        return 0;
      }
    });
  }
}
