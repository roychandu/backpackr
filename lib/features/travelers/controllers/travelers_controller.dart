import 'dart:async';
import 'dart:math' as math;

import 'package:backpackr/features/auth/repositories/auth_repository.dart';
import 'package:backpackr/features/chat/models/conversation.dart';
import 'package:backpackr/features/chat/repositories/chat_repository.dart';
import 'package:backpackr/features/meetups/repositories/meetups_repository.dart';
import 'package:backpackr/features/travelers/repositories/travelers_repository.dart';
import 'package:backpackr/features/travelers/models/user_profile.dart';
import 'package:backpackr/features/waves/repositories/wave_repository.dart';
import 'package:backpackr/shared/services/local_storage_service.dart';
import 'package:backpackr/shared/services/user_setup_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as perm;

class TravelerLocationSnapshot {
  const TravelerLocationSnapshot({
    this.currentLocation,
    this.latitude,
    this.longitude,
    this.lastUpdated,
  });

  final String? currentLocation;
  final double? latitude;
  final double? longitude;
  final int? lastUpdated;
}

class NearbyTravelersSnapshot {
  const NearbyTravelersSnapshot({
    required this.travelers,
    required this.travelerIdMap,
    this.currentLocation,
    this.latitude,
    this.longitude,
    this.lastUpdated,
  });

  final List<UserProfile> travelers;
  final Map<String, String> travelerIdMap;
  final String? currentLocation;
  final double? latitude;
  final double? longitude;
  final int? lastUpdated;
}

class TravelersController extends ChangeNotifier {
  TravelersController({
    TravelersRepository? repository,
    AuthRepository? authRepository,
    WaveRepository? waveRepository,
    ChatRepository? chatRepository,
    MeetupsRepository? meetupsRepository,
  }) : _repository = repository ?? TravelersRepository(),
       _authRepository = authRepository ?? AuthRepository(),
       _waveRepository = waveRepository ?? WaveRepository(),
       _chatRepository = chatRepository ?? ChatRepository(),
       _meetupsRepository = meetupsRepository ?? MeetupsRepository();

  final TravelersRepository _repository;
  final AuthRepository _authRepository;
  final WaveRepository _waveRepository;
  final ChatRepository _chatRepository;
  final MeetupsRepository _meetupsRepository;

  Set<String> hiddenTravelerIds = {};
  Set<String> reportedTravelerIds = {};
  bool isLoading = false;
  String? errorMessage;

  String? get currentUserId => _authRepository.currentUser?.uid;

  void initializeUserSetup(BuildContext context) {
    UserSetupService.initialize(context);
  }

  void disposeUserSetup() {
    UserSetupService.dispose();
  }

  Future<void> ensureUserDataInFirebase() {
    return _authRepository.ensureUserDataInFirebase();
  }

  Future<Map<String, dynamic>> getUserData() {
    return _authRepository.getUserData();
  }

  List<UserProfile> getCachedProfiles() {
    return LocalStorageService.getAllProfiles();
  }

  void saveCachedProfiles(List<UserProfile> profiles) {
    LocalStorageService.saveAllProfiles(profiles);
  }

  Future<bool> hasCompletedSetup() {
    return UserSetupService.hasCompletedSetup();
  }

  Future<bool> isProfileStrictlyComplete() {
    return UserSetupService.isProfileStrictlyComplete();
  }

  Future<void> showSetupPopup(BuildContext context) {
    return UserSetupService.showSetupPopup(context);
  }

  Future<bool> requestLocationPermission() async {
    final status = await perm.Permission.location.status;
    if (status.isGranted || status.isLimited || status.isProvisional) {
      return true;
    }
    if (status.isPermanentlyDenied) return false;
    final result = await perm.Permission.location.request();
    return result.isGranted || result.isLimited || result.isProvisional;
  }

  Future<void> openAppSettings() {
    return perm.openAppSettings();
  }

