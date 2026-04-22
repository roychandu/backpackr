// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math' as math;
import '../../common_widgets/app_colors.dart';
import '../../common_widgets/app_text_styles.dart';
import '../../models/meetup.dart';
import '../../services/meetup_service.dart';
import '../meetups_screen/meetup_details_screen.dart';

class SuggestMeetupBottomSheet extends StatefulWidget {
  const SuggestMeetupBottomSheet({super.key});

  @override
  State<SuggestMeetupBottomSheet> createState() =>
      _SuggestMeetupBottomSheetState();
}

class _SuggestMeetupBottomSheetState extends State<SuggestMeetupBottomSheet> {
  final MeetupService _meetupService = MeetupService();
  List<Meetup> _nearbyMeetups = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, double> _organizerDistances = {}; // Store organizer distances

  @override
  void initState() {
    super.initState();
    _loadNearbyMeetups();
  }

  Future<void> _loadNearbyMeetups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user's location
      final position = await _getCurrentLocation();
      if (position == null) {
        setState(() {
          _errorMessage = 'Unable to get your location';
          _isLoading = false;
        });
        return;
      }

      // Get all meetups
      final meetups = await _meetupService.getAllMeetups();

      // Get all unique host IDs that need profile data
      final Set<String> hostIds = {};
      for (final meetup in meetups) {
        if (!meetup.isPast &&
            (meetup.latitude == null || meetup.longitude == null)) {
          hostIds.add(meetup.hostId);
        }
      }

      // Fetch all user profiles at once for efficiency
      final Map<String, Map<String, double>> organizerLocations = {};
      if (hostIds.isNotEmpty) {
        final userProfilesSnapshot = await FirebaseDatabase.instance
            .ref('userProfiles')
            .get();

        if (userProfilesSnapshot.exists && userProfilesSnapshot.value is Map) {
          final allProfiles =
              userProfilesSnapshot.value as Map<dynamic, dynamic>;

          for (final hostId in hostIds) {
            if (allProfiles.containsKey(hostId)) {
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
          }
        }
      }

      // Filter meetups based on organizer's location (within 200km)
      final List<Meetup> nearby = [];
      final Map<String, double> distances = {};

      for (final meetup in meetups) {
        // Skip past meetups
        if (meetup.isPast) continue;

        double? orgLat;
        double? orgLng;

        // Try to get organizer location from meetup data first
        if (meetup.latitude != null && meetup.longitude != null) {
          orgLat = meetup.latitude;
          orgLng = meetup.longitude;
        } else if (organizerLocations.containsKey(meetup.hostId)) {
          // Fallback to fetched profile data
          orgLat = organizerLocations[meetup.hostId]!['latitude'];
          orgLng = organizerLocations[meetup.hostId]!['longitude'];
        }

        // Calculate distance if we have organizer coordinates
        if (orgLat != null && orgLng != null) {
          final distance = _distanceKm(
            position.latitude,
            position.longitude,
            orgLat,
            orgLng,
          );

          // Include meetup if organizer is within 200km
          if (distance <= 200.0) {
            nearby.add(meetup);
            distances[meetup.id] = distance; // Store organizer distance
          }
        }
      }

      // Sort by date
      nearby.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      setState(() {
        _nearbyMeetups = nearby;
        _organizerDistances = distances;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load meetups: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
    } catch (e) {
      return null;
    }
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.98),
                  AppColors.primary.withOpacity(0.78),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.send_rounded, color: AppColors.text1, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggest a Meetup',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.text1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From organizers near you (200km)',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.text1.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: AppColors.text1),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                ? _buildErrorState()
                : _nearbyMeetups.isEmpty
                ? _buildEmptyState()
                : _buildMeetupsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Finding nearby meetups...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: AppTextStyles.h4.copyWith(color: AppColors.primaryText),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadNearbyMeetups,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.text1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: AppColors.primaryText),
            const SizedBox(height: 16),
            Text(
              'No nearby meetups',
              style: AppTextStyles.h4.copyWith(color: AppColors.primaryText),
            ),
            const SizedBox(height: 8),
            Text(
              'No active meetups from organizers within 200km of your location.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetupsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _nearbyMeetups.length,
      itemBuilder: (context, index) {
        final meetup = _nearbyMeetups[index];
        return _buildMeetupCard(meetup);
      },
    );
  }

  Widget _buildMeetupCard(Meetup meetup) {
    // Get the organizer's distance that was calculated earlier
    final distance = _organizerDistances[meetup.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.text1,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.text3.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Close the bottom sheet first
            Navigator.of(context).pop();

            // Navigate to meetup details screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MeetupDetailsScreen(meetup: meetup),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          meetup.category,
                        ).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        meetup.categoryDisplayName,
                        style: TextStyle(
                          color: _getCategoryColor(meetup.category),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (distance != null) ...[
                      Tooltip(
                        message: 'Organizer distance',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_pin_circle,
                              size: 16,
                              color: AppColors.text3.withOpacity(0.45),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${distance.toStringAsFixed(1)} km',
                              style: TextStyle(
                                color: AppColors.text3.withOpacity(0.54),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  meetup.title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.text3.withOpacity(0.87),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  meetup.description,
                  style: TextStyle(
                    color: AppColors.text3.withOpacity(0.54),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.event_available,
                      color: AppColors.text3.withOpacity(0.38),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        meetup.formattedDateTime,
                        style: TextStyle(
                          color: AppColors.text3.withOpacity(0.54),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.text3.withOpacity(0.38), size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        meetup.location,
                        style: TextStyle(
                          color: AppColors.text3.withOpacity(0.54),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      color: AppColors.text3.withOpacity(0.38),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      meetup.capacityDisplay,
                      style: TextStyle(
                        color: meetup.isFull
                            ? AppColors.error
                            : AppColors.text3.withOpacity(0.54),
                        fontSize: 13,
                        fontWeight: meetup.isFull
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Hosted by ${meetup.hostName}',
                      style: TextStyle(
                        color: AppColors.text3.withOpacity(0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(MeetupCategory category) {
    switch (category) {
      case MeetupCategory.work:
        return AppColors.highlight2;
      case MeetupCategory.culture:
        return AppColors.highlight2;
      case MeetupCategory.adventure:
        return AppColors.success;
      case MeetupCategory.food:
        return AppColors.cta1;
      case MeetupCategory.nightlife:
        return AppColors.cta1;
      case MeetupCategory.sports:
        return AppColors.info;
      case MeetupCategory.other:
        return AppColors.textSecondary;
    }
  }
}
