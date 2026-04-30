// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../common_widgets/app_colors.dart';
import '../../common_widgets/app_text_styles.dart';
import '../../common_widgets/custom_button.dart';

class SetupReminderPopup extends StatelessWidget {
  const SetupReminderPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.text1.withOpacity(0.25),
                  AppColors.text1.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.text1.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.text3.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: AppColors.text1.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete Your Profile',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.text1,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: AppColors.text3.withOpacity(0.3),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Help others discover you!',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.text1,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: AppColors.text3.withOpacity(0.2),
                                    offset: const Offset(0, 1),
                                    blurRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Create your travel profile to connect with other travelers and share your adventures!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.text1,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: AppColors.text3.withOpacity(0.4),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Benefits list
                      Column(
                        children: [
                          _buildBenefitItem(
                            Icons.people,
                            'Connect with travelers',
                            'Find people with similar interests',
                          ),
                          const SizedBox(height: 12),
                          _buildBenefitItem(
                            Icons.share,
                            'Share your experiences',
                            'Tell others about your adventures',
                          ),
                          const SizedBox(height: 12),
                          _buildBenefitItem(
                            Icons.location_on,
                            'Discover new places',
                            'Get recommendations from fellow travelers',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Later',
                              isTextOnly: true,
                              backgroundColor: AppColors.text1,
                              textColor: AppColors.text1,
                              isFullWidth: true,
                              height: 44,
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: CustomButton(
                              text: 'Setup Profile',
                              isGradient: true,
                              isFullWidth: true,
                              height: 44,
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
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.3),
                AppColors.primary.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.text1.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.text1, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.text1,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: AppColors.text3.withOpacity(0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.text1,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: AppColors.text3.withOpacity(0.2),
                      offset: const Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