  Future<void> loadPrivacyState(String currentUserId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      hiddenTravelerIds = await _repository.getHiddenTravelersForUser(
        currentUserId,
      );
      reportedTravelerIds = await _repository.getUsersReportedBy(currentUserId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Set<String>> getHiddenTravelersForUser(String currentUserId) {
    return _repository.getHiddenTravelersForUser(currentUserId);
  }

  Future<Set<String>> getUsersReportedBy(String currentUserId) {
    return _repository.getUsersReportedBy(currentUserId);
  }

  Future<void> hideTraveler({
    required String currentUserId,
    required String travelerId,
  }) async {
    await _repository.hideTravelerForUser(
      userId: currentUserId,
      travelerId: travelerId,
    );
    hiddenTravelerIds = {...hiddenTravelerIds, travelerId};
    notifyListeners();
  }

  Future<void> reportTraveler({
    required String currentUserId,
    required String travelerId,
    required String reason,
  }) {
    return _repository.reportUser(
      reporterUserId: currentUserId,
      reportedUserId: travelerId,
      reason: reason,
    );
  }

  Future<TravelerLocationSnapshot?> getSavedCurrentUserLocation() async {
    final user = _authRepository.currentUser;
    if (user == null) return null;

    final snap = await FirebaseDatabase.instance
        .ref('userProfiles')
        .child(user.uid)
        .get();
    if (!snap.exists || snap.value is! Map) return null;

    final data = snap.value as Map<dynamic, dynamic>;
    return TravelerLocationSnapshot(
      currentLocation: (data['currentLocation'] as String?)?.trim(),
      latitude: _readDouble(data['latitude']),
      longitude: _readDouble(data['longitude']),
      lastUpdated: _readInt(data['lastUpdated']),
    );
  }

  Future<TravelerLocationSnapshot?> getCurrentGpsLocationIfAllowed() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    final status = await perm.Permission.location.status;
    if (!status.isGranted && !status.isLimited && !status.isProvisional) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      ),
    );

