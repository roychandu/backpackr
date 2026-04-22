// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:backpackr/screens/auth_screen/login_screen.dart';
import '../../common_widgets/app_colors.dart';
import '../../common_widgets/app_text_styles.dart';
import '../../common_widgets/custom_button.dart';
import '../../services/app_flow_service.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late final List<_OnboardPage> _pages;
  final AppFlowService _appFlowService = AppFlowService();
  bool _isLoading = false;
  bool _hasError = false;
  late AnimationController _slideController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pages = [
      _OnboardPage(
        heading: 'Meet Like-Minded Travelers',
        subtext:
            'Connect with fellow travelers in your city through our unique double opt-in system. Build meaningful connections with people who share your passion for exploration and adventure.',
        asset: 'assets/onboard03.png',
        icon: Icons.people_rounded,
        illustrationDescription:
            'Illustration showing travelers chatting and connecting',
      ),
      _OnboardPage(
        heading: 'Plan & Share Adventures',
        subtext:
            'Create collaborative itineraries, organize public or private meetups, and share your travel experiences. From city tours to hiking trips, plan your next adventure with fellow travelers.',
        asset: 'assets/onboard02.png',
        icon: Icons.map_rounded,
        illustrationDescription:
            'Illustration showing a meetup scene with travelers planning activities',
      ),
      _OnboardPage(
        heading: 'Stay Safe & Connected',
        subtext:
            'Your safety is our priority. Share your location only within your city, use check-in features, and control your visibility. All your data is private and secure.',
        asset: 'assets/onboard01.png',
        icon: Icons.shield_rounded,
        illustrationDescription:
            'Illustration showing a shield icon representing safety and privacy',
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      _slideController.forward();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Mark intro as seen and navigate to auth
      await _appFlowService.markIntroAsSeen();
      if (mounted) {
        _fadeController.forward();
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      }
    }
  }

  void _skipToAuth() async {
    await _appFlowService.markIntroAsSeen();
    if (mounted) {
      _fadeController.forward();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  void _retryLoad() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    // Simulate loading
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // void _goToHome() {
  //   // Navigator.of(context).pushReplacement(
  //   //   MaterialPageRoute(builder: (context) => const BusinessSetupScreen()),
  //   // );
  // }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorState();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.mainBackground, AppColors.background2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _buildPage(context, page);
                  },
                ),
              ),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, _OnboardPage page) {
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final screenWidth = media.size.width;
    final imageSize = math.min(screenWidth, screenHeight) * 0.7;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.1),
            // Illustration area (200x200pt as specified)
            Semantics(
              label: page.illustrationDescription,
              child: SizedBox(
                width: imageSize,
                height: imageSize,
                child: page.asset != null
                    ? Image.asset(page.asset!, fit: BoxFit.contain)
                    : Icon(
                        page.icon ?? Icons.people_rounded,
                        size: imageSize * 0.6,
                        color: AppColors.cta1,
                      ),
              ),
            ),
            // Title (16pt as specified)
            Text(
              page.heading,
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(
                color: AppColors.text1,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // Description (16pt, 1.5x line height as specified)
            Text(
              page.subtext,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.text2,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            SizedBox(height: screenHeight * 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress dots (8pt as specified)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: _currentPage == index ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppColors.cta1
                      : AppColors.cta1.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Primary CTA (44x44pt as specified)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: CustomButton(
              text: _currentPage == _pages.length - 1 ? 'Done' : 'Next',
              onPressed: _nextPage,
              isFullWidth: true,
              backgroundColor: AppColors.cta1,
            ),
          ),
          // Skip button at bottom (14pt as specified)
          if (_currentPage < _pages.length - 1)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                onPressed: _skipToAuth,
                child: Text(
                  'Skip',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.text2,
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.mainBackground, AppColors.background2],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Skeleton illustration
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.background2.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                const SizedBox(height: 40),
                // Skeleton text lines
                Container(
                  width: double.infinity,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.background2.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.background2.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 200,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.background2.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.mainBackground, AppColors.background2],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.highlight),
                const SizedBox(height: 24),
                Text(
                  'Failed to load content',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.text2,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: CustomButton(
                    text: 'Retry',
                    onPressed: _retryLoad,
                    isFullWidth: true,
                    backgroundColor: AppColors.cta1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardPage {
  final String heading;
  final String subtext;
  final String? asset;
  final IconData? icon;
  final String illustrationDescription;

  _OnboardPage({
    required this.heading,
    required this.subtext,
    this.asset,
    this.icon,
    required this.illustrationDescription,
  });
}
