// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../common_widgets/app_colors.dart';
import '../../common_widgets/app_text_styles.dart';
import '../../common_widgets/custom_button.dart';
import '../../models/meetup.dart';
import '../../services/meetup_service.dart';
import '../../utils/error_handler.dart';
import '../traveling_blogs_screen/other_travelers_blog_screen.dart';
import 'edit_meetup_screen.dart';

class MeetupDetailsScreen extends StatefulWidget {
  final Meetup meetup;

  const MeetupDetailsScreen({super.key, required this.meetup});

  @override
  State<MeetupDetailsScreen> createState() => _MeetupDetailsScreenState();
}

class _MeetupDetailsScreenState extends State<MeetupDetailsScreen>
    with SingleTickerProviderStateMixin {
  final MeetupService _meetupService = MeetupService();
  List<Map<String, dynamic>> _attendees = [];
  List<Map<String, dynamic>> _pendingRequestUsers = [];
  bool _isLoading = true;
  bool _isLoadingRequests = true;
  bool _isProcessing = false;
  late Meetup _currentMeetup;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _currentMeetup = widget.meetup;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadAttendees();
    _loadPendingRequests();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final attendees = await _meetupService.getAttendeesData(
        _currentMeetup.attendeeIds,
      );
      setState(() {
        _attendees = attendees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPendingRequests() async {
    setState(() {
      _isLoadingRequests = true;
    });

    try {
      final pendingUsers = await _meetupService.getAttendeesData(
        _currentMeetup.pendingRequests,
      );
      setState(() {
        _pendingRequestUsers = pendingUsers;
        _isLoadingRequests = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRequests = false;
      });
    }
  }

  Future<void> _refreshMeetup() async {
    final meetup = await _meetupService.getMeetupById(_currentMeetup.id);
    if (meetup != null && mounted) {
      setState(() {
        _currentMeetup = meetup;
      });
      _loadAttendees();
      _loadPendingRequests();
    }
  }

  Future<void> _requestToJoinMeetup() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _meetupService.requestToJoinMeetup(_currentMeetup.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.send, color: AppColors.text1),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Join request sent for "${_currentMeetup.title}"!'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      await _refreshMeetup();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _cancelJoinRequest() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _meetupService.cancelJoinRequest(_currentMeetup.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.cancel, color: AppColors.text1),
              const SizedBox(width: 12),
              const Expanded(child: Text('Join request cancelled')),
            ],
          ),
          backgroundColor: AppColors.cta1,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      await _refreshMeetup();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _approveJoinRequest(String userId, String userName) async {
    try {
      await _meetupService.approveJoinRequest(_currentMeetup.id, userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approved $userName to join the meetup!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      await _refreshMeetup();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _rejectJoinRequest(String userId, String userName) async {
    try {
      await _meetupService.rejectJoinRequest(_currentMeetup.id, userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rejected $userName\'s join request'),
          backgroundColor: AppColors.cta1,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      await _refreshMeetup();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _removeAttendee(String userId, String userName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Attendee'),
        content: Text(
          'Are you sure you want to remove $userName from this meetup?',
        ),
        actions: [
          CustomButton(
            text: 'Cancel',
            isTextOnly: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CustomButton(
            text: 'Remove',
            isTextOnly: true,
            textColor: AppColors.error,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _meetupService.removeAttendee(_currentMeetup.id, userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed $userName from the meetup'),
          backgroundColor: AppColors.cta1,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      await _refreshMeetup();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _leaveMeetup() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _meetupService.leaveMeetup(_currentMeetup.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.text1),
              const SizedBox(width: 12),
              Expanded(child: Text('Left "${_currentMeetup.title}"')),
            ],
          ),
          backgroundColor: AppColors.cta1,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      await _refreshMeetup();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _showEditMeetupDialog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMeetupScreen(
          meetup: _currentMeetup,
          onMeetupUpdated: () async {
            await _refreshMeetup();
          },
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            Text(
              'Delete Meetup',
              style: AppTextStyles.h4.copyWith(color: AppColors.text1),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${_currentMeetup.title}"? This action cannot be undone and all attendees will be notified.',
          style: TextStyle(color: AppColors.text1.withOpacity(0.70)),
        ),
        actions: [
          CustomButton(
            text: 'Cancel',
            isTextOnly: true,
            textColor: AppColors.text1.withOpacity(0.70),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CustomButton(
            text: 'Delete',
            backgroundColor: AppColors.error,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteMeetup();
    }
  }

  Future<void> _deleteMeetup() async {
    try {
      await _meetupService.cancelMeetup(_currentMeetup.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meetup deleted successfully'),
          backgroundColor: AppColors.cta1,
        ),
      );

      // Navigate back to meetups screen
      Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final isHost = _currentMeetup.hostId == _meetupService.currentUserId;
    final isAttending = _currentMeetup.attendeeIds.contains(
      _meetupService.currentUserId,
    );
    final isFull = _currentMeetup.isFull;
    final isPast = _currentMeetup.isPast;
    final hasPendingRequest = _currentMeetup.pendingRequests.contains(
      _meetupService.currentUserId,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildUnifiedDetailsCard(),
                  const SizedBox(height: 20),
                  if (isHost && _currentMeetup.pendingRequests.isNotEmpty)
                    _buildPendingRequestsCard(),
                  if (isHost && _currentMeetup.pendingRequests.isNotEmpty)
                    const SizedBox(height: 20),
                  _buildAttendeesCard(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildActionButton(
        isHost,
        isAttending,
        isFull,
        isPast,
        hasPendingRequest,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final isHost = _currentMeetup.hostId == _meetupService.currentUserId;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _getCategoryColor(_currentMeetup.category),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.text1.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text1),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: isHost
          ? [
              // Edit button
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.text1.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.edit_rounded, color: AppColors.text1),
                  onPressed: _showEditMeetupDialog,
                  tooltip: 'Edit Meetup',
                ),
              ),
              // Delete button
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.text1.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.delete_rounded, color: AppColors.text1),
                  onPressed: _showDeleteConfirmation,
                  tooltip: 'Delete Meetup',
                ),
              ),
            ]
          : null,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getCategoryColor(_currentMeetup.category),
                    _getCategoryColor(_currentMeetup.category).withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _CirclePatternPainter()),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.text1.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(_currentMeetup.category),
                      size: 50,
                      color: AppColors.text1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.text1.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.text1.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _currentMeetup.categoryDisplayName.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.text1,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.text1, AppColors.text1.withOpacity(0.95)],
        ),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor(_currentMeetup.category).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.text1.withOpacity(0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _currentMeetup.title,
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor(_currentMeetup.category),
                            _getCategoryColor(
                              _currentMeetup.category,
                            ).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getCategoryColor(
                              _currentMeetup.category,
                            ).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group, size: 16, color: AppColors.text1),
                          const SizedBox(width: 6),
                          Text(
                            _currentMeetup.capacityDisplay,
                            style: TextStyle(
                              color: AppColors.text1,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_currentMeetup.isFull) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MEETUP FULL',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_currentMeetup.isPast) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.textSecondary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'EVENT ENDED',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),

                // Description
                Text(
                  'About This Meetup',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _currentMeetup.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.background,
                    height: 1.6,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 24),

                // Date & Time Info Card
                _buildInfoRow(
                  Icons.calendar_today_rounded,
                  'Date & Time',
                  _currentMeetup.formattedDateTime,
                  _getCategoryColor(_currentMeetup.category),
                ),
                const SizedBox(height: 16),

                // Location Info Card
                _buildInfoRow(
                  Icons.location_on_rounded,
                  'Location',
                  _currentMeetup.location,
                  _getCategoryColor(_currentMeetup.category),
                ),

                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 20),

                // Host Section
                Text(
                  'Organized by',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OtherTravelersBlogScreen(
                          userId: _currentMeetup.hostId,
                          userName: _currentMeetup.hostName,
                          avatarUrl: _currentMeetup.hostAvatarUrl,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getCategoryColor(
                            _currentMeetup.category,
                          ).withOpacity(0.08),
                          _getCategoryColor(
                            _currentMeetup.category,
                          ).withOpacity(0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getCategoryColor(
                          _currentMeetup.category,
                        ).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: _getCategoryColor(
                                _currentMeetup.category,
                              ).withOpacity(0.2),
                              backgroundImage:
                                  _currentMeetup.hostAvatarUrl != null
                                  ? NetworkImage(_currentMeetup.hostAvatarUrl!)
                                  : null,
                              child: _currentMeetup.hostAvatarUrl == null
                                  ? Text(
                                      _currentMeetup.hostName[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: _getCategoryColor(
                                          _currentMeetup.category,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.highlight,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.text1,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.star,
                                  size: 12,
                                  color: AppColors.text1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentMeetup.hostName,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.background,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Meetup Host',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.background,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_currentMeetup.hostId ==
                            _meetupService.currentUserId)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.highlight,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.highlight.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'YOU',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text1,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.text1, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.highlight.withOpacity(0.08),
            AppColors.highlight.withOpacity(0.03),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.highlight.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.text1.withOpacity(0.95),
              border: Border.all(
                color: AppColors.highlight.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.highlight, AppColors.cta1],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.highlight.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.pending_actions,
                        color: AppColors.text1,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pending Requests',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.highlight.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentMeetup.pendingRequests.length}',
                        style: const TextStyle(
                          color: AppColors.highlight,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isLoadingRequests)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: AppColors.highlight,
                      ),
                    ),
                  )
                else if (_pendingRequestUsers.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No pending requests',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.text3.withOpacity(0.54),
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: _pendingRequestUsers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final user = entry.value;

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OtherTravelersBlogScreen(
                                userId: user['userId'],
                                userName: user['displayName'] ?? 'Guest User',
                                currentLocation: user['location'],
                                avatarUrl: user['avatarUrl'],
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: index < _pendingRequestUsers.length - 1
                                ? 12
                                : 0,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.highlight.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.highlight.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppColors.highlight
                                        .withOpacity(0.2),
                                    backgroundImage: user['avatarUrl'] != null
                                        ? NetworkImage(user['avatarUrl'])
                                        : null,
                                    child: user['avatarUrl'] == null
                                        ? Text(
                                            ((user['displayName'] is String
                                                        ? (user['displayName']
                                                                  as String)
                                                              .trim()
                                                        : '')
                                                    .isNotEmpty
                                                ? (user['displayName']
                                                          as String)
                                                      .trim()
                                                      .characters
                                                      .first
                                                      .toUpperCase()
                                                : 'G'),
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.highlight,
                                            ),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: AppColors.highlight,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.text1,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.hourglass_empty,
                                        size: 10,
                                        color: AppColors.text1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['displayName'] ?? 'Guest User',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.text3.withOpacity(
                                          0.87,
                                        ),
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (user['location'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 12,
                                              color: AppColors.text3
                                                  .withOpacity(0.45),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                user['location'],
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      color: AppColors.text3
                                                          .withOpacity(0.54),
                                                      fontSize: 13,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _rejectJoinRequest(
                                      user['userId'],
                                      user['displayName'] ?? 'User',
                                    ),
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: AppColors.error,
                                      size: 28,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.error
                                          .withOpacity(0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    tooltip: 'Reject',
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _approveJoinRequest(
                                      user['userId'],
                                      user['displayName'] ?? 'User',
                                    ),
                                    icon: Icon(
                                      Icons.check_rounded,
                                      color: AppColors.success,
                                      size: 28,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.success
                                          .withOpacity(0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    tooltip: 'Approve',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendeesCard() {
    final isViewerHost = _currentMeetup.hostId == _meetupService.currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor(_currentMeetup.category).withOpacity(0.05),
            _getCategoryColor(_currentMeetup.category).withOpacity(0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.text3.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.text1.withOpacity(0.9),
              border: Border.all(
                color: _getCategoryColor(
                  _currentMeetup.category,
                ).withOpacity(0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getCategoryColor(_currentMeetup.category),
                                _getCategoryColor(
                                  _currentMeetup.category,
                                ).withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _getCategoryColor(
                                  _currentMeetup.category,
                                ).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.people_rounded,
                            color: AppColors.text1,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Attendees',
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.background,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          _currentMeetup.category,
                        ).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentMeetup.currentAttendees}',
                        style: TextStyle(
                          color: _getCategoryColor(_currentMeetup.category),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: _getCategoryColor(_currentMeetup.category),
                      ),
                    ),
                  )
                else if (_attendees.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppColors.text3.withOpacity(0.26),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No attendees yet',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.text3.withOpacity(0.54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: _attendees.asMap().entries.map((entry) {
                      final index = entry.key;
                      final attendee = entry.value;
                      final isCurrentUser =
                          attendee['userId'] == _meetupService.currentUserId;
                      final isHost =
                          attendee['userId'] == _currentMeetup.hostId;
                      final canRemove = isViewerHost && !isHost;

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OtherTravelersBlogScreen(
                                userId: attendee['userId'],
                                userName:
                                    attendee['displayName'] ?? 'Guest User',
                                currentLocation: attendee['location'],
                                avatarUrl: attendee['avatarUrl'],
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: index < _attendees.length - 1 ? 12 : 0,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isCurrentUser
                                ? AppColors.success.withOpacity(0.08)
                                : isHost
                                ? _getCategoryColor(
                                    _currentMeetup.category,
                                  ).withOpacity(0.08)
                                : AppColors.text1,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrentUser
                                  ? AppColors.success.withOpacity(0.3)
                                  : isHost
                                  ? _getCategoryColor(
                                      _currentMeetup.category,
                                    ).withOpacity(0.3)
                                  : AppColors.text3.withOpacity(0.06),
                              width: 1,
                            ),
                            boxShadow: [
                              if (isCurrentUser || isHost)
                                BoxShadow(
                                  color:
                                      (isCurrentUser
                                              ? AppColors.success
                                              : _getCategoryColor(
                                                  _currentMeetup.category,
                                                ))
                                          .withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: isHost
                                        ? _getCategoryColor(
                                            _currentMeetup.category,
                                          ).withOpacity(0.2)
                                        : AppColors.primary.withOpacity(0.2),
                                    backgroundImage:
                                        attendee['avatarUrl'] != null
                                        ? NetworkImage(attendee['avatarUrl'])
                                        : null,
                                    child: attendee['avatarUrl'] == null
                                        ? Text(
                                            ((attendee['displayName'] is String
                                                        ? (attendee['displayName']
                                                                  as String)
                                                              .trim()
                                                        : '')
                                                    .isNotEmpty
                                                ? (attendee['displayName']
                                                          as String)
                                                      .trim()
                                                      .characters
                                                      .first
                                                      .toUpperCase()
                                                : 'G'),
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isHost
                                                  ? _getCategoryColor(
                                                      _currentMeetup.category,
                                                    )
                                                  : AppColors.primary,
                                            ),
                                          )
                                        : null,
                                  ),
                                  if (isHost || isCurrentUser)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: isHost
                                              ? _getCategoryColor(
                                                  _currentMeetup.category,
                                                )
                                              : AppColors.success,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.text1,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          isHost ? Icons.star : Icons.check,
                                          size: 10,
                                          color: AppColors.text1,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      attendee['displayName'] ?? 'Guest User',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.text3.withOpacity(
                                          0.87,
                                        ),
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (attendee['location'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 12,
                                              color: AppColors.text3
                                                  .withOpacity(0.45),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                attendee['location'],
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      color: AppColors.text3
                                                          .withOpacity(0.54),
                                                      fontSize: 13,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isHost)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _getCategoryColor(
                                          _currentMeetup.category,
                                        ),
                                        _getCategoryColor(
                                          _currentMeetup.category,
                                        ).withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getCategoryColor(
                                          _currentMeetup.category,
                                        ).withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'HOST',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text1,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                )
                              else if (isCurrentUser)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.success.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'YOU',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text1,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                )
                              else if (canRemove)
                                IconButton(
                                  onPressed: () => _removeAttendee(
                                    attendee['userId'],
                                    attendee['displayName'] ?? 'User',
                                  ),
                                  icon: Icon(
                                    Icons.person_remove_rounded,
                                    color: AppColors.error,
                                    size: 22,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.error
                                        .withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                  tooltip: 'Remove Attendee',
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    bool isHost,
    bool isAttending,
    bool isFull,
    bool isPast,
    bool hasPendingRequest,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.text1,
        boxShadow: [
          BoxShadow(
            color: AppColors.text3.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: CustomButton(
            text: isHost
                ? 'You\'re the Host'
                : isPast
                ? 'Event Ended'
                : isAttending
                ? 'Leave Meetup'
                : hasPendingRequest
                ? 'Cancel Request'
                : isFull
                ? 'Meetup is Full'
                : 'Request to Join',
            icon: isHost
                ? Icons.star_rounded
                : isPast
                ? Icons.event_busy_rounded
                : isAttending
                ? Icons.exit_to_app_rounded
                : hasPendingRequest
                ? Icons.cancel_rounded
                : isFull
                ? Icons.block_rounded
                : Icons.send_rounded,
            backgroundColor: isAttending
                ? AppColors.cta1
                : hasPendingRequest
                ? AppColors.cta1
                : isHost || isFull || isPast
                ? AppColors.textSecondary.withOpacity(0.6)
                : _getCategoryColor(_currentMeetup.category),
            isFullWidth: true,
            height: 56,
            borderRadius: 16,
            isLoading: _isProcessing,
            onPressed: _isProcessing
                ? null
                : isHost
                ? null
                : isPast
                ? null
                : isAttending
                ? _leaveMeetup
                : hasPendingRequest
                ? _cancelJoinRequest
                : isFull
                ? null
                : _requestToJoinMeetup,
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

  IconData _getCategoryIcon(MeetupCategory category) {
    switch (category) {
      case MeetupCategory.work:
        return Icons.work_rounded;
      case MeetupCategory.culture:
        return Icons.museum_rounded;
      case MeetupCategory.adventure:
        return Icons.hiking_rounded;
      case MeetupCategory.food:
        return Icons.restaurant_rounded;
      case MeetupCategory.nightlife:
        return Icons.nightlife_rounded;
      case MeetupCategory.sports:
        return Icons.sports_soccer_rounded;
      case MeetupCategory.other:
        return Icons.category_rounded;
    }
  }
}

// Custom painter for decorative circles
class _CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.text1.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw decorative circles
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 60, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), 40, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
