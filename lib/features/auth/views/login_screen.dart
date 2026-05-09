// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:backpackr/shared/widgets/app_colors.dart';
import 'package:backpackr/shared/widgets/app_text_styles.dart';
import 'package:backpackr/shared/widgets/custom_button.dart';
import 'package:backpackr/features/auth/repositories/auth_service.dart';
import 'package:backpackr/core/utils/error_handler.dart';
import 'package:backpackr/features/auth/views/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isEmailLoginLoading = false;
  bool _isGuestLoading = false;
  bool _isAppleLoading = false;
  bool _isGoogleLoading = false;
  final AuthService _authService = AuthService();
  // Removed unused AppFlowService instance

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  bool get _isAnyLoading =>
      _isEmailLoginLoading ||
      _isGuestLoading ||
      _isAppleLoading ||
      _isGoogleLoading;

  Widget _buildEulaContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'End User License Agreement (EULA)',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This End User License Agreement ("Agreement") governs your use of this application ("App"). By downloading, installing, or using the App, you agree to be bound by the terms of this Agreement. If you do not agree, do not use the App.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '1. License Grant',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You are granted a limited, non-exclusive, non-transferable license to use the App on your personal device for personal, non-commercial purposes, in accordance with this Agreement.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '2. User-Generated Content & Community Use',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The App allows users to post, upload, or share content, including text, images, and other materials.\n\n• You are solely responsible for the content you create, share, or interact with.\n• You agree not to post content that is unlawful, offensive, defamatory, misleading, fraudulent, infringing, or otherwise inappropriate.\n• There is zero tolerance for objectionable content or abusive users.\n• The App includes functionality to block and report users for inappropriate content or behavior. Reports may be reviewed and acted upon at the App\'s discretion.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '3. Community Guidelines & Enforcement',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You must comply with the App\'s community guidelines at all times.\n\nThe App reserves the right, at its sole discretion, to:\n• Remove or restrict access to any content that violates community guidelines.\n• Temporarily or permanently suspend or block a user account for violations.\n• Take any additional action deemed necessary to maintain a safe and respectful environment.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '4. Restrictions',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You may not:\n• Reverse engineer, modify, or distribute the App.\n• Use the App for unlawful purposes.\n• Interfere with the security or functionality of the App.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '5. Data & Privacy',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your use of the App is also subject to the Privacy Policy, which explains how data is collected, stored, and used.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '6. Disclaimer of Warranties',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The App is provided "as is" and without warranties of any kind. No guarantee is made regarding accuracy, reliability, or availability.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '7. Limitation of Liability',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'To the fullest extent permitted by law, the App and its operators are not liable for damages arising from your use or inability to use the App, including but not limited to lost data, community disputes, or account suspension.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '8. Termination',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This Agreement is effective until terminated. The App may terminate or suspend your access immediately, without notice, for violation of this Agreement or community guidelines.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '9. Updates & Modifications',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The App may update or modify this Agreement at any time. Continued use after changes constitutes acceptance of the revised Agreement.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '10. Governing Law',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This Agreement shall be governed by applicable laws of your jurisdiction, without regard to conflict of laws principles.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showEulaDialogBeforeGuestLogin() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cta1,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'End User License Agreement',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.text3,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildEulaContent(),
                  ),
                ),
                // Footer with Cancel and Accept buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Later',
                          isOutlined: true,
                          backgroundColor: AppColors.cta2,
                          isFullWidth: true,
                          height: 44,
                          onPressed: () {
                            Navigator.of(context).pop();
                            _proceedWithGuestLogin(eulaAccepted: false);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Accept',
                          backgroundColor: AppColors.cta1,
                          isFullWidth: true,
                          height: 44,
                          onPressed: () {
                            Navigator.of(context).pop();
                            _proceedWithGuestLogin(eulaAccepted: true);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    setState(() {
      _isEmailLoginLoading = true;
    });

    try {
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Navigate to home screen after successful login
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEmailLoginLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _handleRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _handleGuestLogin() {
    // Show EULA dialog before proceeding
    _showEulaDialogBeforeGuestLogin();
  }

  Future<void> _proceedWithGuestLogin({required bool eulaAccepted}) async {
    setState(() {
      _isGuestLoading = true;
    });

    try {
      // Use Firebase anonymous authentication for guest login
      await _authService.signInAnonymously();

      // If user accepted EULA, save it
      if (eulaAccepted) {
        try {
          await _authService.acceptEula();
        } catch (e) {
          // Log error but don't block guest login
          print('Error saving EULA acceptance: $e');
        }
      }

      if (mounted) {
        // For guest users, we'll navigate directly to home
        // since they won't have business setup data
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGuestLoading = false;
        });
      }
    }
  }

  void _handleAppleSignIn() async {
    setState(() {
      _isAppleLoading = true;
    });

    try {
      await _authService.signInWithApple();

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAppleLoading = false;
        });
      }
    }
  }

  void _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      await _authService.signInWithGoogle();

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shadowColor: AppColors.shadow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: AppColors.cardBackground,
                child: Container(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        'Login',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email Input
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter Email',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.textSecondary,
                              ),
                              filled: true,
                              fillColor: AppColors.background2,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.cta1,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Password Input
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter Password',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppColors.textSecondary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: _togglePasswordVisibility,
                              ),
                              filled: true,
                              fillColor: AppColors.background2,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.cta1,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Login Button
                      CustomButton(
                        text: 'Login',
                        backgroundColor: AppColors.cta1,
                        isFullWidth: true,
                        height: 50,
                        isLoading: _isEmailLoginLoading,
                        onPressed: _isAnyLoading ? null : _handleLogin,
                      ),
                      const SizedBox(height: 24),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: _handleRegister,
                            child: Text(
                              'Register',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.cta1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Separator
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.divider,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.divider,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Continue as Guest Button
                      CustomButton(
                        text: 'Continue as a Guest',
                        isOutlined: true,
                        backgroundColor: AppColors.cta2,
                        isFullWidth: true,
                        height: 50,
                        isLoading: _isGuestLoading,
                        onPressed: _isAnyLoading ? null : _handleGuestLogin,
                      ),
                      const SizedBox(height: 16),

                      // Sign in with Apple Button
                      CustomButton(
                        text: _isAppleLoading
                            ? 'Signing in...'
                            : 'Sign in with Apple',
                        backgroundColor: AppColors.appleButton,
                        textColor: AppColors.appleButtonText,
                        iconWidget: Icon(
                          Icons.apple,
                          color: AppColors.appleButtonText,
                          size: 24,
                        ),
                        isFullWidth: true,
                        height: 50,
                        isLoading: _isAppleLoading,
                        onPressed: _isAnyLoading ? null : _handleAppleSignIn,
                      ),
                      const SizedBox(height: 16),

                      // Sign in with Google Button
                      CustomButton(
                        text: _isGoogleLoading
                            ? 'Signing in...'
                            : 'Sign in with Google',
                        backgroundColor: AppColors.googleButton,
                        textColor: AppColors.googleButtonText,
                        iconWidget: Image.asset(
                          'assets/icons/google-icon.png',
                          height: 24,
                          width: 24,
                        ),
                        isFullWidth: true,
                        height: 50,
                        isLoading: _isGoogleLoading,
                        onPressed: _isAnyLoading ? null : _handleGoogleSignIn,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
