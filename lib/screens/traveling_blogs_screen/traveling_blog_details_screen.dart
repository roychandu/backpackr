// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../common_widgets/app_colors.dart';
import '../../common_widgets/app_text_styles.dart';
import '../../models/blog.dart';

class TravelingBlogDetailsScreen extends StatefulWidget {
  final Blog blog;

  const TravelingBlogDetailsScreen({super.key, required this.blog});

  @override
  State<TravelingBlogDetailsScreen> createState() =>
      _TravelingBlogDetailsScreenState();
}

class _TravelingBlogDetailsScreenState extends State<TravelingBlogDetailsScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _typewriterController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _typewriterAnimation;
  Timer? _autoScrollTimer;

  int _currentImageIndex = 0;
  String _displayedContent = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _typewriterController = AnimationController(
      duration: Duration(milliseconds: widget.blog.content.length * 30),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _typewriterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typewriterController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _startTypewriterEffect();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _typewriterController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startTypewriterEffect() {
    _typewriterController.addListener(() {
      if (mounted) {
        final progress = _typewriterAnimation.value;
        final contentLength = widget.blog.content.length;
        final currentLength = (progress * contentLength).round();
        setState(() {
          _displayedContent = widget.blog.content.substring(
            0,
            currentLength.clamp(0, contentLength),
          );
        });
      }
    });
    _typewriterController.forward();
  }

  void _startAutoScroll() {
    if (widget.blog.imageUrls.length <= 1) return;

    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        final nextIndex =
            (_currentImageIndex + 1) % widget.blog.imageUrls.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onImageChanged(int index) {
    setState(() {
      _currentImageIndex = index;
    });
    // Reset auto-scroll timer when user manually swipes
    _startAutoScroll();
  }

  String _formatTravelDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildBlogContent(),
                  const SizedBox(height: 24),
                  _buildTagsSection(),
                  const SizedBox(height: 24),
                  _buildTravelInfo(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.text1.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.text1,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        // Image counter
        if (widget.blog.imageUrls.length > 1)
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.text3.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_currentImageIndex + 1}/${widget.blog.imageUrls.length}',
              style: const TextStyle(
                color: AppColors.text1,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image Gallery
            if (widget.blog.imageUrls.isNotEmpty)
              PageView.builder(
                controller: _pageController,
                onPageChanged: _onImageChanged,
                itemCount: widget.blog.imageUrls.length,
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: widget.blog.imageUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.text1),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.textSecondary.withOpacity(0.4),
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: AppColors.text1,
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                color: AppColors.primary,
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 80,
                    color: AppColors.text1,
                  ),
                ),
              ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.text3.withOpacity(0.7)],
                ),
              ),
            ),

            // Image indicators
            if (widget.blog.imageUrls.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.blog.imageUrls.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentImageIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index
                            ? AppColors.text1
                            : AppColors.text1.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlogContent() {
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
            color: AppColors.primary.withOpacity(0.15),
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
                // Title
                Text(
                  widget.blog.title,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                // Content with typewriter effect
                AnimatedBuilder(
                  animation: _typewriterAnimation,
                  builder: (context, child) {
                    return RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _displayedContent,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.background,
                              height: 1.6,
                              fontSize: 16,
                            ),
                          ),
                          if (_displayedContent.length <
                              widget.blog.content.length)
                            TextSpan(
                              text: '|',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                height: 1.6,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Date
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(widget.blog.dateCreated),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.background,
                        fontWeight: FontWeight.w600,
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

  Widget _buildTravelInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Route info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: AppColors.text1,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Travel Route',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.blog.startPlace} → ${widget.blog.destination}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Travel details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.text1.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Distance and Duration
                  Row(
                    children: [
                      Expanded(
                        child: _buildSimpleInfoItem(
                          icon: Icons.social_distance_rounded,
                          label: 'Distance',
                          value: widget.blog.distance,
                          color: AppColors.info,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                      Expanded(
                        child: _buildSimpleInfoItem(
                          icon: Icons.schedule_rounded,
                          label: 'Duration',
                          value: widget.blog.duration,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),

                  // Divider
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 1,
                    color: AppColors.primary.withOpacity(0.1),
                  ),

                  // Travel dates
                  Row(
                    children: [
                      Expanded(
                        child: _buildSimpleInfoItem(
                          icon: Icons.calendar_today_rounded,
                          label: 'Start Date',
                          value: _formatTravelDate(widget.blog.startDate),
                          color: AppColors.cta1,
                        ),
                      ),
                      if (widget.blog.endDate != null) ...[
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                        Expanded(
                          child: _buildSimpleInfoItem(
                            icon: Icons.event_rounded,
                            label: 'End Date',
                            value: _formatTravelDate(widget.blog.endDate!),
                            color: AppColors.highlight2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    if (widget.blog.tags.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.text1,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.blog.tags
                .map((tag) => _buildTagChip(tag))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: AppColors.text1,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
