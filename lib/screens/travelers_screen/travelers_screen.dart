// ignore_for_file: use_build_context_synchronously, avoid_print, empty_catches, deprecated_member_use, prefer_interpolation_to_compose_strings, sort_child_properties_last
import 'package:backpackr/common_widgets/app_colors.dart';
import 'package:backpackr/screens/traveling_blogs_screen/traveling_blogs_screen.dart';
import 'package:backpackr/screens/traveling_blogs_screen/other_travelers_blog_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:permission_handler/permission_handler.dart' as perm;
import '../../common_widgets/app_text_styles.dart';
import '../../common_widgets/app_header.dart';
import '../../common_widgets/custom_button.dart';
import '../../common_widgets/sliver_tab_delegate.dart';
import '../waves_screen/waves_screen.dart';
import '../meetups_screen/meetups_screen.dart';
import 'package:backpackr/screens/chat_screens/chat_list_screen.dart';
import '../chat_screens/conversation_screen.dart';
import '../../services/user_setup_service.dart';
import '../../services/auth_service.dart';
import '../../services/wave_service.dart';
import '../../services/chat_service.dart';
import '../../services/meetup_service.dart';
import '../../services/traveler_service.dart';
import '../../services/local_storage_service.dart';
import '../../models/user_profile.dart';
import 'dart:math' as math;

class TravelersScreen extends StatefulWidget {
  const TravelersScreen({super.key});

  @override
  State<TravelersScreen> createState() => _TravelersScreenState();
}

