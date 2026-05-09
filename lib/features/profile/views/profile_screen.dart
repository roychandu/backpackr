// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_to_list_in_spreads

import 'package:backpackr/shared/widgets/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:backpackr/features/profile/views/edit_profile.dart';
import 'package:backpackr/features/premium/views/premium_screen.dart';
import 'package:backpackr/features/profile/views/user_setup_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:backpackr/features/premium/controllers/purchase_controller.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:backpackr/shared/widgets/app_colors.dart';
import 'package:backpackr/shared/widgets/custom_button.dart';
import 'package:backpackr/features/auth/repositories/auth_service.dart';
import 'package:backpackr/shared/services/theme_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  String _userEmail = '';
  String _userName = '';
  String? _userPhotoUrl;
  bool _isLoading = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final userData = await _authService.getUserData();
      if (mounted) {
        setState(() {
          _userEmail = userData['email'] ?? '';
          _userName = userData['name'] ?? '';
          _userPhotoUrl = userData['photoURL'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text1,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildSettingsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.text1.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.text1.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: AppColors.text3.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: _userPhotoUrl != null
                        ? CachedNetworkImageProvider(_userPhotoUrl!)
                        : null,
                    child: _userPhotoUrl == null
                        ? Icon(Icons.person, size: 50, color: AppColors.primary)
                        : null,
                  ),
                  // Edit button removed per requirement; show static avatar only
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _userName.isNotEmpty
                    ? _userName
                    : (_userEmail.isNotEmpty
                          ? _userEmail.split('@').first
                          : 'User'),
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.text1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (_userEmail.isNotEmpty)
                Text(
                  _userEmail,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.text1.withOpacity(0.70),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.text1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsCard([
          _buildSettingsRow(
            'Edit Profile',
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primaryText,
              size: 16,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ).then((_) {
                _loadProfileData();
              });
            },
          ),
          _buildDivider(),
          Obx(
            () => _buildSettingsRow(
              'Dark Mode',
              trailing: Switch(
                value: ThemeService.to.isDarkMode.value,
                onChanged: (val) {
                  ThemeService.to.switchTheme();
                },
                activeColor: AppColors.primary,
              ),
              onTap: () {
                ThemeService.to.switchTheme();
              },
            ),
          ),
          _buildDivider(),
          _buildSettingsRow(
            'Premium',
            trailing: const Icon(
              Icons.star,
              color: AppColors.highlight,
              size: 16,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PremiumScreen()),
              );
            },
          ),
          _buildSettingsRow(
            'Restore Purchases',
            trailing: const Icon(
              Icons.star,
              color: AppColors.highlight,
              size: 16,
            ),
            onTap: () {
              setState(() => isLoading = true);
              Provider.of<InAppPurchaseProvider>(
                context,
                listen: false,
              ).restorePurchases();
              setState(() => isLoading = false);
            },
          ),
          _buildDivider(),
          _buildSettingsRow(
            'Complete Profile Setup',
            trailing: Icon(
              Icons.person_add,
              color: AppColors.primary,
              size: 16,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserSetupScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsRow(
            'Sign Out',
            trailing: Icon(Icons.logout, color: AppColors.error, size: 16),
            onTap: _showSignOutDialog,
          ),
        ]),
        const SizedBox(height: 24),
        _buildSettingsCard([
          _buildSettingsRow(
            'Delete Account',
            trailing: Icon(
              Icons.delete_forever,
              color: AppColors.error,
              size: 16,
            ),
            onTap: _showDeleteAccountDialog,
          ),
        ]),
      ],
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.text1.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.text1.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: AppColors.text3.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildSettingsRow(
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.text1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.text1.withOpacity(0.1),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.text1.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.text1.withOpacity(0.18)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.text3.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppColors.text1,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to sign out?',
                    style: TextStyle(
                      color: AppColors.text1.withOpacity(0.70),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomButton(
                        text: 'Cancel',
                        isTextOnly: true,
                        textColor: AppColors.text1.withOpacity(0.70),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                      const SizedBox(width: 8),
                      CustomButton(
                        text: 'Sign Out',
                        isTextOnly: true,
                        textColor: AppColors.error,
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          try {
                            await _authService.signOut();
                            if (mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error signing out: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Account', style: TextStyle(color: AppColors.text1)),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(color: AppColors.text1.withOpacity(0.70)),
        ),
        actions: [
          CustomButton(
            text: 'Cancel',
            isTextOnly: true,
            textColor: AppColors.text1.withOpacity(0.70),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CustomButton(
            text: 'Delete',
            isTextOnly: true,
            textColor: AppColors.error,
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteAccount();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      await _authService.deleteAccount();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
