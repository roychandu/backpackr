// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:backpackr/features/chat/controllers/suggest_meetup_controller.dart';
import 'package:backpackr/shared/widgets/app_colors.dart';
import 'package:backpackr/shared/widgets/app_text_styles.dart';
import 'package:backpackr/features/meetups/models/meetup.dart';
import 'package:backpackr/features/meetups/views/meetup_details_screen.dart';

class SuggestMeetupBottomSheet extends StatefulWidget {
  const SuggestMeetupBottomSheet({super.key});

  @override
  State<SuggestMeetupBottomSheet> createState() =>
      _SuggestMeetupBottomSheetState();
}

class _SuggestMeetupBottomSheetState extends State<SuggestMeetupBottomSheet> {
  final SuggestMeetupController _controller = SuggestMeetupController();

  @override
  void initState() {
    super.initState();
    _controller.loadNearbyMeetups();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
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
                child: _controller.isLoading
                    ? _buildLoadingState()
                    : _controller.errorMessage != null
                    ? _buildErrorState()
                    : _controller.nearbyMeetups.isEmpty
                    ? _buildEmptyState()
                    : _buildMeetupsList(),
              ),
            ],
          ),
        );
      },
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
              _controller.errorMessage ?? 'Something went wrong',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _controller.loadNearbyMeetups,
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
      itemCount: _controller.nearbyMeetups.length,
      itemBuilder: (context, index) {
        final meetup = _controller.nearbyMeetups[index];
        return _buildMeetupCard(meetup);
      },
    );
  }

  Widget _buildMeetupCard(Meetup meetup) {
    // Get the organizer's distance that was calculated earlier
    final distance = _controller.organizerDistances[meetup.id];

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
                    Icon(
                      Icons.location_on,
                      color: AppColors.text3.withOpacity(0.38),
                      size: 18,
                    ),
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