class _TravelersScreenState extends State<TravelersScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const double _nearbyTravelerRadiusKm = 200.0;

  int _selectedIndex = 0;
  late TabController _travelersTabController;
  String _currentCity = '';
  bool _isLocating = false;
  bool _isLoadingTravelers = false;
  double? _currentLatitude;
  double? _currentLongitude;
  int _currentCoordinatesUpdatedAt = 0;
  List<UserProfile> _filteredTravelers = [];
  final List<UserProfile> _allTravelers = [];
  final List<UserProfile> _dummyTravelers = [
    UserProfile(
      displayName: 'Amelia Chen',
      bio: 'Product designer capturing cities through street photography.',
      currentLocation: 'Lisbon, Portugal',
      latitude: null,
      longitude: null,
      avatarUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=300&q=60',
      tags: ['Remote work', 'Foodie', 'Photography'],
      destinations: [Destination(city: 'Barcelona, Spain', date: '02/2025')],
      setupCompleted: true,
      lastUpdated: 1733966400000,
      wavesSent: 12,
      wavesReceived: 30,
      mutualConnections: 6,
    ),
    UserProfile(
      displayName: 'Luca Marino',
      bio: 'Backpacker chasing mountain trails and cozy hostels.',
      currentLocation: 'Bergamo, Italy',
      latitude: null,
      longitude: null,
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=60',
      tags: ['Hiking', 'Budget travel', 'Coffee'],
      destinations: [
        Destination(city: 'Interlaken, Switzerland', date: '03/2025'),
      ],
      setupCompleted: true,
      lastUpdated: 1734052800000,
      wavesSent: 8,
      wavesReceived: 19,
      mutualConnections: 4,
    ),
    UserProfile(
      displayName: 'Sara Patel',
      bio: 'Weekend explorer who never skips local food tours.',
      currentLocation: 'Austin, USA',
      latitude: null,
      longitude: null,
      avatarUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=300&q=60',
      tags: ['Food tours', 'Live music', 'Solo travel'],
      destinations: [Destination(city: 'Mexico City, Mexico', date: '01/2025')],
      setupCompleted: true,
      lastUpdated: 1734139200000,
      wavesSent: 20,
      wavesReceived: 41,
      mutualConnections: 10,
    ),
    UserProfile(
      displayName: 'Jonas Weber',
      bio: 'Cyclist mapping scenic routes and hidden bakeries.',
      currentLocation: 'Munich, Germany',
      latitude: null,
      longitude: null,
      avatarUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=300&q=60',
      tags: ['Cycling', 'History', 'Coffee'],
      destinations: [Destination(city: 'Prague, Czechia', date: '04/2025')],
      setupCompleted: true,
      lastUpdated: 1734225600000,
      wavesSent: 15,
      wavesReceived: 27,
      mutualConnections: 7,
    ),
    UserProfile(
      displayName: 'Nia Okafor',
      bio: 'Solo traveler learning languages through slow travel.',
      currentLocation: 'Cape Town, South Africa',
      latitude: null,
      longitude: null,
      avatarUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=300&q=60',
      tags: ['Language exchange', 'Beaches', 'Art museums'],
      destinations: [Destination(city: 'Lisbon, Portugal', date: '05/2025')],
      setupCompleted: true,
      lastUpdated: 1734312000000,
      wavesSent: 9,
      wavesReceived: 22,
      mutualConnections: 5,
    ),
  ];
  final Map<String, String> _travelerIdMap = {}; // Maps UserProfile to userId
  final Map<String, bool> _waveSentMap =
      {}; // Tracks if wave already sent to user
  final Map<String, bool> _waveCheckingMap =
      {}; // Tracks which users are currently being checked
  final Map<String, String> _waveStatusMap =
      {}; // Tracks wave status: 'pending', 'accepted', 'mutual'
  final Set<String> _hiddenTravelerIds = {}; // Travelers hidden by current user
  final Set<String> _reportedTravelerIds =
      {}; // Travelers reported by current user
  String _userName = '';
  bool _setupCompleted = false;
  bool _hasCheckedLocationPermission = false;
  Timer? _setupPollTimer;
  final AuthService _authService = AuthService();
  final WaveService _waveService = WaveService();
  final ChatService _chatService = ChatService();
  final MeetupService _meetupService = MeetupService();
  final TravelerService _travelerService = TravelerService();
  StreamSubscription<DatabaseEvent>? _profilesSubscription;
  int _profilesSubscriptionGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _travelersTabController = TabController(length: 2, vsync: this);

    // Add listener to search controller for reactive UI updates
    // removed search listener

    // Initialize user setup service and check location permission
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      UserSetupService.initialize(context);

      // Check location permission after login
      await _checkLocationPermission();
    });

    // No static seed; data should be populated from backend when available
    _loadUserName();
    _checkSetupAndMaybeLoadLocation();
    _applyFilters();
    // Ensure current user data exists in Firebase
    _authService.ensureUserDataInFirebase();

    // Load cached travelers for instant UI
    _loadCachedTravelers();

    // Load hidden/reported travelers for current user
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        try {
          final hidden = await _travelerService.getHiddenTravelersForUser(uid);
          final reported = await _travelerService.getUsersReportedBy(uid);
          if (mounted) {
            setState(() {
              _hiddenTravelerIds
                ..clear()
                ..addAll(hidden);
              _reportedTravelerIds
                ..clear()
                ..addAll(reported);
              _applyFilters();
            });
          }
        } catch (_) {}
      }
    });
  }

  void _loadCachedTravelers() {
    final cached = LocalStorageService.getAllProfiles();
    if (cached.isNotEmpty) {
      setState(() {
        _allTravelers.addAll(cached);
        _applyFilters();
        // Keep _isLoadingTravelers true so the spinner still shows we are checking for updates
      });
    }
  }

  @override
  void dispose() {
    _profilesSubscriptionGeneration++;
    _profilesSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    UserSetupService.dispose();
    _travelersTabController.dispose();
    _setupPollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSetupAndMaybeLoadLocation();
      // Clear wave tracking when app resumes to refresh status
      _clearWaveTracking();
    }
  }

  /// Clear wave tracking maps to force refresh of wave status
  void _clearWaveTracking() {
    setState(() {
      _waveSentMap.clear();
      _waveCheckingMap.clear();
      _waveStatusMap.clear();
    });
  }

  /// Check location permission status and show dialog if needed
  Future<void> _checkLocationPermission() async {
    if (_hasCheckedLocationPermission) return;
    _hasCheckedLocationPermission = true;
    await _requestLocationPermission();
  }

  /// Show dialog when location service is disabled
  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            const Text('Location Service Disabled'),
          ],
        ),
        content: const Text(
          'Location services are turned off. Please enable location services to find travelers near you.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          CustomButton(
            text: 'Maybe Later',
            isTextOnly: true,
            textColor: AppColors.textSecondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
          CustomButton(
            text: 'Open Settings',
            backgroundColor: AppColors.primary,
            onPressed: () async {
              Navigator.of(context).pop();
              await perm.openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  /// Request location permission
  Future<void> _requestLocationPermission() async {
    try {
      // Check current status using permission_handler
      var status = await perm.Permission.location.status;

      // If already granted or limited (iOS), no need to request
      if (status.isGranted || status.isLimited || status.isProvisional) {
        debugPrint('Location permission already granted or limited');
        return;
      }

      // If permanently denied, show settings dialog
      if (status.isPermanentlyDenied) {
        if (mounted) {
          _showOpenSettingsDialog();
        }
        return;
      }

      // Request permission
      final result = await perm.Permission.location.request();

      // If user denied after request, maybe show settings dialog if suitable
      if (result.isPermanentlyDenied && mounted) {
        _showOpenSettingsDialog();
      }
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
    }
  }

  /// Show dialog to open app settings
  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Location Permission Required'),
        content: const Text(
          'The location permission allows the app to determine your current location using GPS or network services. This helps provide personalized features like suggesting nearby users, destinations, or tagging your location in posts. It enhances your overall app experience by enabling location-based recommendations.',
        ),
        actions: [
          CustomButton(
            text: 'Cancel',
            isTextOnly: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
          CustomButton(
            text: 'Open Settings',
            backgroundColor: AppColors.primary,
            onPressed: () {
              Navigator.of(context).pop();
              perm.openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _checkSetupAndMaybeLoadLocation() async {
    try {
      final completed = await UserSetupService.hasCompletedSetup();
      if (!mounted) return;
      setState(() {
        _setupCompleted = completed;
      });
      if (completed) {
        // Set loading state before loading
        if (mounted) {
          setState(() {
            _isLoadingTravelers = true;
          });
        }
        await _loadCurrentCity();
      } else {
        // ensure we don't show any previous city
        setState(() {
          _currentCity = '';
          _isLoadingTravelers = false; // No loading if setup not completed
        });
        // Start a short polling loop to detect completion soon after user finishes setup
        _setupPollTimer?.cancel();
        _setupPollTimer = Timer.periodic(const Duration(seconds: 2), (t) async {
          final done = await UserSetupService.hasCompletedSetup();
          if (done) {
            t.cancel();
            if (!mounted) return;
            setState(() {
              _setupCompleted = true;
              _isLoadingTravelers = true; // Start loading when setup completes
            });
            await _loadCurrentCity();
          }
        });
      }
    } catch (_) {
      // ignore
      if (mounted) {
        setState(() {
          _isLoadingTravelers = false;
        });
      }
    }
  }

  Future<void> _loadUserName() async {
    try {
      final userData = await _authService.getUserData();
      if (mounted) {
        setState(() {
          _userName = userData['name'] ?? '';
        });
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadCurrentCity() async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
    });
    try {
      // First, try to get city from Firebase user profile
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final profileSnap = await FirebaseDatabase.instance
              .ref('userProfiles')
              .child(user.uid)
              .get();

          if (profileSnap.exists && profileSnap.value is Map) {
            final profileData = profileSnap.value as Map<dynamic, dynamic>;
            final savedLocation = profileData['currentLocation'] as String?;
            final savedLatitude = _readDouble(profileData['latitude']);
            final savedLongitude = _readDouble(profileData['longitude']);
            final savedLastUpdated = _readInt(profileData['lastUpdated']) ?? 0;
            final hasSavedLocation =
                savedLocation != null && savedLocation.trim().isNotEmpty;
            final hasSavedCoordinates = _hasUsableCoordinates(
              savedLatitude,
              savedLongitude,
            );

            if (hasSavedLocation || hasSavedCoordinates) {
              if (mounted) {
                setState(() {
                  if (hasSavedLocation) {
                    _currentCity = savedLocation.trim();
                  }
                  if (hasSavedCoordinates) {
                    _setCurrentCoordinates(
                      savedLatitude!,
                      savedLongitude!,
                      updatedAt: savedLastUpdated,
                    );
                  }
                  _applyFilters();
                });
              }
              if (hasSavedCoordinates) {
                await _startNearbyTravelersWatcher();
              }

              // Refresh with GPS, but do not block first nearby results on geocoding.
              await _loadCurrentCityFromGPS();
              return;
            }
          }
        } catch (e) {}
      }

      // Fallback to GPS geocoding if no Firebase location
      await _loadCurrentCityFromGPS();
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _loadCurrentCityFromGPS() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location service disabled - stop loading
        if (mounted) {
          setState(() {
            _isLoadingTravelers = false;
          });
        }
        return;
      }

      // Check status but DO NOT auto-request here to avoid popups on every app resume
      var status = await perm.Permission.location.status;

      if (!status.isGranted && !status.isLimited && !status.isProvisional) {
        // Not granted - stop loading rather than showing a popup again
        if (mounted) {
          setState(() {
            _isLoadingTravelers = false;
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10), // Add timeout
      );
      if (!mounted) return;

      final positionUpdatedAt = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        _setCurrentCoordinates(
          position.latitude,
          position.longitude,
          updatedAt: positionUpdatedAt,
        );
        _applyFilters();
      });

      unawaited(
        _syncCurrentUserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          lastUpdated: positionUpdatedAt,
        ),
      );

      await _startNearbyTravelersWatcher();

      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city = p.locality?.isNotEmpty == true
            ? p.locality
            : p.subAdministrativeArea;
        final country = p.country ?? p.isoCountryCode;
        final display = city != null && city.isNotEmpty
            ? (country != null && country.isNotEmpty ? '$city, $country' : city)
            : '';
        if (mounted && display.isNotEmpty) {
          setState(() {
            _currentCity = display;
            _applyFilters();
          });
          unawaited(
            _syncCurrentUserLocation(
              latitude: position.latitude,
              longitude: position.longitude,
              currentLocation: display,
            ),
          );
        }
      } else {
        // No placemarks found - stop loading
        if (mounted && _profilesSubscription == null) {
          setState(() {
            _isLoadingTravelers = false;
          });
        }
      }
    } catch (e) {
      // Error getting location - stop loading
      print('Error loading location: $e');
      if (mounted) {
        setState(() {
          _isLoadingTravelers = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildTravelersScreen(); // Travelers
      case 1:
        return const WavesScreen();
      case 2:
        return const MeetupsScreen();
      case 3:
        return const ChatListScreen();
      case 4:
        return const TravelingBlogsScreen();
      default:
        return _buildTravelersScreen();
    }
  }

  Widget _buildTravelersScreen() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(child: _buildDiscoverHeader()),
          SliverPersistentHeader(
            pinned: true,
            delegate: SliverTabDelegate(
              child: Container(
                width: double.infinity,
                color: AppColors.background,
                child: TabBar(
                  controller: _travelersTabController,
                  isScrollable: false,
                  padding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.zero,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.text1.withOpacity(0.70),
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_alt_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('All Travelers'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Near Travelers'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _travelersTabController,
        children: [
          RefreshIndicator(
            onRefresh: () async {
              if (_setupCompleted) {
                await _loadCurrentCity();
              }
              _applyFilters();
            },
            child: _buildAllTravelersList(),
          ),
          RefreshIndicator(
            onRefresh: () async {
              if (_setupCompleted) {
                await _loadCurrentCity();
              }
              _applyFilters();
            },
            child: _buildNearTravelersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverHeader() {
    return AppHeader(
      title: 'Discover Travelers',
      topSubtitle: _userName.isNotEmpty ? 'Hi, ' + _userName : null,
      fontSize: 32,
      customBottomContent: Row(
        children: [
          Expanded(
            child: Text(
              _setupCompleted && _currentCity.isNotEmpty
                  ? 'Connect with fellow adventurers in ' + _currentCity
                  : 'Connect with fellow adventurers',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text1.withOpacity(0.9),
              ),
            ),
          ),
          if (_setupCompleted && _isLocating)
            Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.text1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Remove static data: rely on dynamic list (to be plugged from backend)

  void _applyFilters() {
    // Start with all travelers already filtered by the 200km watcher.
    Iterable<UserProfile> list = _allTravelers;

    // Exclude hidden and reported travelers
    list = list.where((t) {
      final travelerId = _travelerIdMap[t.displayName];
      if (travelerId == null) return true;
      if (_hiddenTravelerIds.contains(travelerId)) return false;
      if (_reportedTravelerIds.contains(travelerId)) return false;
      return true;
    });

    _filteredTravelers = list.toList();
  }

  bool _isDummyTraveler(UserProfile traveler) {
    return _dummyTravelers.any(
      (dummy) => dummy.displayName == traveler.displayName,
    );
  }

  // Haversine distance in kilometers
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    // Validate inputs to prevent NaN
    if (lat1.isNaN || lon1.isNaN || lat2.isNaN || lon2.isNaN) {
      return double.infinity; // Return infinity for invalid coordinates
    }
    if (lat1 < -90 || lat1 > 90 || lat2 < -90 || lat2 > 90) {
      return double.infinity; // Invalid latitude
    }
    if (lon1 < -180 || lon1 > 180 || lon2 < -180 || lon2 > 180) {
      return double.infinity; // Invalid longitude
    }

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
    final double distance = earthRadiusKm * c;

    // Validate result to prevent NaN
    if (distance.isNaN || distance.isInfinite) {
      return double.infinity;
    }
    return distance;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);

  double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  bool _hasUsableCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (latitude.isNaN || longitude.isNaN) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    return true;
  }

  void _setCurrentCoordinates(
    double latitude,
    double longitude, {
    int? updatedAt,
  }) {
    _currentLatitude = latitude;
    _currentLongitude = longitude;
    if (updatedAt != null) {
      _currentCoordinatesUpdatedAt = updatedAt;
    }
  }

  Future<void> _syncCurrentUserLocation({
    required double latitude,
    required double longitude,
    String? currentLocation,
    int? lastUpdated,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !_hasUsableCoordinates(latitude, longitude)) return;

    final updates = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated ?? DateTime.now().millisecondsSinceEpoch,
    };

    if (currentLocation != null && currentLocation.trim().isNotEmpty) {
      updates['currentLocation'] = currentLocation.trim();
    }

    try {
      await FirebaseDatabase.instance
          .ref('userProfiles')
          .child(uid)
          .update(updates);
    } catch (e) {
      debugPrint('Failed to sync current location: $e');
    }
  }

  // Removed fallback loader to enforce 200km-only visibility

  Future<void> _startNearbyTravelersWatcher() async {
    if (!_hasUsableCoordinates(_currentLatitude, _currentLongitude)) {
      if (mounted) {
        setState(() {
          _allTravelers.clear();
          _applyFilters();
          _isLoadingTravelers = false;
        });
      }
      return;
    }

    final generation = ++_profilesSubscriptionGeneration;
    try {
      if (mounted) {
        setState(() {
          _isLoadingTravelers = true;
        });
      }

      await _profilesSubscription?.cancel();
      _profilesSubscription = FirebaseDatabase.instance
          .ref('userProfiles')
          .onValue
          .listen(
            (DatabaseEvent event) async {
              if (generation != _profilesSubscriptionGeneration) return;

              try {
                // Clear maps at the START, not at the end
                _travelerIdMap.clear();
                _waveSentMap.clear();
                _waveCheckingMap.clear();
                _waveStatusMap.clear();

                final DataSnapshot snap = event.snapshot;
                if (!snap.exists || snap.value is! Map) {
                  if (mounted &&
                      generation == _profilesSubscriptionGeneration) {
                    setState(() {
                      _allTravelers.clear();
                      _applyFilters();
                      _isLoadingTravelers = false;
                    });
                  }
                  return;
                }

                final Map<dynamic, dynamic> data =
                    snap.value as Map<dynamic, dynamic>;
                final List<UserProfile> nearby = [];
                final String? currentUid =
                    FirebaseAuth.instance.currentUser?.uid;

                if (currentUid != null) {
                  final currentProfileData = data[currentUid];
                  if (currentProfileData is Map) {
                    final currentProfile = UserProfile.fromMap(
                      currentProfileData,
                    );
                    final remoteLastUpdated =
                        _readInt(currentProfileData['lastUpdated']) ?? 0;
                    if (_hasUsableCoordinates(
                          currentProfile.latitude,
                          currentProfile.longitude,
                        ) &&
                        remoteLastUpdated >= _currentCoordinatesUpdatedAt) {
                      _setCurrentCoordinates(
                        currentProfile.latitude!,
                        currentProfile.longitude!,
                        updatedAt: remoteLastUpdated,
                      );
                    }
                    if (currentProfile.currentLocation.trim().isNotEmpty) {
                      _currentCity = currentProfile.currentLocation.trim();
                    }
                  }
                }

                final currentLat = _currentLatitude;
                final currentLng = _currentLongitude;
                if (!_hasUsableCoordinates(currentLat, currentLng)) {
                  if (mounted &&
                      generation == _profilesSubscriptionGeneration) {
                    setState(() {
                      _allTravelers.clear();
                      _applyFilters();
                      _isLoadingTravelers = false;
                    });
                  }
                  return;
                }

                final centerLatitude = currentLat!;
                final centerLongitude = currentLng!;

                for (final entry in data.entries) {
                  final key = entry.key;
                  final value = entry.value;

                  if (value is Map) {
                    // Skip current user
                    if (currentUid != null &&
                        key is String &&
                        key == currentUid) {
                      continue;
                    }

                    try {
                      final profile = UserProfile.fromMap(value);
                      if (!profile.setupCompleted) continue;
                      if (!_hasUsableCoordinates(
                        profile.latitude,
                        profile.longitude,
                      )) {
                        continue;
                      }

                      final distance = _distanceKm(
                        centerLatitude,
                        centerLongitude,
                        profile.latitude!,
                        profile.longitude!,
                      );
                      if (!distance.isFinite ||
                          distance > _nearbyTravelerRadiusKm) {
                        continue;
                      }

                      // Resolve username with multiple fallbacks
                      String? username;

                      // 1) Prefer name fields on profile record itself
                      final rawMap = value;
                      final fromProfileName = (rawMap['displayName'] as String?)
                          ?.trim();
                      final fromProfileAlt = (rawMap['name'] as String?)
                          ?.trim();
                      if (fromProfileName != null &&
                          fromProfileName.isNotEmpty) {
                        username = fromProfileName;
                      } else if (fromProfileAlt != null &&
                          fromProfileAlt.isNotEmpty) {
                        username = fromProfileAlt;
                      } else if (profile.displayName.isNotEmpty) {
                        username = profile.displayName;
                      } else {
                        // 2) Then try users/<uid>/name
                        try {
                          final userSnap = await FirebaseDatabase.instance
                              .ref('users')
                              .child(key.toString())
                              .get();
                          if (userSnap.exists) {
                            final userData =
                                userSnap.value as Map<dynamic, dynamic>;
                            final dbName = userData['name'] as String?;
                            if (dbName != null && dbName.trim().isNotEmpty) {
                              username = dbName.trim();
                            }
                          }
                        } catch (_) {
                          // leave as null
                        }
                      }

                      // Skip users without proper names
                      if (username == null || username.isEmpty) {
                        continue;
                      }

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
                      // Store mapping for wave sending
                      _travelerIdMap[userProfile.displayName] = key.toString();
                    } catch (e) {
                      // Skip invalid profile data
                    }
                  }
                }

                if (!mounted || generation != _profilesSubscriptionGeneration) {
                  return;
                }
                setState(() {
                  _allTravelers
                    ..clear()
                    ..addAll(nearby);
                  _applyFilters();
                  _isLoadingTravelers = false;
                });

                // Cache the profiles for next launch
                LocalStorageService.saveAllProfiles(nearby);
              } catch (e) {
                debugPrint('Error processing nearby travelers: $e');
                if (mounted && generation == _profilesSubscriptionGeneration) {
                  setState(() {
                    _allTravelers.clear();
                    _applyFilters();
                    _isLoadingTravelers = false;
                  });
                }
              }
            },
            onError: (Object error) {
              debugPrint('Error watching nearby travelers: $error');
              if (!mounted || generation != _profilesSubscriptionGeneration) {
                return;
              }
              setState(() {
                _allTravelers.clear();
                _travelerIdMap.clear();
                _waveSentMap.clear();
                _waveCheckingMap.clear();
                _waveStatusMap.clear();
                _applyFilters();
                _isLoadingTravelers = false;
              });
            },
          );
    } catch (e) {
      print('Error in _startNearbyTravelersWatcher: $e');
      if (!mounted) return;
      setState(() {
        _allTravelers.clear();
        _travelerIdMap.clear(); // Clear mappings on error
        _waveSentMap.clear(); // Clear wave sent tracking on error
        _waveCheckingMap.clear(); // Clear checking states on error
        _waveStatusMap.clear(); // Clear wave status tracking on error
        _applyFilters();
        _isLoadingTravelers = false;
      });
    }
  }

  Widget _buildAllTravelersList() {
    if (_isLoadingTravelers) {
      return SizedBox.expand(
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    // Show dummy travelers only when no real travelers are available
    final List<UserProfile> displayList = _filteredTravelers.isNotEmpty
        ? _filteredTravelers
        : _dummyTravelers;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: displayList.length,
      itemBuilder: (context, index) => _buildTravelerCard(displayList[index]),
    );
  }

  Widget _buildNearTravelersList() {
    if (_isLoadingTravelers) {
      return SizedBox.expand(
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    // Prefer coordinate filtering within 200km if we have current coordinates.
    if (_hasUsableCoordinates(_currentLatitude, _currentLongitude)) {
      final currentLatitude = _currentLatitude!;
      final currentLongitude = _currentLongitude!;
      final List<UserProfile> gpsNear = _filteredTravelers.where((t) {
        if (t.latitude == null || t.longitude == null) return false;
        // Validate coordinates before calculating distance
        if (t.latitude!.isNaN || t.longitude!.isNaN) return false;
        if (t.latitude! < -90 || t.latitude! > 90) return false;
        if (t.longitude! < -180 || t.longitude! > 180) return false;
        final dist = _distanceKm(
          currentLatitude,
          currentLongitude,
          t.latitude!,
          t.longitude!,
        );
        return dist.isFinite && dist <= _nearbyTravelerRadiusKm;
      }).toList();

      if (gpsNear.isNotEmpty) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: gpsNear.length,
          itemBuilder: (context, index) => _buildTravelerCard(gpsNear[index]),
        );
      }
      // Coordinate filtering returned an empty list.
      return SizedBox.expand(
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildEmptyTravelersState(),
          ),
        ),
      );
    }

    // Fallback: if GPS not available, use city-name match
    String cityOnly = _currentCity;
    final commaIndex = cityOnly.indexOf(',');
    if (commaIndex != -1) {
      cityOnly = cityOnly.substring(0, commaIndex).trim();
    }
    final String cityLower = cityOnly.trim().toLowerCase();

    final List<UserProfile> nearList = _filteredTravelers.where((t) {
      if (cityLower.isEmpty) return true; // if unknown, show all
      final loc = t.currentLocation.trim().toLowerCase();
      return loc.contains(cityLower);
    }).toList();

    if (nearList.isEmpty) {
      return SizedBox.expand(
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildEmptyTravelersState(),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: nearList.length,
      itemBuilder: (context, index) => _buildTravelerCard(nearList[index]),
    );
  }

  Widget _buildEmptyTravelersState() {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final imageSize = math.min(screenWidth, screenHeight) * 0.4;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: imageSize,
              height: imageSize,
              child: Image.asset(
                'assets/travelers-empty.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No travelers nearby',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.text1,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try broadening your search or check back later',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text1.withOpacity(0.70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelerCard(UserProfile t) {
    return GestureDetector(
      onTap: () {
        final travelerId = _travelerIdMap[t.displayName];
        final bool isDummy = _isDummyTraveler(t);

        if (travelerId != null && travelerId.isNotEmpty && !isDummy) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtherTravelersBlogScreen(
                userId: travelerId,
                userName: t.displayName,
                currentLocation: t.currentLocation.isNotEmpty
                    ? t.currentLocation
                    : null,
                avatarUrl: t.avatarUrl,
                destinations: t.destinations.isNotEmpty
                    ? t.destinations.map((d) => d.city).toList()
                    : null,
              ),
            ),
          );
        } else if (isDummy) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(
                'This is a demo profile. Connect with real travelers to view their blogs!',
              ),
              backgroundColor: AppColors.info,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Unable to find traveler information'),
              backgroundColor: AppColors.cta1,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.text3.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.surface,
                      child: (t.avatarUrl == null || t.avatarUrl!.isEmpty)
                          ? Icon(
                              Icons.person,
                              color: AppColors.textSecondary,
                              size: 28,
                            )
                          : null,
                      backgroundImage:
                          (t.avatarUrl != null && t.avatarUrl!.isNotEmpty)
                          ? NetworkImage(t.avatarUrl!)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.text1, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.displayName, // Removed age display since it's not stored in profile
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.text3.withOpacity(0.87),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Options menu for traveler card (Block / Report) with more_horiz icon
                PopupMenuButton<String>(
                  onSelected: (value) => _handleTravelerMenu(value, t),
                  icon: const Icon(Icons.more_horiz), // changed icon here
                  itemBuilder: (context) {
                    return <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(Icons.block, color: AppColors.error, size: 18),
                            SizedBox(width: 8),
                            Text('Block user'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'report',
                        child: Row(
                          children: const [
                            Icon(
                              Icons.flag_outlined,
                              color: AppColors.highlight,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text('Report user'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              t.bio,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text3.withOpacity(0.54),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 18,
                  color: AppColors.text3.withOpacity(0.45),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t.currentLocation.isNotEmpty
                        ? t.currentLocation
                        : 'Location not set',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.text3.withOpacity(0.54),
                    ),
                  ),
                ),
              ],
            ),
            if (t.destinations.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Next: ${t.destinations.first.city}',
                style: const TextStyle(
                  color: AppColors.highlight2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (t.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: t.tags.map((e) => _buildTagChip(e)).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(children: [Expanded(child: _buildWaveButton(t))]),
          ],
        ),
      ),
    );
  }

  void _handleTravelerMenu(String action, UserProfile traveler) async {
    switch (action) {
      case 'block':
        _showBlockTravelerDialog(traveler);
        break;
      case 'report':
        _showReportTravelerDialog(traveler);
        break;
    }
  }

  void _showBlockTravelerDialog(UserProfile traveler) {
    final messenger = ScaffoldMessenger.of(context);
    final travelerId = _travelerIdMap[traveler.displayName] ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.block, color: AppColors.error),
            SizedBox(width: 8),
            Text('Block this traveler'),
          ],
        ),
        content: const Text(
          'This traveler will be blocked from your list. You can still see other travelers nearby.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          CustomButton(
            text: 'Cancel',
            isTextOnly: true,
            textColor: AppColors.textSecondary,
            onPressed: () => Navigator.pop(context),
          ),
          CustomButton(
            text: 'Block user',
            backgroundColor: AppColors.error,
            onPressed: () async {
              Navigator.pop(context);
              try {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) {
                  messenger.showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Please log in to hide travelers'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                if (travelerId.isEmpty) return;
                await _travelerService.hideTravelerForUser(
                  userId: currentUser.uid,
                  travelerUserId: travelerId,
                );
                setState(() {
                  _hiddenTravelerIds.add(travelerId);
                  _applyFilters();
                });
                messenger.showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      'User blocked. You will not see their profile.',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Failed to hide: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showReportTravelerDialog(UserProfile traveler) {
    final messenger = ScaffoldMessenger.of(context);
    final reasonCtrl = TextEditingController();
    final travelerId = _travelerIdMap[traveler.displayName] ?? '';
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.flag_outlined, color: AppColors.highlight),
            SizedBox(width: 8),
            Text('Report user'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tell us what happened'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Reason (required)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'Cancel',
            isTextOnly: true,
            textColor: AppColors.textSecondary,
            onPressed: () => Navigator.pop(dlgCtx),
          ),
          CustomButton(
            text: 'Submit',
            backgroundColor: AppColors.highlight,
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(dlgCtx);
              try {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) {
                  messenger.showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Please log in to report users'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                if (travelerId.isEmpty) return;
                await _travelerService.reportUser(
                  reportedUserId: travelerId,
                  reporterUserId: currentUser.uid,
                  reason: reason,
                );
                setState(() {
                  _reportedTravelerIds.add(travelerId);
                  _applyFilters();
                });
                messenger.showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('User reported. Thank you for the feedback.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Failed to report: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWaveButton(UserProfile traveler) {
    final travelerId = _travelerIdMap[traveler.displayName] ?? '';
    final isChecking = _waveCheckingMap[travelerId] ?? false;
    final waveStatus = _waveStatusMap[travelerId] ?? 'none';

    // Require profile setup completion before allowing any wave interactions
    if (!_setupCompleted) {
      return CustomButton(
        text: 'Complete Profile to Connect',
        backgroundColor: AppColors.primary,
        icon: Icons.person_pin_circle,
        isFullWidth: true,
        height: 48,
        onPressed: () async {
          final completed = await _checkProfileSetup();
          if (!mounted) return;
          if (completed) {
            setState(() {
              _setupCompleted = true;
            });
          }
        },
      );
    }

    // Check wave status if not already checked and not currently checking
    if (!_waveSentMap.containsKey(travelerId) && !isChecking) {
      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hasWaveBeenSent(travelerId);
      });
    }

    if (isChecking) {
      return CustomButton(
        text: 'Checking...',
        backgroundColor: AppColors.primary,
        isFullWidth: true,
        height: 48,
        isLoading: true,
        onPressed: null,
      );
    }

    // Show different button based on wave status
    if (waveStatus == 'accepted') {
      return CustomButton(
        text: 'Mutual Connection',
        backgroundColor: AppColors.highlight2,
        icon: Icons.chat_bubble,
        isFullWidth: true,
        height: 48,
        onPressed: () async {
          if (!await _checkProfileSetup()) return;
          await _startChat(travelerId, traveler.displayName);
        },
      );
    } else if (waveStatus == 'pending') {
      return CustomButton(
        text: 'Wave Pending',
        backgroundColor: AppColors.cta1,
        icon: Icons.schedule,
        isFullWidth: true,
        height: 48,
        onPressed: null,
      );
    } else if (waveStatus == 'ignored') {
      return CustomButton(
        text: 'Wave Ignored',
        backgroundColor: AppColors.textSecondary,
        icon: Icons.block,
        isFullWidth: true,
        height: 48,
        onPressed: null,
      );
    } else {
      return CustomButton(
        text: 'Send Wave',
        backgroundColor: AppColors.primary,
        icon: Icons.waving_hand,
        isFullWidth: true,
        height: 48,
        onPressed: () async {
          if (!await _checkProfileSetup()) return;
          await _sendWave(traveler);
        },
      );
    }
  }

  Future<bool> _hasWaveBeenSent(String travelerId) async {
    // Mark as checking
    _waveCheckingMap[travelerId] = true;
    setState(() {});

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _waveCheckingMap[travelerId] = false;
        return false;
      }

      // Fetch all waves and check locally to avoid Android warning
      final waveSnapshot = await FirebaseDatabase.instance
          .ref('userProfiles')
          .child(currentUser.uid)
          .child('waves')
          .get();

      bool hasWave = false;
      String waveStatus = 'none';
      if (waveSnapshot.exists) {
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
                hasWave = true;
                waveStatus = status ?? 'pending';
                break;
              }
            }
          } catch (_) {}
        }
      }

      // Update the result and clear checking state
      _waveSentMap[travelerId] = hasWave;
      _waveStatusMap[travelerId] = waveStatus;
      _waveCheckingMap[travelerId] = false;
      setState(() {});

      return hasWave;
    } catch (e) {
      print('Error checking wave status: $e');
      _waveCheckingMap[travelerId] = false;
      setState(() {});
      return false;
    }
  }

  Future<void> _startChat(String otherUserId, String otherUserName) async {
    try {
      // Show loading indicator
      _showSnackBar('Opening chat...', AppColors.primary);

      final conversationId = await _chatService.createConversation(
        otherUserId: otherUserId,
        otherUserName: otherUserName,
      );

      if (!mounted) return;

      // Get the conversation object from the service
      final conversations = await _chatService.getConversations().first;
      final conversation = conversations.firstWhere(
        (c) => c.id == conversationId,
        orElse: () => throw Exception('Conversation not found'),
      );

      // Navigate to conversation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationScreen(conversation: conversation),
        ),
      );
    } catch (e) {
      print('Failed to start chat: ${e.toString()}');
      if (mounted) {
        _showSnackBar('Failed to open chat: ${e.toString()}', AppColors.error);
      }
    }
  }

  Future<void> _sendWave(UserProfile traveler) async {
    try {
      // Check if user has completed profile setup
      if (!await _checkProfileSetup()) {
        return;
      }

      // Get user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showSnackBar('Please log in to send waves', AppColors.error);
        return;
      }

      // Get the traveler's user ID from our mapping
      final receiverId = _travelerIdMap[traveler.displayName];
      final bool isDummy = _isDummyTraveler(traveler);

      if (receiverId == null || isDummy) {
        _showSnackBar(
          'This is a demo profile. Connect with real travelers to send waves!',
          AppColors.info,
        );
        return;
      }

      // Don't allow sending waves to yourself
      if (currentUser.uid == receiverId) {
        _showSnackBar('You cannot send a wave to yourself', AppColors.cta1);
        return;
      }

      // Show dialog to add optional message
      final message = await _showWaveDialog();
      if (message != null) {
        // Show loading indicator
        _showSnackBar('Sending wave...', AppColors.primary);

        // Get the traveler's user ID from our mapping
        final receiverId = _travelerIdMap[traveler.displayName];
        if (receiverId == null) {
          _showSnackBar('Unable to find traveler ID', AppColors.error);
          return;
        }

        // Send the wave using WaveService
        await _waveService.sendWave(
          receiverId: receiverId,
          receiverName: traveler.displayName,
          receiverLocation: traveler.currentLocation,
          message: message.isNotEmpty ? message : null,
        );

        // Update tracking
        _waveSentMap[receiverId] = true;
        _waveStatusMap[receiverId] = 'pending';
        setState(() {}); // Refresh UI to show updated button

        // Show success message
        _showSnackBar(
          'Wave sent to ${traveler.displayName}!',
          AppColors.primary,
        );
      }
    } catch (e) {
      print('Failed to send wave: $e');
      _showSnackBar('Failed to send wave: ${e.toString()}', AppColors.error);
    }
  }

  Future<String?> _showWaveDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.waving_hand, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Send Wave',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect with fellow traveler',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.textFieldBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: controller,
                maxLines: 4,
                maxLength: 200,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a personal message...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Cancel',
                  isTextOnly: true,
                  textColor: AppColors.textSecondary,
                  isFullWidth: true,
                  height: 48,
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'Send Wave',
                  icon: Icons.waving_hand,
                  isGradient: true,
                  isFullWidth: true,
                  height: 48,
                  onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Check if user has completed profile setup
  Future<bool> _checkProfileSetup() async {
    // Use strict verification to ensure required fields are actually filled
    final hasCompleted = await UserSetupService.isProfileStrictlyComplete();
    if (!hasCompleted) {
      if (!mounted) return false;

      // Use the existing SetupReminderPopup
      await UserSetupService.showSetupPopup(context);
      return false;
    }
    return true;
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.highlight2.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.highlight2.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.highlight2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // old header removed per redesign

  // quick action button removed per redesign

  // quick actions removed per redesign

  // quick action card removed per redesign

  Widget _buildBottomNavigationBar() {
    return StreamBuilder<int>(
      stream: _waveService.getPendingReceivedWavesCount(),
      builder: (context, waveSnapshot) {
        final wavesCount = waveSnapshot.data ?? 0;

        return StreamBuilder<int>(
          stream: _chatService.getTotalUnreadCount(),
          builder: (context, chatSnapshot) {
            final unreadCount = chatSnapshot.data ?? 0;

            return StreamBuilder<int>(
              stream: _meetupService.getPendingHostRequestsCount(),
              builder: (context, meetupSnapshot) {
                final meetupRequestsCount = meetupSnapshot.data ?? 0;

                return BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: _selectedIndex,
                  onTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });

                    // Clear wave tracking when switching back to home screen
                    // This ensures wave status is refreshed after any changes in waves screen
                    if (index == 0) {
                      _clearWaveTracking();
                    }
                  },
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: AppColors.primaryText,
                  backgroundColor: AppColors.background,
                  elevation: 8,
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.groups_rounded),
                      label: 'Travelers',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildWavesIconWithBadge(wavesCount),
                      label: 'Waves',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildMeetupsIconWithBadge(meetupRequestsCount),
                      label: 'Meetups',
                    ),
                    BottomNavigationBarItem(
                      icon: _buildChatIconWithBadge(unreadCount),
                      label: 'Chat',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.article_rounded),
                      label: 'Blogs',
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWavesIconWithBadge(int wavesCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.electric_bolt_rounded),
        if (wavesCount > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              width: 20,
              height: 20,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.cta1,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                wavesCount > 99 ? '99+' : wavesCount.toString(),
                style: TextStyle(
                  color: AppColors.text1,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMeetupsIconWithBadge(int requestsCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.event_available_rounded),
        if (requestsCount > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              width: 20,
              height: 20,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.highlight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                requestsCount > 99 ? '99+' : requestsCount.toString(),
                style: TextStyle(
                  color: AppColors.text1,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatIconWithBadge(int unreadCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.chat_rounded),
        if (unreadCount > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              width: 20,
              height: 20,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: TextStyle(
                  color: AppColors.text1,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
