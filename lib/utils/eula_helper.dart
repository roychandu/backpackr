import 'package:flutter/material.dart';
import '../common_widgets/app_colors.dart';
import '../common_widgets/app_text_styles.dart';
import '../common_widgets/custom_button.dart';
import '../services/auth_service.dart';

class EulaHelper {
  static Future<bool> checkAndRequestEulaAcceptance(
    BuildContext context,
  ) async {
    final authService = AuthService();

    // Check if user has already accepted EULA
    final hasAccepted = await authService.hasAcceptedEula();
    if (hasAccepted) {
      return true; // User has already accepted
    }

    // Show EULA dialog and wait for response
    final bool? accepted = await showDialog<bool>(
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
                    color: AppColors.primary,
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
                            color: AppColors.text1,
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
                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'You must accept the EULA to post content to the community.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Cancel',
                              isOutlined: true,
                              backgroundColor: AppColors.primary,
                              borderColor: AppColors.primary,
                              isFullWidth: true,
                              height: 48,
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: 'Accept',
                              backgroundColor: AppColors.primary,
                              isFullWidth: true,
                              height: 48,
                              onPressed: () => Navigator.of(context).pop(true),
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
      },
    );

    // If user accepted, save to database
    if (accepted == true) {
      try {
        await authService.acceptEula();
        return true;
      } catch (e) {
        // Show error but return false
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Failed to save EULA acceptance: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return false;
      }
    }

    return false; // User cancelled
  }

  static Widget _buildEulaContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'End User License Agreement (EULA)',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This End User License Agreement ("Agreement") governs your use of this application ("App"). By downloading, installing, or using the App, you agree to be bound by the terms of this Agreement. If you do not agree, do not use the App.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          '1. License Grant',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You are granted a limited, non-exclusive, non-transferable license to use the App on your personal device for personal, non-commercial purposes, in accordance with this Agreement.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          '2. User-Generated Content & Community Use',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The App allows users to post, upload, or share content, including text, images, and other materials.\n\n• You are solely responsible for the content you create, share, or interact with.\n• You agree not to post content that is unlawful, offensive, defamatory, misleading, fraudulent, infringing, or otherwise inappropriate.\n• The App includes functionality to block and report users for inappropriate content or behavior. Reports may be reviewed and acted upon at the App\'s discretion.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          '3. Community Guidelines & Enforcement',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You must comply with the App\'s community guidelines at all times.\n\nThe App reserves the right, at its sole discretion, to:\n• Remove or restrict access to any content that violates community guidelines.\n• Temporarily or permanently suspend or block a user account for violations.\n• Take any additional action deemed necessary to maintain a safe and respectful environment.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          '4. Restrictions',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You may not:\n• Reverse engineer, modify, or distribute the App.\n• Use the App for unlawful purposes.\n• Interfere with the security or functionality of the App.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          '5. Data & Privacy',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your use of the App is also subject to the Privacy Policy, which explains how data is collected, stored, and used.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          '6. Disclaimer of Warranties',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The App is provided "as is" and without warranties of any kind. No guarantee is made regarding accuracy, reliability, or availability.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          '7. Limitation of Liability',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'To the fullest extent permitted by law, the App and its operators are not liable for damages arising from your use or inability to use the App, including but not limited to lost data, community disputes, or account suspension.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          '8. Termination',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This Agreement is effective until terminated. The App may terminate or suspend your access immediately, without notice, for violation of this Agreement or community guidelines.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          '9. Updates & Modifications',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The App may update or modify this Agreement at any time. Continued use after changes constitutes acceptance of the revised Agreement.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          '10. Governing Law',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This Agreement shall be governed by applicable laws of your jurisdiction, without regard to conflict of laws principles.',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}
