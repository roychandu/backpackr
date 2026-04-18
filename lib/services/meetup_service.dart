// ignore_for_file: deprecated_member_use, avoid_print, empty_catches

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/meetup.dart';

class MeetupService {
  static final MeetupService _instance = MeetupService._internal();
  factory MeetupService() => _instance;
  MeetupService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Database references
  DatabaseReference get _meetupsRef => _database.ref('meetups');
  DatabaseReference get _userProfilesRef => _database.ref('userProfiles');

  /// Create a new meetup
  /// Organizer's location (latitude/longitude) is automatically fetched from their profile
  Future<String> createMeetup({
    required String title,
    required String description,
    required MeetupCategory category,
    required DateTime dateTime,
    required String location,
    required int maxCapacity,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Get host data (with fallback to FirebaseAuth)
    final hostData = await _getUserData(currentUserId!);
    if (hostData == null) {
      throw Exception(
        'User data could not be retrieved. Please ensure you are logged in.',
      );
    }

    // Always fetch organizer's location from their profile
    // Note: latitude/longitude in meetup represent ORGANIZER's location, not event location
    double? organizerLatitude;
    double? organizerLongitude;

    // Get organizer's location from their profile
    final orgLat = hostData['latitude'];
    final orgLng = hostData['longitude'];

    if (orgLat != null && orgLng != null) {
      organizerLatitude = double.tryParse(orgLat.toString());
      organizerLongitude = double.tryParse(orgLng.toString());
    } else {
      // If profile doesn't have location, fetch it now
      try {
        final position = await _getCurrentPosition();
        if (position != null) {
          organizerLatitude = position.latitude;
          organizerLongitude = position.longitude;

          // Also update/create the user profile with this location for future use
          try {
            final profileRef = _userProfilesRef.child(currentUserId!);
            final profileSnapshot = await profileRef.get();

            if (profileSnapshot.exists) {
              // Profile exists, update it
              await profileRef.update({
                'latitude': organizerLatitude,
                'longitude': organizerLongitude,
              });
            } else {
              // Profile doesn't exist, create minimal one with location
              final user = _auth.currentUser;
              await profileRef.set({
                'displayName':
                    user?.displayName ??
                    user?.email?.split('@').first ??
                    'User',
                'avatarUrl': user?.photoURL,
                'latitude': organizerLatitude,
                'longitude': organizerLongitude,
              });
            }
          } catch (e) {
            // Log but don't fail meetup creation if profile update fails
            print('Warning: Could not update user profile with location: $e');
          }
        } else {}
      } catch (e) {}
    }

    final meetupId = _meetupsRef.push().key!;
    final now = DateTime.now();

    final meetup = Meetup(
      id: meetupId,
      hostId: currentUserId!,
      hostName: hostData['displayName'] ?? 'Unknown User',
      hostAvatarUrl: hostData['avatarUrl'],
      title: title,
      description: description,
      category: category,
      dateTime: dateTime,
      location: location,
      latitude: organizerLatitude, // Organizer's location, not event location
      longitude: organizerLongitude, // Organizer's location, not event location
      maxCapacity: maxCapacity,
      attendeeIds: [currentUserId!], // Host is automatically an attendee
      pendingRequests: [], // Initialize empty pending requests list
      createdAt: now,
      isActive: true,
    );

    // Debug: Print what's being saved
    final meetupMap = meetup.toMap();

    // Save meetup to Firebase
    await _meetupsRef.child(meetupId).set(meetupMap);

    // Add to user's hosted meetups
    await _userProfilesRef
        .child(currentUserId!)
        .child('hostedMeetups')
        .child(meetupId)
        .set(true);

    return meetupId;
  }

  /// Get all active meetups
  Future<List<Meetup>> getAllMeetups() async {
    try {
      final snapshot = await _meetupsRef
          .orderByChild('isActive')
          .equalTo(true)
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final List<Meetup> meetups = [];
      for (final child in snapshot.children) {
        try {
          final meetupData = Map<String, dynamic>.from(
            child.value as Map<dynamic, dynamic>,
          );
          final meetup = Meetup.fromMap(meetupData);

          // Only show future meetups (temporarily disabled for testing)
          // if (!meetup.isPast) {
          meetups.add(meetup);
          // }
        } catch (e) {
          continue;
        }
      }

      // Sort by date (nearest first)
      meetups.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      return meetups;
    } catch (e) {
      return [];
    }
  }

  /// Get meetups by location/city
  Future<List<Meetup>> getMeetupsByLocation(String location) async {
    try {
      final allMeetups = await getAllMeetups();
      return allMeetups
          .where(
            (meetup) =>
                meetup.location.toLowerCase().contains(location.toLowerCase()),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get meetups the user is attending
  Future<List<Meetup>> getUserAttendingMeetups() async {
    if (currentUserId == null) {
      return [];
    }

    try {
      final allMeetups = await getAllMeetups();
      return allMeetups
          .where((meetup) => meetup.attendeeIds.contains(currentUserId))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get meetups hosted by the user
  Future<List<Meetup>> getUserHostedMeetups() async {
    if (currentUserId == null) {
      return [];
    }

    try {
      final allMeetups = await getAllMeetups();
      return allMeetups
          .where((meetup) => meetup.hostId == currentUserId)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Request to join a meetup
  Future<void> requestToJoinMeetup(String meetupId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final meetupRef = _meetupsRef.child(meetupId);
    final snapshot = await meetupRef.get();

    if (!snapshot.exists) {
      throw Exception('Meetup not found');
    }

    final meetupData = Map<String, dynamic>.from(
      snapshot.value as Map<dynamic, dynamic>,
    );
    final meetup = Meetup.fromMap(meetupData);

    if (meetup.attendeeIds.contains(currentUserId)) {
      throw Exception('Already joined this meetup');
    }

    if (meetup.pendingRequests.contains(currentUserId)) {
      throw Exception('Request already sent');
    }

    if (meetup.isFull) {
      throw Exception('Meetup is full');
    }

    if (meetup.isPast) {
      throw Exception('Cannot join past meetup');
    }

    // Add user to pending requests
    final updatedPendingRequests = [...meetup.pendingRequests, currentUserId!];

    await meetupRef.child('pendingRequests').set(updatedPendingRequests);

    // Get current user's data for notification
    final userData = await _getUserData(currentUserId!);
    final userName = userData?['displayName'] ?? 'Someone';

    // Create notification for host that someone requested to join
    await _userProfilesRef
        .child(meetup.hostId)
        .child('meetupNotifications')
        .push()
        .set({
          'type': 'new_request',
          'meetupId': meetupId,
          'meetupTitle': meetup.title,
          'requesterName': userName,
          'requesterId': currentUserId,
          'timestamp': DateTime.now().toIso8601String(),
          'read': false,
        });
  }

  /// Approve a join request (only host can do this)
  Future<void> approveJoinRequest(String meetupId, String userId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final meetupRef = _meetupsRef.child(meetupId);
    final snapshot = await meetupRef.get();

    if (!snapshot.exists) {
      throw Exception('Meetup not found');
    }

    final meetupData = Map<String, dynamic>.from(
      snapshot.value as Map<dynamic, dynamic>,
    );
    final meetup = Meetup.fromMap(meetupData);

    if (meetup.hostId != currentUserId) {
      throw Exception('Only the host can approve requests');
    }

    if (!meetup.pendingRequests.contains(userId)) {
      throw Exception('No pending request from this user');
    }

    if (meetup.isFull) {
      throw Exception('Meetup is full');
    }

    // Remove from pending requests
    final updatedPendingRequests = meetup.pendingRequests
        .where((id) => id != userId)
        .toList();

    // Add to attendees
    final updatedAttendees = [...meetup.attendeeIds, userId];

    try {
      // Update both lists using a single update call
      await meetupRef.update({
        'pendingRequests': updatedPendingRequests,
        'attendeeIds': updatedAttendees,
      });

      // Add to user's attending meetups
      await _userProfilesRef
          .child(userId)
          .child('attendingMeetups')
          .child(meetupId)
          .set(true);

      // Create notification for user that their request was approved
      await _userProfilesRef
          .child(userId)
          .child('meetupNotifications')
          .push()
          .set({
            'type': 'approved',
            'meetupId': meetupId,
            'meetupTitle': meetup.title,
            'timestamp': DateTime.now().toIso8601String(),
            'read': false,
          });

      // Clear the "new_request" notification for host
      await _clearHostRequestNotification(meetup.hostId, meetupId, userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Reject a join request (only host can do this)
  Future<void> rejectJoinRequest(String meetupId, String userId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final meetupRef = _meetupsRef.child(meetupId);
    final snapshot = await meetupRef.get();

    if (!snapshot.exists) {
      throw Exception('Meetup not found');
    }

    final meetupData = Map<String, dynamic>.from(
      snapshot.value as Map<dynamic, dynamic>,
    );
    final meetup = Meetup.fromMap(meetupData);

    if (meetup.hostId != currentUserId) {
      throw Exception('Only the host can reject requests');
    }

    if (!meetup.pendingRequests.contains(userId)) {
      throw Exception('No pending request from this user');
    }

    // Remove from pending requests
    final updatedPendingRequests = meetup.pendingRequests
        .where((id) => id != userId)
        .toList();

    try {
      await meetupRef.update({'pendingRequests': updatedPendingRequests});

      // Create notification for user that their request was rejected
      await _userProfilesRef
          .child(userId)
          .child('meetupNotifications')
          .push()
          .set({
            'type': 'rejected',
            'meetupId': meetupId,
            'meetupTitle': meetup.title,
            'timestamp': DateTime.now().toIso8601String(),
            'read': false,
          });

      // Clear the "new_request" notification for host
      await _clearHostRequestNotification(meetup.hostId, meetupId, userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel a join request (user cancels their own request)
  Future<void> cancelJoinRequest(String meetupId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final meetupRef = _meetupsRef.child(meetupId);
    final snapshot = await meetupRef.get();

    if (!snapshot.exists) {
      throw Exception('Meetup not found');
    }

    final meetupData = Map<String, dynamic>.from(
      snapshot.value as Map<dynamic, dynamic>,
    );
    final meetup = Meetup.fromMap(meetupData);

    if (!meetup.pendingRequests.contains(currentUserId)) {
      throw Exception('No pending request found');
    }

    // Remove from pending requests
    final updatedPendingRequests = meetup.pendingRequests
        .where((id) => id != currentUserId)
        .toList();

    await meetupRef.child('pendingRequests').set(updatedPendingRequests);

    // Get current user's data for notification
    final userData = await _getUserData(currentUserId!);
    final userName = userData?['displayName'] ?? 'Someone';

    // Create notification for host that user cancelled
    await _userProfilesRef
        .child(meetup.hostId)
        .child('meetupNotifications')
        .push()
        .set({
          'type': 'request_cancelled',
          'meetupId': meetupId,
          'meetupTitle': meetup.title,
          'requesterName': userName,
          'requesterId': currentUserId,
          'timestamp': DateTime.now().toIso8601String(),
          'read': false,
        });

    // Also clear the original "new_request" notification
    await _clearHostRequestNotification(
      meetup.hostId,
      meetupId,
      currentUserId!,
    );
  }

  /// Leave a meetup
  Future<void> leaveMeetup(String meetupId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final meetupRef = _meetupsRef.child(meetupId);
    final snapshot = await meetupRef.get();

    if (!snapshot.exists) {
      throw Exception('Meetup not found');
    }

    final meetupData = Map<String, dynamic>.from(
      snapshot.value as Map<dynamic, dynamic>,
    );
    final meetup = Meetup.fromMap(meetupData);

    if (meetup.hostId == currentUserId) {
      throw Exception('Host cannot leave their own meetup. Cancel it instead.');
    }

    if (!meetup.attendeeIds.contains(currentUserId)) {
      throw Exception('Not attending this meetup');
    }

    // Remove user from attendees
    final updatedAttendees = meetup.attendeeIds
        .where((id) => id != currentUserId)
        .toList();
    await meetupRef.child('attendeeIds').set(updatedAttendees);

    // Remove from user's attending meetups
    await _userProfilesRef
        .child(currentUserId!)
        .child('attendingMeetups')
        .child(meetupId)
        .remove();

    // Get current user's data for notification
    final userData = await _getUserData(currentUserId!);
    final userName = userData?['displayName'] ?? 'Someone';

    // Create notification for host that someone left
    await _userProfilesRef
        .child(meetup.hostId)
        .child('meetupNotifications')
        .push()
        .set({
          'type': 'attendee_left',
          'meetupId': meetupId,
          'meetupTitle': meetup.title,
          'attendeeName': userName,
          'attendeeId': currentUserId,
          'timestamp': DateTime.now().toIso8601String(),
          'read': false,
        });
  }

  /// Remove an attendee from meetup (only host can do this)
  Future<void> removeAttendee(String meetupId, String userId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final meetupRef = _meetupsRef.child(meetupId);
    final snapshot = await meetupRef.get();

    if (!snapshot.exists) {
      throw Exception('Meetup not found');
    }

    final meetupData = Map<String, dynamic>.from(
      snapshot.value as Map<dynamic, dynamic>,
    );
    final meetup = Meetup.fromMap(meetupData);

    if (meetup.hostId != currentUserId) {
      throw Exception('Only the host can remove attendees');
    }

    if (userId == currentUserId) {
      throw Exception('Host cannot remove themselves');
    }

    if (!meetup.attendeeIds.contains(userId)) {
      throw Exception('User is not attending this meetup');
    }

    // Remove user from attendees
    final updatedAttendees = meetup.attendeeIds
        .where((id) => id != userId)
        .toList();

    try {
      await meetupRef.update({'attendeeIds': updatedAttendees});

      // Remove from user's attending meetups
      await _userProfilesRef
          .child(userId)
          .child('attendingMeetups')
          .child(meetupId)
          .remove();

      // Create notification for user that they were removed
      await _userProfilesRef
          .child(userId)
          .child('meetupNotifications')
          .push()
          .set({
            'type': 'removed',
            'meetupId': meetupId,
            'meetupTitle': meetup.title,
            'timestamp': DateTime.now().toIso8601String(),
            'read': false,
          });
    } catch (e) {
      print('Error in removeAttendee: $e');
      rethrow;
    }
  }

  /// Cancel/delete a meetup (only host can do this)
  Future<void> cancelMeetup(String meetupId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final meetupRef = _meetupsRef.child(meetupId);
    final snapshot = await meetupRef.get();

    if (!snapshot.exists) {
      throw Exception('Meetup not found');
    }

    final meetupData = Map<String, dynamic>.from(
      snapshot.value as Map<dynamic, dynamic>,
    );
    final meetup = Meetup.fromMap(meetupData);

    if (meetup.hostId != currentUserId) {
      throw Exception('Only the host can cancel this meetup');
    }

    // Mark as inactive instead of deleting
    await meetupRef.update({'isActive': false});

    // Remove from host's hosted meetups
    await _userProfilesRef
        .child(currentUserId!)
        .child('hostedMeetups')
        .child(meetupId)
        .remove();

    // Remove from all attendees' attending meetups
    for (final attendeeId in meetup.attendeeIds) {
      if (attendeeId != currentUserId) {
        await _userProfilesRef
            .child(attendeeId)
            .child('attendingMeetups')
            .child(meetupId)
            .remove();
      }
    }
  }

  /// Get a single meetup by ID
  Future<Meetup?> getMeetupById(String meetupId) async {
    try {
      final snapshot = await _meetupsRef.child(meetupId).get();
      if (!snapshot.exists) {
        return null;
      }

      final meetupData = Map<String, dynamic>.from(
        snapshot.value as Map<dynamic, dynamic>,
      );
      return Meetup.fromMap(meetupData);
    } catch (e) {
      print('Error fetching meetup: $e');
      return null;
    }
  }

  /// Get meetups stream for real-time updates
  Stream<List<Meetup>> getMeetupsStream() {
    return _meetupsRef.orderByChild('isActive').equalTo(true).onValue.map((
      event,
    ) {
      if (event.snapshot.value == null) {
        return <Meetup>[];
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final List<Meetup> meetups = [];

      for (final entry in data.entries) {
        try {
          final meetupData = Map<String, dynamic>.from(
            entry.value as Map<dynamic, dynamic>,
          );
          final meetup = Meetup.fromMap(meetupData);

          // Only show future meetups
          if (!meetup.isPast) {
            meetups.add(meetup);
          }
        } catch (e) {
          print('Error parsing meetup in stream: $e');
          continue;
        }
      }

      // Sort by date (nearest first)
      meetups.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      return meetups;
    });
  }

  /// Get count of meetup notifications
  /// Returns: pending requests to approve (for hosts) + unread notifications (for users)
  Stream<int> getPendingRequestsCount() async* {
    if (currentUserId == null) {
      yield 0;
      return;
    }

    await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
      try {
        int count = 0;

        // Count pending requests for meetups you host
        final hostedMeetupsSnapshot = await _meetupsRef
            .orderByChild('hostId')
            .equalTo(currentUserId)
            .get();

        if (hostedMeetupsSnapshot.exists) {
          final data = hostedMeetupsSnapshot.value as Map<dynamic, dynamic>;
          for (final entry in data.values) {
            try {
              final meetupData = Map<String, dynamic>.from(
                entry as Map<dynamic, dynamic>,
              );
              final meetup = Meetup.fromMap(meetupData);

              if (meetup.isActive && !meetup.isPast) {
                count += meetup.pendingRequests.length;
              }
            } catch (e) {
              continue;
            }
          }
        }

        // Count unread meetup notifications for current user
        final notificationsSnapshot = await _userProfilesRef
            .child(currentUserId!)
            .child('meetupNotifications')
            .orderByChild('read')
            .equalTo(false)
            .get();

        if (notificationsSnapshot.exists) {
          final notifData =
              notificationsSnapshot.value as Map<dynamic, dynamic>;
          count += notifData.length;
        }

        yield count;
      } catch (e) {
        print('Error in getPendingRequestsCount: $e');
        yield 0;
      }
    }
  }

  /// Get meetup notifications stream for real-time updates
  Stream<List<Map<String, dynamic>>> getMeetupNotificationsStream() {
    if (currentUserId == null) {
      print('getMeetupNotificationsStream: No current user');
      return Stream.value([]);
    }

    print('Setting up notifications stream for user: $currentUserId');

    return _userProfilesRef
        .child(currentUserId!)
        .child('meetupNotifications')
        .onValue
        .map((event) {
          print('Notifications stream event received');

          if (event.snapshot.value == null) {
            print('No notifications data in snapshot');
            return <Map<String, dynamic>>[];
          }

          try {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            print('Raw notifications data: ${data.length} items');
            final List<Map<String, dynamic>> notifications = [];

            for (final entry in data.entries) {
              try {
                final notifData = Map<String, dynamic>.from(
                  entry.value as Map<dynamic, dynamic>,
                );
                notifData['id'] = entry.key.toString();

                print(
                  'Notification: type=${notifData['type']}, read=${notifData['read']}',
                );

                // Only include unread notifications
                if (notifData['read'] == false) {
                  notifications.add(notifData);
                }
              } catch (e) {
                print('Error parsing notification: $e');
                continue;
              }
            }

            print('Returning ${notifications.length} unread notifications');

            // Sort by timestamp (newest first)
            notifications.sort((a, b) {
              final aTime = DateTime.parse(a['timestamp'] as String);
              final bTime = DateTime.parse(b['timestamp'] as String);
              return bTime.compareTo(aTime);
            });

            return notifications;
          } catch (e) {
            print('Error in notifications stream: $e');
            return <Map<String, dynamic>>[];
          }
        });
  }

  /// Get all meetup notifications for current user (including read ones)
  Future<List<Map<String, dynamic>>> getMeetupNotifications() async {
    if (currentUserId == null) {
      return [];
    }

    try {
      final snapshot = await _userProfilesRef
          .child(currentUserId!)
          .child('meetupNotifications')
          .orderByChild('timestamp')
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> notifications = [];

      for (final entry in data.entries) {
        try {
          final notifData = Map<String, dynamic>.from(
            entry.value as Map<dynamic, dynamic>,
          );
          notifData['id'] = entry.key.toString();
          notifications.add(notifData);
        } catch (e) {
          print('Error parsing notification: $e');
          continue;
        }
      }

      // Sort by timestamp (newest first)
      notifications.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });

      return notifications;
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Clear all meetup notifications for current user
  Future<void> clearMeetupNotifications() async {
    if (currentUserId == null) return;

    try {
      final notificationsRef = _userProfilesRef
          .child(currentUserId!)
          .child('meetupNotifications');

      final snapshot = await notificationsRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        for (final key in data.keys) {
          await notificationsRef.child(key.toString()).update({'read': true});
        }
        print('Cleared all meetup notifications');
      }
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  /// Delete a specific notification
  Future<void> deleteNotification(String notificationId) async {
    if (currentUserId == null) return;

    try {
      await _userProfilesRef
          .child(currentUserId!)
          .child('meetupNotifications')
          .child(notificationId)
          .remove();
      print('Deleted notification: $notificationId');
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Mark a specific notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    if (currentUserId == null) return;

    try {
      await _userProfilesRef
          .child(currentUserId!)
          .child('meetupNotifications')
          .child(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Clear/mark as read the "new_request" notification for a specific user
  Future<void> _clearHostRequestNotification(
    String hostId,
    String meetupId,
    String requesterId,
  ) async {
    try {
      final snapshot = await _userProfilesRef
          .child(hostId)
          .child('meetupNotifications')
          .get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        for (final entry in data.entries) {
          final notifData = Map<String, dynamic>.from(
            entry.value as Map<dynamic, dynamic>,
          );

          // Find the notification for this specific request
          if (notifData['type'] == 'new_request' &&
              notifData['meetupId'] == meetupId &&
              notifData['requesterId'] == requesterId) {
            // Mark as read instead of deleting
            await _userProfilesRef
                .child(hostId)
                .child('meetupNotifications')
                .child(entry.key.toString())
                .update({'read': true});
            print('Cleared new_request notification for host');
            break;
          }
        }
      }
    } catch (e) {
      print('Error clearing host request notification: $e');
    }
  }

  /// Get current GPS position
  Future<Position?> _getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      return position;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Get user data from userProfiles, with fallback to FirebaseAuth
  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      print('DEBUG - Fetching user data for userId: $userId');
      final snapshot = await _userProfilesRef.child(userId).get();
      print('DEBUG - Snapshot exists: ${snapshot.exists}');

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(
          snapshot.value as Map<dynamic, dynamic>,
        );
        print('DEBUG - User data fetched: ${data.keys.toList()}');
        print(
          'DEBUG - Has latitude: ${data.containsKey('latitude')}, value: ${data['latitude']}',
        );
        print(
          'DEBUG - Has longitude: ${data.containsKey('longitude')}, value: ${data['longitude']}',
        );
        return data;
      } else {
        print(
          'DEBUG - User profile snapshot does not exist for userId: $userId, using FirebaseAuth fallback',
        );

        // Fallback to FirebaseAuth user data
        final user = _auth.currentUser;
        if (user != null && user.uid == userId) {
          // Return minimal profile data from FirebaseAuth
          final fallbackData = <String, dynamic>{
            'displayName':
                user.displayName ??
                user.email?.split('@').first ??
                'Guest User',
            'avatarUrl': user.photoURL,
            'latitude': null,
            'longitude': null,
          };
          print('DEBUG - Using fallback data from FirebaseAuth: $fallbackData');
          return fallbackData;
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      // Try FirebaseAuth fallback even on error
      try {
        final user = _auth.currentUser;
        if (user != null && user.uid == userId) {
          return <String, dynamic>{
            'displayName':
                user.displayName ??
                user.email?.split('@').first ??
                'Guest User',
            'avatarUrl': user.photoURL,
            'latitude': null,
            'longitude': null,
          };
        }
      } catch (e2) {
        print('Error in FirebaseAuth fallback: $e2');
      }
    }
    // Fallback for users without profile data (e.g., anonymous/guest users)
    return <String, dynamic>{
      'displayName': 'Guest User',
      'avatarUrl': null,
      'location': null,
      'latitude': null,
      'longitude': null,
    };
  }

  /// Get multiple users' data
  Future<List<Map<String, dynamic>>> getAttendeesData(
    List<String> attendeeIds,
  ) async {
    final List<Map<String, dynamic>> attendees = [];

    for (final userId in attendeeIds) {
      try {
        final userData = await _getUserData(userId);
        if (userData != null) {
          attendees.add({
            'userId': userId,
            'displayName': userData['displayName'] ?? 'Guest User',
            'avatarUrl': userData['avatarUrl'],
            'location': userData['location'],
          });
        }
      } catch (e) {
        print('Error fetching attendee data for $userId: $e');
      }
    }

    return attendees;
  }

  /// Update meetup details (only host can do this)
  Future<void> updateMeetup({
    required String meetupId,
    String? title,
    String? description,
    DateTime? dateTime,
    String? location,
    int? maxCapacity,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final meetupRef = _meetupsRef.child(meetupId);
    final snapshot = await meetupRef.get();

    if (!snapshot.exists) {
      throw Exception('Meetup not found');
    }

    final meetupData = Map<String, dynamic>.from(
      snapshot.value as Map<dynamic, dynamic>,
    );
    final meetup = Meetup.fromMap(meetupData);

    if (meetup.hostId != currentUserId) {
      throw Exception('Only the host can update this meetup');
    }

    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (dateTime != null) updates['dateTime'] = dateTime.toIso8601String();
    if (location != null) updates['location'] = location;
    if (maxCapacity != null) {
      if (maxCapacity < meetup.currentAttendees) {
        throw Exception('Cannot set capacity lower than current attendees');
      }
      updates['maxCapacity'] = maxCapacity;
    }

    if (updates.isNotEmpty) {
      await meetupRef.update(updates);
    }
  }

  /// Get count of pending join requests for meetups the current user hosts
  /// Note: Does NOT include unread notifications, to avoid double counting
  Stream<int> getPendingHostRequestsCount() async* {
    if (currentUserId == null) {
      yield 0;
      return;
    }

    await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
      try {
        int count = 0;

        // Count pending requests for meetups you host
        final hostedMeetupsSnapshot = await _meetupsRef
            .orderByChild('hostId')
            .equalTo(currentUserId)
            .get();

        if (hostedMeetupsSnapshot.exists) {
          final data = hostedMeetupsSnapshot.value as Map<dynamic, dynamic>;
          for (final entry in data.values) {
            try {
              final meetupData = Map<String, dynamic>.from(
                entry as Map<dynamic, dynamic>,
              );
              final meetup = Meetup.fromMap(meetupData);

              if (meetup.isActive && !meetup.isPast) {
                count += meetup.pendingRequests.length;
              }
            } catch (e) {
              continue;
            }
          }
        }

        yield count;
      } catch (e) {
        print('Error in getPendingHostRequestsCount: $e');
        yield 0;
      }
    }
  }
}
