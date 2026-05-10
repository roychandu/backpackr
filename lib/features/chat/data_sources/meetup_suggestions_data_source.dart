import 'dart:math' as math;

import 'package:backpackr/features/chat/models/nearby_meetups_result.dart';
import 'package:backpackr/features/meetups/models/meetup.dart';
import 'package:backpackr/features/meetups/data_sources/meetup_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class MeetupSuggestionsDataSource {
  MeetupSuggestionsDataSource({MeetupService? meetupService})
    : _meetupService = meetupService ?? MeetupService();

  final MeetupService _meetupService;

  Future<NearbyMeetupsResult> getNearbyMeetups() async {
    final position = await _getCurrentLocation();
    if (position == null) {
      throw Exception('Unable to get your location');
    }

    final meetups = await _meetupService.getAllMeetups();
    final organizerLocations = await _getOrganizerLocations(meetups);
    final nearby = <Meetup>[];
    final distances = <String, double>{};

    for (final meetup in meetups) {
      if (meetup.isPast) continue;

      double? orgLat;
      double? orgLng;

      if (meetup.latitude != null && meetup.longitude != null) {
        orgLat = meetup.latitude;
        orgLng = meetup.longitude;
      } else if (organizerLocations.containsKey(meetup.hostId)) {
        orgLat = organizerLocations[meetup.hostId]!['latitude'];
        orgLng = organizerLocations[meetup.hostId]!['longitude'];
      }

      if (orgLat != null && orgLng != null) {
        final distance = _distanceKm(
          position.latitude,
          position.longitude,
          orgLat,
          orgLng,
        );

        if (distance <= 200.0) {
          nearby.add(meetup);
          distances[meetup.id] = distance;
        }
      }
    }

    nearby.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return NearbyMeetupsResult(meetups: nearby, organizerDistances: distances);
  }

  Future<Map<String, Map<String, double>>> _getOrganizerLocations(
    List<Meetup> meetups,
  ) async {
    final hostIds = <String>{};
    for (final meetup in meetups) {
      if (!meetup.isPast &&
          (meetup.latitude == null || meetup.longitude == null)) {
        hostIds.add(meetup.hostId);
      }
    }

    final organizerLocations = <String, Map<String, double>>{};
    if (hostIds.isEmpty) return organizerLocations;

    final snapshot = await FirebaseDatabase.instance.ref('userProfiles').get();
    if (!snapshot.exists || snapshot.value is! Map) return organizerLocations;

    final allProfiles = snapshot.value as Map<dynamic, dynamic>;
    for (final hostId in hostIds) {
      if (!allProfiles.containsKey(hostId)) continue;

      final profileData = allProfiles[hostId] as Map<dynamic, dynamic>;
      final lat = profileData['latitude'];
      final lng = profileData['longitude'];

      if (lat != null && lng != null) {
        organizerLocations[hostId] = {
          'latitude': double.tryParse(lat.toString()) ?? 0.0,
          'longitude': double.tryParse(lng.toString()) ?? 0.0,
        };
      }
    }

    return organizerLocations;
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
}
