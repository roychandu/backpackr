// ignore_for_file: avoid_print, use_build_context_synchronously, avoid_unnecessary_containers, deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:backpackr/shared/widgets/app_colors.dart';
import 'package:backpackr/shared/widgets/app_text_styles.dart';
import 'package:backpackr/shared/widgets/custom_button.dart';
import 'package:backpackr/features/meetups/controllers/meetups_controller.dart';
import 'package:backpackr/features/meetups/models/meetup.dart';
import 'package:backpackr/core/utils/error_handler.dart';
import 'package:backpackr/features/meetups/views/create_meetup_screen.dart';
import 'package:backpackr/features/meetups/views/meetup_details_screen.dart';
import 'package:backpackr/shared/widgets/app_header.dart';
import 'package:backpackr/shared/widgets/sliver_tab_delegate.dart';

class MeetupsScreen extends StatefulWidget {
  const MeetupsScreen({super.key});

  @override
  State<MeetupsScreen> createState() => _MeetupsScreenState();
}

class _MeetupsScreenState extends State<MeetupsScreen>
    with SingleTickerProviderStateMixin {
  final MeetupsController _meetupsController = MeetupsController();
  List<Meetup> _meetups = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;
  double? _userLatitude;
  double? _userLongitude;
  Set<String> _reportedUserIds = <String>{};
  Set<String> _hiddenUserIds = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes
    });
    _loadUserLocation();
    _loadMeetups();
    _loadReportedUsers();
    _loadHiddenUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _meetupsController.dispose();
    super.dispose();
  }

  Future<void> _loadReportedUsers() async {
    try {
      final uid = _meetupsController.currentUserId;
      if (uid == null) return;
      final reported = await _meetupsController.getReportedUsers(uid);
      if (!mounted) return;
      setState(() {
        _reportedUserIds = reported;
      });
    } catch (_) {}
  }

  Future<void> _loadHiddenUsers() async {
    try {
      final uid = _meetupsController.currentUserId;
      if (uid == null) return;
      final hidden = await _meetupsController.getHiddenUsers(uid);
      if (!mounted) return;
      setState(() {
        _hiddenUserIds = hidden;
      });
    } catch (_) {}
  }

  Future<void> _loadUserLocation() async {
    try {
      final position = await _meetupsController.getCurrentUserLocation();
      if (position != null && mounted) {
        setState(() {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  // Haversine distance calculation in kilometers
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

  List<Meetup> _filterByDistance(List<Meetup> meetups) {
    // If user location is not available, return all meetups
    if (_userLatitude == null || _userLongitude == null) {
      return meetups;
    }

    // Filter meetups within 200km based on organizer's (host) location
    // Note: meetup.latitude/longitude represent the organizer's location, not event location
    return meetups.where((meetup) {
      if (meetup.latitude == null || meetup.longitude == null) {
        return false; // Exclude meetups without organizer location
      }

      // Calculate distance from user's location to organizer's location
      final distance = _distanceKm(
        _userLatitude!,
        _userLongitude!,
        meetup.latitude!, // Organizer's latitude
        meetup.longitude!, // Organizer's longitude
      );

      return distance <= 200.0;
    }).toList();
  }

  Future<void> _loadMeetups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final meetups = await _meetupsController.getAllMeetups();
      setState(() {
        _meetups = meetups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getFriendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _requestToJoinMeetup(Meetup meetup) async {
    // Check if user has completed profile setup
    if (!await _checkProfileSetup()) {
      return;
    }

    try {
      await _meetupsController.requestToJoinMeetup(meetup.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Join request sent for "${meetup.title}"!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Reload meetups to show updated status
      _loadMeetups();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _cancelJoinRequest(Meetup meetup) async {
    try {
      await _meetupsController.cancelJoinRequest(meetup.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Join request cancelled for "${meetup.title}"'),
          backgroundColor: AppColors.cta1,
        ),
      );

      // Reload meetups to show updated status
      _loadMeetups();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  List<Meetup> get _myMeetups {
    final userId = _meetupsController.currentUserId;
    if (userId == null) return [];

    final filteredMeetups = _meetups.where((meetup) {
      final isMine =
          meetup.hostId == userId || meetup.attendeeIds.contains(userId);
      if (!isMine && _reportedUserIds.contains(meetup.hostId)) return false;
      return isMine;
    }).toList();

    // Apply 200km distance filter
    return _filterByDistance(filteredMeetups);
  }

  // All meetups (no distance filter), excluding reported hosts
  List<Meetup> get _allMeetups {
    return _meetups
        .where((m) => !_reportedUserIds.contains(m.hostId))
        .where((m) => !_hiddenUserIds.contains(m.hostId))
        .toList();
  }

  // Near me meetups (within 200km), excluding reported hosts
  List<Meetup> get _nearMeMeetups {
    final list = _meetups
        .where((m) => !_reportedUserIds.contains(m.hostId))
        .where((m) => !_hiddenUserIds.contains(m.hostId))
        .toList();
    return _filterByDistance(list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildHeader(context), _buildNotificationsSection()],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: SliverTabDelegate(
                child: Container(
                  width: double.infinity,
                  color: AppColors.background,
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
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

                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.public, size: 20),
                            const SizedBox(width: 8),
                            Text('All Meetups (${_allMeetups.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.near_me, size: 20),
                            const SizedBox(width: 8),
                            Text('Near Me Meetups (${_nearMeMeetups.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_outline, size: 20),
                            const SizedBox(width: 8),
                            Text('My Meetups (${_myMeetups.length})'),
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
          controller: _tabController,
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await _loadUserLocation();
                await _loadMeetups();
                await _loadReportedUsers();
                await _loadHiddenUsers();
              },
              child: _buildMeetupsList(_allMeetups),
            ),
            RefreshIndicator(
              onRefresh: () async {
                await _loadUserLocation();
                await _loadMeetups();
                await _loadReportedUsers();
                await _loadHiddenUsers();
              },
              child: _buildMeetupsList(_nearMeMeetups),
            ),
            RefreshIndicator(
              onRefresh: () async {
                await _loadUserLocation();
                await _loadMeetups();
                await _loadReportedUsers();
                await _loadHiddenUsers();
              },
              child: _buildMeetupsList(_myMeetups),
            ),
          ],
        ),
      ),
      floatingActionButton: _shouldShowFAB()
          ? FloatingActionButton(
              onPressed: _showCreateMeetupDialog,
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              child: Icon(Icons.add, color: AppColors.text1),
            )
          : null,
    );
  }

  bool _shouldShowFAB() {
    // Always show FAB on all tabs, independent of tab selection or content
    return true;
  }

  Widget _buildMeetupsList(List<Meetup> meetups) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (meetups.isEmpty) {
      return _buildEmptyWidget();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meetups.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _meetupCard(meetups[index]),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppHeader(
      title: 'Meetups',
      subtitle: 'Join or create amazing experiences',
      additionalSubtitle:
          '${_myMeetups.length + _allMeetups.length} upcoming events',
    );
  }

  Widget _buildErrorWidget() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error loading meetups', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Something went wrong',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.text3.withOpacity(0.54),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadMeetups,
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
      ),
    );
  }

  Widget _buildEmptyWidget() {
    final idx = _tabController.index;
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final imageSize = math.min(screenWidth, screenHeight) * 0.4;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              SizedBox(
                width: imageSize,
                height: imageSize,
                child: Image.asset(
                  'assets/meetup-empty.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                idx == 0
                    ? 'No meetups yet'
                    : idx == 1
                    ? 'No meetups available'
                    : 'No nearby meetups',
                style: AppTextStyles.h4.copyWith(color: AppColors.primaryText),
              ),
              const SizedBox(height: 8),
              Text(
                idx == 0
                    ? 'Join or create a meetup to see your meetups here!'
                    : idx == 1
                    ? 'Be the first to create a meetup!'
                    : 'Try expanding your area or check back later',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: idx == 0 ? 'Create your Meetup' : 'Create Meetup',
                backgroundColor: AppColors.primary,
                icon: Icons.add,
                onPressed: _showCreateMeetupDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateMeetupDialog() async {
    // Check if user has completed profile setup
    if (!await _checkProfileSetup()) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMeetupScreen(
          onMeetupCreated: () {
            _loadMeetups();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Meetup created successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _meetupsController.getMeetupNotificationsStream(),
      builder: (context, snapshot) {
        print(
          'Notifications StreamBuilder rebuild: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, dataLength=${snapshot.data?.length ?? 0}',
        );

        // Show error if stream has error
        if (snapshot.hasError) {
          print('StreamBuilder error: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error loading notifications: ${snapshot.error}'),
          );
        }

        // Don't show anything while waiting for first data
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('StreamBuilder waiting for initial data');
          return const SizedBox.shrink();
        }

        // Hide section if no notifications
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print('No notifications to display');
          return const SizedBox.shrink();
        }

        final notifications = snapshot.data!;
        print('Displaying ${notifications.length} notifications');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: AppColors.highlight,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Notifications',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  CustomButton(
                    text: 'Clear All',
                    isTextOnly: true,
                    textColor: AppColors.primary,
                    onPressed: () async {
                      await _meetupsController.clearMeetupNotifications();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...notifications.map((notification) {
                final type = notification['type'] as String;
                final title = notification['meetupTitle'] as String;
                final notificationId = notification['id'] as String;
                final timestamp = DateTime.parse(
                  notification['timestamp'] as String,
                );
                final timeAgo = _getTimeAgo(timestamp);

                Color bgColor;
                Color iconColor;
                IconData icon;
                String message;

                switch (type) {
                  case 'approved':
                    bgColor = AppColors.success.withOpacity(0.1);
                    iconColor = AppColors.success;
                    icon = Icons.check_circle_rounded;
                    message = 'Your request to join "$title" was approved!';
                    break;
                  case 'rejected':
                    bgColor = AppColors.error.withOpacity(0.1);
                    iconColor = AppColors.error;
                    icon = Icons.cancel_rounded;
                    message = 'Your request to join "$title" was declined';
                    break;
                  case 'removed':
                    bgColor = AppColors.cta1.withOpacity(0.1);
                    iconColor = AppColors.cta1;
                    icon = Icons.person_remove_rounded;
                    message = 'You were removed from "$title"';
                    break;
                  case 'new_request':
                    bgColor = AppColors.info.withOpacity(0.1);
                    iconColor = AppColors.info;
                    icon = Icons.person_add_rounded;
                    final requesterName =
                        notification['requesterName'] as String? ?? 'Someone';
                    message = '$requesterName requested to join "$title"';
                    break;
                  case 'attendee_left':
                    bgColor = AppColors.cta1.withOpacity(0.1);
                    iconColor = AppColors.cta1;
                    icon = Icons.exit_to_app_rounded;
                    final attendeeName =
                        notification['attendeeName'] as String? ?? 'Someone';
                    message = '$attendeeName left "$title"';
                    break;
                  case 'request_cancelled':
                    bgColor = AppColors.textSecondary.withOpacity(0.1);
                    iconColor = AppColors.textSecondary;
                    icon = Icons.cancel_outlined;
                    final cancelledName =
                        notification['requesterName'] as String? ?? 'Someone';
                    message =
                        '$cancelledName cancelled their request for "$title"';
                    break;
                  default:
                    bgColor = AppColors.textSecondary.withOpacity(0.1);
                    iconColor = AppColors.textSecondary;
                    icon = Icons.info_rounded;
                    message = 'Update about "$title"';
                }

                return Dismissible(
                  key: Key(notificationId),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) async {
                    await _meetupsController.deleteNotification(notificationId);
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete_rounded, color: AppColors.text1),
                  ),
                  child: GestureDetector(
                    onTap: type == 'new_request'
                        ? () async {
                            final meetupId =
                                notification['meetupId'] as String?;
                            if (meetupId != null && meetupId.isNotEmpty) {
                              final meetup = await _meetupsController
                                  .getMeetupById(meetupId);
                              if (!mounted) return;
                              if (meetup != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MeetupDetailsScreen(meetup: meetup),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Meetup not found'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: iconColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: iconColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: AppColors.text1, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeAgo,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primaryText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  Widget _meetupCard(Meetup meetup) {
    final isAttending = meetup.attendeeIds.contains(
      _meetupsController.currentUserId,
    );
    final isHost = meetup.hostId == _meetupsController.currentUserId;
    final isFull = meetup.isFull;
    final isPast = meetup.isPast;
    final hasPendingRequest = meetup.pendingRequests.contains(
      _meetupsController.currentUserId,
    );
    final bool showUserActions =
        !isHost &&
        (_tabController.index == 0 ||
            _tabController.index == 1 ||
            _tabController.index == 2);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MeetupDetailsScreen(meetup: meetup),
          ),
        ).then((_) {
          // Refresh the meetups list when returning from details screen
          _loadMeetups();
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.text3.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
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
                    color: _getCategoryColor(meetup.category).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    meetup.categoryDisplayName,
                    style: TextStyle(color: _getCategoryColor(meetup.category)),
                  ),
                ),
                const Spacer(),
                if (showUserActions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz,
                        color: AppColors.text3.withOpacity(0.54),
                      ),
                      onSelected: (value) {
                        if (value == 'report') {
                          _onReportUser(meetup);
                        } else if (value == 'block') {
                          _onBlockUser(meetup);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag_outlined, color: AppColors.error),
                              SizedBox(width: 10),
                              Text('Report user'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(
                                Icons.block,
                                color: AppColors.text3.withOpacity(0.87),
                              ),
                              SizedBox(width: 10),
                              Text('Block user'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Icon(
                  Icons.group_outlined,
                  color: AppColors.text3.withOpacity(0.45),
                ),
                const SizedBox(width: 4),
                Text(
                  meetup.capacityDisplay,
                  style: TextStyle(
                    color: isFull
                        ? AppColors.error
                        : AppColors.text3.withOpacity(0.45),
                    fontWeight: isFull ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              meetup.title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.text3.withOpacity(0.87),
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              meetup.description,
              style: TextStyle(color: AppColors.text3.withOpacity(0.54)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.event_available,
                  color: AppColors.text3.withOpacity(0.38),
                  size: 20,
                ),
                const SizedBox(width: 8),
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
                Icon(
                  Icons.location_on,
                  color: AppColors.text3.withOpacity(0.38),
                  size: 20,
                ),
                const SizedBox(width: 8),
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
                const Text('Hosted by  ', style: TextStyle(fontSize: 13)),
                Text(
                  meetup.hostName,
                  style: TextStyle(
                    color: _getCategoryColor(meetup.category),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (isHost)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.highlight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'YOU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.highlight,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: isHost
                  ? 'You\'re the host'
                  : isPast
                  ? 'Event ended'
                  : isAttending
                  ? 'Leave Meetup'
                  : hasPendingRequest
                  ? 'Request Sent (Cancel)'
                  : isFull
                  ? 'Full'
                  : 'Request to Join',
              backgroundColor: isAttending
                  ? AppColors.textSecondary
                  : isPast
                  ? AppColors.textSecondary
                  : hasPendingRequest
                  ? AppColors.cta1
                  : AppColors.primary,
              isFullWidth: true,
              height: 44,
              onPressed: isHost
                  ? null
                  : isPast
                  ? null
                  : isAttending
                  ? () => _leaveMeetup(meetup)
                  : hasPendingRequest
                  ? () => _cancelJoinRequest(meetup)
                  : isFull
                  ? null
                  : () => _requestToJoinMeetup(meetup),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onReportUser(Meetup meetup) async {
    final userId = _meetupsController.currentUserId;
    if (userId == null) return;

    final TextEditingController reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report user'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tell us why you are reporting this user.'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            CustomButton(
              text: 'Cancel',
              isTextOnly: true,
              onPressed: () => Navigator.pop(context),
            ),
            CustomButton(
              text: 'Submit',
              backgroundColor: AppColors.primary,
              onPressed: () {
                Navigator.pop(context, reasonController.text.trim());
              },
            ),
          ],
        );
      },
    );

    if (reason == null) return;

    try {
      await _meetupsController.reportUser(
        reportedUserId: meetup.hostId,
        reporterUserId: userId,
        reason: reason.isEmpty ? 'Reported from meetups screen' : reason,
      );

      // Immediately hide reported user's meetups from All/Near Me
      setState(() {
        _reportedUserIds = {..._reportedUserIds, meetup.hostId};
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User reported. Thank you for the feedback.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.cta1,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _onBlockUser(Meetup meetup) async {
    final userId = _meetupsController.currentUserId;
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block user'),
        content: const Text(
          'You will no longer see meetups from this user. Continue?',
        ),
        actions: [
          CustomButton(
            text: 'Cancel',
            isTextOnly: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          CustomButton(
            text: 'Block',
            backgroundColor: AppColors.error,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _meetupsController.hideTravelerForUser(
        userId: userId,
        travelerId: meetup.hostId,
      );

      setState(() {
        _hiddenUserIds = {..._hiddenUserIds, meetup.hostId};
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User blocked. You will not see their meetups.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _leaveMeetup(Meetup meetup) async {
    try {
      await _meetupsController.leaveMeetup(meetup.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Left "${meetup.title}"'),
          backgroundColor: AppColors.cta1,
        ),
      );

      // Reload meetups to show updated attendee count
      _loadMeetups();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
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

  /// Check if user has completed profile setup
  Future<bool> _checkProfileSetup() async {
    final hasCompleted = await _meetupsController.isProfileStrictlyComplete();
    if (!hasCompleted) {
      if (!mounted) return false;

      // Use the existing SetupReminderPopup
      await _meetupsController.showSetupPopup(context);
      return false;
    }
    return true;
  }
}
