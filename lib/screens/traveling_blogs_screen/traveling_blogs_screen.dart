// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import '../../common_widgets/app_colors.dart';
import '../../common_widgets/app_text_styles.dart';
import '../../models/blog.dart';
import '../../services/blog_service.dart';
import '../../services/user_setup_service.dart';
import '../../common_widgets/app_header.dart';
import '../../utils/error_handler.dart';
import 'create_traveling_blog_bottom_sheet.dart';
import 'traveling_blog_details_screen.dart';

class TravelingBlogsScreen extends StatefulWidget {
  const TravelingBlogsScreen({super.key});

  @override
  State<TravelingBlogsScreen> createState() => _TravelingBlogsScreenState();
}

class _TravelingBlogsScreenState extends State<TravelingBlogsScreen> {
  final BlogService _blogService = BlogService();
  List<Blog> _allBlogs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBlogs();
  }

  Future<void> _loadBlogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final blogs = await _blogService.getAllBlogs();

      setState(() {
        _allBlogs = blogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getFriendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadBlogs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                _buildErrorWidget()
              else if (_allBlogs.isEmpty)
                _buildEmptyState()
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ..._allBlogs.map(
                        (blog) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildBlogCard(blog),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: _allBlogs.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showCreateBlogDialog,
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: AppColors.text1),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppHeader(
      title: 'Traveling Blogs',
      subtitle: 'Share your travel stories',
      additionalSubtitle:
          '${_allBlogs.length} ${_allBlogs.length == 1 ? 'blog' : 'blogs'}',
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error loading blogs', style: AppTextStyles.h4),
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
              onPressed: _loadBlogs,
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
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final imageSize = math.min(screenWidth, screenHeight) * 0.4;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            SizedBox(
              width: imageSize,
              height: imageSize,
              child: Image.asset('assets/blog-empty.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            Text(
              'No blogs available',
              style: AppTextStyles.h4.copyWith(color: AppColors.primaryText),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your travel story!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCreateBlogDialog,
              icon: const Icon(Icons.add),
              label: const Text('Write Your First Blog'),
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

  Widget _buildBlogCard(Blog blog) {
    return _BlogCardWithSlider(blog: blog);
  }

  Future<void> _showCreateBlogDialog() async {
    // Check if user has completed profile setup
    if (!await _checkProfileSetup()) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTravelingBlogBottomSheet(
        onBlogCreated: () {
          _loadBlogs();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Blog created successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  /// Check if user has completed profile setup
  Future<bool> _checkProfileSetup() async {
    final hasCompleted = await UserSetupService.hasCompletedSetup();
    if (!hasCompleted) {
      if (!mounted) return false;

      // Use the existing SetupReminderPopup
      await UserSetupService.showSetupPopup(context);
      return false;
    }
    return true;
  }
}

class _BlogCardWithSlider extends StatefulWidget {
  final Blog blog;

  const _BlogCardWithSlider({required this.blog});

  @override
  State<_BlogCardWithSlider> createState() => _BlogCardWithSliderState();
}

class _BlogCardWithSliderState extends State<_BlogCardWithSlider> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    // Only auto-scroll if there are multiple images
    if (widget.blog.imageUrls.length <= 1) return;

    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextPage = (_currentImageIndex + 1) % widget.blog.imageUrls.length;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int index) {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TravelingBlogDetailsScreen(blog: widget.blog),
          ),
        );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images Slider
            if (widget.blog.imageUrls.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: SizedBox(
                      height: 250,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: widget.blog.imageUrls.length,
                        itemBuilder: (context, index) {
                          return CachedNetworkImage(
                            imageUrl: widget.blog.imageUrls[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Container(
                              color: AppColors.textSecondary.withOpacity(0.3),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.textSecondary.withOpacity(0.4),
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Image indicators
                  if (widget.blog.imageUrls.length > 1)
                    Positioned(
                      bottom: 12,
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
                                  ? AppColors.primary
                                  : AppColors.text1.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Image counter
                  if (widget.blog.imageUrls.length > 1)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.text3.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${widget.blog.imageUrls.length}',
                          style: const TextStyle(
                            color: AppColors.text1,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

            // Content padding
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author and date
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          widget.blog.author.isNotEmpty
                              ? widget.blog.author[0].toUpperCase()
                              : 'A',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.blog.author,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.text3.withOpacity(0.87),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatDate(widget.blog.dateCreated),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.text3.withOpacity(0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Blog title
                  Text(
                    widget.blog.title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.text3.withOpacity(0.87),
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Blog content preview
                  Text(
                    widget.blog.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.text3.withOpacity(0.54),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tags
                  if (widget.blog.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.blog.tags
                          .map((tag) => _buildTagChip(tag))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Bottom row with location and date
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.text3.withOpacity(0.38),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${widget.blog.startPlace} → ${widget.blog.destination}',
                          style: TextStyle(
                            color: AppColors.text3.withOpacity(0.54),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.social_distance_rounded,
                        size: 16,
                        color: AppColors.text3.withOpacity(0.38),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.blog.distance} km',
                          style: TextStyle(
                            color: AppColors.text3.withOpacity(0.54),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Travel dates row
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.text3.withOpacity(0.38),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTravelDate(widget.blog.startDate),
                        style: TextStyle(
                          color: AppColors.text3.withOpacity(0.54),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.blog.endDate != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: AppColors.text3.withOpacity(0.38),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTravelDate(widget.blog.endDate!),
                          style: TextStyle(
                            color: AppColors.text3.withOpacity(0.54),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Icon(Icons.schedule, size: 16, color: AppColors.text3.withOpacity(0.38)),
                      const SizedBox(width: 4),
                      Text(
                        widget.blog.duration,
                        style: TextStyle(
                          color: AppColors.text3.withOpacity(0.54),
                          fontSize: 13,
                        ),
                      ),
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

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
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
}