    var display = '';
    final placemarks = await geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      final city = place.locality?.isNotEmpty == true
          ? place.locality
          : place.subAdministrativeArea;
      final country = place.country ?? place.isoCountryCode;
      display = city != null && city.isNotEmpty
          ? (country != null && country.isNotEmpty ? '$city, $country' : city)
          : '';
    }

    final updatedAt = DateTime.now().millisecondsSinceEpoch;
    await syncCurrentUserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      currentLocation: display.isEmpty ? null : display,
      lastUpdated: updatedAt,
    );

    return TravelerLocationSnapshot(
      currentLocation: display.isEmpty ? null : display,
      latitude: position.latitude,
      longitude: position.longitude,
      lastUpdated: updatedAt,
    );
  }

  Future<void> syncCurrentUserLocation({
    required double latitude,
    required double longitude,
    String? currentLocation,
    int? lastUpdated,
  }) async {
    final uid = _authRepository.currentUser?.uid;
    if (uid == null || !_hasUsableCoordinates(latitude, longitude)) return;

    final updates = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated ?? DateTime.now().millisecondsSinceEpoch,
    };

    if (currentLocation != null && currentLocation.trim().isNotEmpty) {
      updates['currentLocation'] = currentLocation.trim();
    }

    await FirebaseDatabase.instance
        .ref('userProfiles')
        .child(uid)
        .update(updates);
  }

  Stream<NearbyTravelersSnapshot> watchNearbyTravelers({
    required double centerLatitude,
    required double centerLongitude,
    required double radiusKm,
    required int currentCoordinatesUpdatedAt,
  }) {
    return FirebaseDatabase.instance.ref('userProfiles').onValue.asyncMap((
      event,
    ) async {
      final snap = event.snapshot;
      if (!snap.exists || snap.value is! Map) {
        return const NearbyTravelersSnapshot(travelers: [], travelerIdMap: {});
      }

      final data = snap.value as Map<dynamic, dynamic>;
      final nearby = <UserProfile>[];
      final idMap = <String, String>{};
      var nextCity = '';
      var nextLatitude = centerLatitude;
      var nextLongitude = centerLongitude;
      var nextUpdatedAt = currentCoordinatesUpdatedAt;
      final currentUid = _authRepository.currentUser?.uid;

      if (currentUid != null) {
        final currentProfileData = data[currentUid];
        if (currentProfileData is Map) {
          final currentProfile = UserProfile.fromMap(currentProfileData);
          final remoteLastUpdated =
              _readInt(currentProfileData['lastUpdated']) ?? 0;
          if (_hasUsableCoordinates(
                currentProfile.latitude,
                currentProfile.longitude,
              ) &&
              remoteLastUpdated >= currentCoordinatesUpdatedAt) {
            nextLatitude = currentProfile.latitude!;
            nextLongitude = currentProfile.longitude!;
            nextUpdatedAt = remoteLastUpdated;
          }
          if (currentProfile.currentLocation.trim().isNotEmpty) {
            nextCity = currentProfile.currentLocation.trim();
          }
        }
      }

      for (final entry in data.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key == currentUid || value is! Map) continue;

        try {
          final profile = UserProfile.fromMap(value);
          if (!profile.setupCompleted ||
              !_hasUsableCoordinates(profile.latitude, profile.longitude)) {
            continue;
          }

          final distance = _distanceKm(
            nextLatitude,
            nextLongitude,
            profile.latitude!,
            profile.longitude!,
          );
          if (!distance.isFinite || distance > radiusKm) continue;

          var username = (value['displayName'] as String?)?.trim();
          username = (username == null || username.isEmpty)
              ? (value['name'] as String?)?.trim()
              : username;
          username = (username == null || username.isEmpty)
              ? profile.displayName
              : username;

          if (username.isEmpty) {
            username = await _lookupUserName(key.toString()) ?? '';
          }
          if (username.isEmpty) continue;

          final userProfile = UserProfile(
            displayName: username,
            bio: profile.bio.isNotEmpty
                ? profile.bio
                : 'Adventurer exploring the world',
            currentLocation: profile.currentLocation,
            latitude: profile.latitude,
            longitude: profile.longitude,
            avatarUrl: profile.avatarUrl,
            tags: profile.tags,
            destinations: profile.destinations,
            setupCompleted: profile.setupCompleted,
            lastUpdated: profile.lastUpdated,
            wavesSent: profile.wavesSent,
            wavesReceived: profile.wavesReceived,
            mutualConnections: profile.mutualConnections,
          );

          nearby.add(userProfile);
          idMap[userProfile.displayName] = key.toString();
        } catch (_) {
          // Skip invalid profile records.
        }
      }

      return NearbyTravelersSnapshot(
        travelers: nearby,
        travelerIdMap: idMap,
        currentLocation: nextCity.isEmpty ? null : nextCity,
        latitude: nextLatitude,
        longitude: nextLongitude,
        lastUpdated: nextUpdatedAt,
      );
    });
  }

  Future<bool> hasWaveBeenSent(String travelerId) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) return false;

    final waveSnapshot = await FirebaseDatabase.instance
        .ref('userProfiles')
        .child(currentUser.uid)
        .child('waves')
        .get();

    if (!waveSnapshot.exists) return false;
    for (final child in waveSnapshot.children) {
      try {
        final waveData = Map<String, dynamic>.from(
          child.value as Map<dynamic, dynamic>,
        );
        if (waveData['receiverId'] == travelerId) {
          final status = waveData['status'] as String?;
          if (status == 'pending' ||
              status == 'accepted' ||
              status == 'ignored') {
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  Future<String> getWaveStatus(String travelerId) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) return 'none';

    final waveSnapshot = await FirebaseDatabase.instance
        .ref('userProfiles')
        .child(currentUser.uid)
        .child('waves')
        .get();

    if (!waveSnapshot.exists) return 'none';
    for (final child in waveSnapshot.children) {
      try {
        final waveData = Map<String, dynamic>.from(
          child.value as Map<dynamic, dynamic>,
        );
        if (waveData['receiverId'] == travelerId) {
          final status = waveData['status'] as String?;
          if (status == 'pending' ||
              status == 'accepted' ||
              status == 'ignored') {
            return status ?? 'pending';
          }
        }
      } catch (_) {}
    }
    return 'none';
  }

  Future<Conversation> startConversation({
    required String otherUserId,
    required String otherUserName,
  }) async {
    final conversationId = await _chatRepository.createConversation(
      otherUserId: otherUserId,
      otherUserName: otherUserName,
    );
    final conversations = await _chatRepository.getConversations().first;
    return conversations.firstWhere(
      (conversation) => conversation.id == conversationId,
      orElse: () => throw Exception('Conversation not found'),
    );
  }

  Future<void> sendWave({
    required String receiverId,
    required String receiverName,
    required String receiverLocation,
    String? message,
  }) {
    return _waveRepository.sendWave(
      receiverId: receiverId,
      receiverName: receiverName,
      receiverLocation: receiverLocation,
      message: message,
    );
  }

  Stream<int> getPendingReceivedWavesCount() {
    return _waveRepository.getPendingReceivedWavesCount();
  }

  Stream<int> getTotalUnreadCount() {
    return _chatRepository.getTotalUnreadCount();
  }

  Stream<int> getPendingHostRequestsCount() {
    return _meetupsRepository.getPendingHostRequestsCount();
  }

  Future<String?> _lookupUserName(String userId) async {
    final snap = await FirebaseDatabase.instance
        .ref('users')
        .child(userId)
        .get();
    if (!snap.exists || snap.value is! Map) return null;
    final userData = snap.value as Map<dynamic, dynamic>;
    return (userData['name'] as String?)?.trim();
  }

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _hasUsableCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (!latitude.isFinite || !longitude.isFinite) return false;
    if (latitude.abs() > 90 || longitude.abs() > 180) return false;
    return !(latitude == 0 && longitude == 0);
  }

  static double _distanceKm(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(latitude2 - latitude1);
    final dLon = _degToRad(longitude2 - longitude1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(latitude1)) *
            math.cos(_degToRad(latitude2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double degrees) => degrees * math.pi / 180;
}
