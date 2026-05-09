// ignore_for_file: use_build_context_synchronously, deprecated_member_use, sort_child_properties_last

import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:backpackr/shared/widgets/app_colors.dart';
import 'package:backpackr/shared/widgets/app_text_styles.dart';
import 'package:backpackr/shared/widgets/custom_button.dart';
import 'package:backpackr/shared/widgets/image_source_bottom_sheet.dart';
import 'package:backpackr/features/blogs/repositories/blog_service.dart';
import 'package:backpackr/core/utils/error_handler.dart';
import 'package:backpackr/features/auth/repositories/auth_service.dart';
import 'package:backpackr/shared/services/user_setup_service.dart';

class CreateTravelingBlogBottomSheet extends StatefulWidget {
  final VoidCallback onBlogCreated;

  const CreateTravelingBlogBottomSheet({
    super.key,
    required this.onBlogCreated,
  });

  @override
  State<CreateTravelingBlogBottomSheet> createState() =>
      _CreateTravelingBlogBottomSheetState();
}

class _CreateTravelingBlogBottomSheetState
    extends State<CreateTravelingBlogBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final BlogService _blogService = BlogService();
  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldMessengerState> _sheetMessenger =
      GlobalKey<ScaffoldMessengerState>();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startPlaceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _tagsController = TextEditingController();

  // Form state
  DateTime? _startDate;
  DateTime? _endDate;
  final List<File> _selectedImages = [];
  bool _isCreating = false;

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
          'The App allows users to post, upload, or share content, including text, images, and other materials.\n\n• You are solely responsible for the content you create, share, or interact with.\n• You agree not to post content that is unlawful, offensive, defamatory, misleading, fraudulent, infringing, or otherwise inappropriate.\n• The App includes functionality to block and report users for inappropriate content or behavior. Reports may be reviewed and acted upon at the App\'s discretion.',
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

  Future<void> _showEulaDialogBeforeCreate() async {
    await showDialog(
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildEulaContent(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Later',
                          isOutlined: true,
                          backgroundColor: AppColors.cta2,
                          borderColor: AppColors.cta2,
                          isFullWidth: true,
                          height: 48,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Accept',
                          backgroundColor: AppColors.cta1,
                          isFullWidth: true,
                          height: 48,
                          onPressed: () async {
                            try {
                              Navigator.of(context).pop();
                              await _authService.acceptEula();
                              await _performCreateBlog();
                            } catch (e) {
                              if (!mounted) return;
                              _sheetMessenger.currentState?.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ErrorHandler.getFriendlyErrorMessage(e),
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startPlaceController.dispose();
    _destinationController.dispose();
    _distanceController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  String _calculateDuration() {
    if (_startDate == null || _endDate == null) {
      return 'Select start and end dates';
    }

    final difference = _endDate!.difference(_startDate!).inDays;

    if (difference == 0) {
      return 'Same day';
    } else if (difference == 1) {
      return '1 day';
    } else if (difference < 7) {
      return '$difference days';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      final remainingDays = difference % 7;
      if (remainingDays == 0) {
        return weeks == 1 ? '1 week' : '$weeks weeks';
      } else {
        return weeks == 1
            ? '1 week $remainingDays ${remainingDays == 1 ? 'day' : 'days'}'
            : '$weeks weeks $remainingDays ${remainingDays == 1 ? 'day' : 'days'}';
      }
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      final remainingDays = difference % 30;
      if (remainingDays == 0) {
        return months == 1 ? '1 month' : '$months months';
      } else {
        return months == 1
            ? '1 month $remainingDays ${remainingDays == 1 ? 'day' : 'days'}'
            : '$months months $remainingDays ${remainingDays == 1 ? 'day' : 'days'}';
      }
    } else {
      final years = (difference / 365).floor();
      final remainingMonths = ((difference % 365) / 30).floor();
      if (remainingMonths == 0) {
        return years == 1 ? '1 year' : '$years years';
      } else {
        return years == 1
            ? '1 year $remainingMonths ${remainingMonths == 1 ? 'month' : 'months'}'
            : '$years years $remainingMonths ${remainingMonths == 1 ? 'month' : 'months'}';
      }
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.text1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Reset end date if it's before start date
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      _sheetMessenger.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Please select start date first'),
          backgroundColor: AppColors.cta1,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!,
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.text1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          // Limit to 6 images
          final remainingSlots = 6 - _selectedImages.length;
          final imagesToAdd = images.take(remainingSlots);
          _selectedImages.addAll(imagesToAdd.map((img) => File(img.path)));
        });
      }
    } catch (e) {
      if (!mounted) return;
      _sheetMessenger.currentState?.showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null && _selectedImages.length < 6) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (!mounted) return;
      _sheetMessenger.currentState?.showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showImagePickerOptions() {
    ImageSourceBottomSheet.show(
      context: context,
      title: 'Add Travel Photos',
      subtitle: 'Choose a source to add your travel photos',
      onCameraSelected: () async {
        await _pickImageFromCamera();
      },
      onGallerySelected: () async {
        await _pickImages();
      },
    );
  }

  Future<void> _createBlog() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();

    // Wait a brief moment for keyboard to dismiss
    await Future.delayed(const Duration(milliseconds: 100));

    // Require strict profile completion before allowing blog creation
    final setupOk = await UserSetupService.isProfileStrictlyComplete();
    if (!setupOk) {
      await UserSetupService.showSetupPopup(context);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _sheetMessenger.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: AppColors.cta1,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      _sheetMessenger.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Please add at least one photo'),
          backgroundColor: AppColors.cta1,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_startDate == null) {
      _sheetMessenger.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Please select the journey start date'),
          backgroundColor: AppColors.cta1,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check EULA acceptance before creating the blog
    final hasAccepted = await _authService.hasAcceptedEula();
    if (!hasAccepted) {
      await _showEulaDialogBeforeCreate();
      return;
    }

    await _performCreateBlog();
  }

  Future<void> _performCreateBlog() async {
    if (!mounted) return;

    setState(() {
      _isCreating = true;
    });

    try {
      // Parse tags from comma-separated input
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Create blog with Firebase and AWS
      await _blogService.createBlog(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startPlace: _startPlaceController.text.trim(),
        destination: _destinationController.text.trim(),
        distance: _distanceController.text.trim(),
        duration: _calculateDuration(),
        startDate: _startDate!,
        endDate: _endDate,
        images: _selectedImages,
        tags: tags,
      );

      if (!mounted) return;

      // Close the bottom sheet
      _sheetMessenger.currentState?.showSnackBar(
        SnackBar(
          content: Text('Blog created successfully!'),
          backgroundColor: AppColors.success,
          duration: Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Wait a moment so the SnackBar shows on this sheet
      await Future.delayed(const Duration(milliseconds: 1200));

      if (!mounted) return;
      Navigator.of(context).pop();

      // Call the success callback after closing
      widget.onBlogCreated();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCreating = false;
      });

      _sheetMessenger.currentState?.showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getFriendlyErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _sheetMessenger,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(0.95),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      border: Border.all(
                        color: AppColors.text1.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Drag Handle
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.text1.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.article_rounded,
                                  color: AppColors.text1,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Create Travel Blog',
                                  style: AppTextStyles.h4.copyWith(
                                    color: AppColors.text1,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: AppColors.text1.withOpacity(0.70),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Form
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Photos Section
                                  Text(
                                    'Travel Photos',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.text1,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Add Photo Button - Full Width
                                  if (_selectedImages.length < 6)
                                    GestureDetector(
                                      onTap: _showImagePickerOptions,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.text1.withOpacity(
                                            0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppColors.text1.withOpacity(
                                              0.15,
                                            ),
                                            width: 2,
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate,
                                              color: AppColors.primary,
                                              size: 40,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Add Travel Photos',
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                    color: AppColors.text1
                                                        .withOpacity(0.70),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_selectedImages.length}/6 photos added',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color: AppColors.text1
                                                        .withOpacity(0.54),
                                                    fontSize: 12,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // Selected Images Grid
                                  if (_selectedImages.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 1,
                                          ),
                                      itemCount: _selectedImages.length,
                                      itemBuilder: (context, index) {
                                        final image = _selectedImages[index];
                                        return Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            image: DecorationImage(
                                              image: FileImage(image),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              // Remove button
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      _removeImage(index),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.error,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.close,
                                                      color: AppColors.text1,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 16),

                                  // Title
                                  _buildTextField(
                                    controller: _titleController,
                                    icon: Icons.title_rounded,
                                    hintText:
                                        'Blog title (e.g., My Paris Adventure)',
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter a title';
                                      }
                                      if (value.trim().length < 3) {
                                        return 'Title must be at least 3 characters';
                                      }
                                      return null;
                                    },
                                    textCapitalization:
                                        TextCapitalization.words,
                                  ),
                                  const SizedBox(height: 12),

                                  // Description/Experience
                                  _buildTextField(
                                    controller: _descriptionController,
                                    icon: Icons.description_rounded,
                                    hintText: 'Share your travel experience...',
                                    maxLines: 4,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please share your experience';
                                      }

                                      return null;
                                    },
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  ),
                                  const SizedBox(height: 12),

                                  // Start Place
                                  _buildTextField(
                                    controller: _startPlaceController,
                                    icon: Icons.location_on_outlined,
                                    hintText: 'Starting place (e.g., New York)',
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter starting place';
                                      }
                                      return null;
                                    },
                                    textCapitalization:
                                        TextCapitalization.words,
                                  ),
                                  const SizedBox(height: 12),

                                  // Destination
                                  _buildTextField(
                                    controller: _destinationController,
                                    icon: Icons.place_rounded,
                                    hintText:
                                        'Destination (e.g., Paris, France)',
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter destination';
                                      }
                                      return null;
                                    },
                                    textCapitalization:
                                        TextCapitalization.words,
                                  ),
                                  const SizedBox(height: 12),

                                  // Distance
                                  _buildTextField(
                                    controller: _distanceController,
                                    icon: Icons.social_distance_rounded,
                                    hintText: 'Distance (e.g., 5000 km)',
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Enter distance';
                                      }
                                      return null;
                                    },
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 12),

                                  // Start Date
                                  InkWell(
                                    onTap: _selectStartDate,
                                    child: _buildDateField(
                                      icon: Icons.calendar_today_rounded,
                                      label: 'Journey Started',
                                      date: _startDate,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // End Date (Optional)
                                  InkWell(
                                    onTap: _selectEndDate,
                                    child: _buildDateField(
                                      icon: Icons.event_rounded,
                                      label: 'Journey Ended',
                                      date: _endDate,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Calculated Duration (Non-editable)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: BackdropFilter(
                                      filter: ui.ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.text1.withOpacity(
                                            0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: AppColors.text1.withOpacity(
                                              0.15,
                                            ),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.timelapse_rounded,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Duration',
                                                    style: AppTextStyles
                                                        .bodySmall
                                                        .copyWith(
                                                          color: AppColors.text1
                                                              .withOpacity(0.7),
                                                          fontSize: 11,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _calculateDuration(),
                                                    style: AppTextStyles
                                                        .bodyMedium
                                                        .copyWith(
                                                          color:
                                                              (_startDate ==
                                                                      null ||
                                                                  _endDate ==
                                                                      null)
                                                              ? AppColors.text1
                                                                    .withOpacity(
                                                                      0.5,
                                                                    )
                                                              : AppColors.text1,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.info_outline,
                                              color: AppColors.text1
                                                  .withOpacity(0.5),
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Tags
                                  _buildTextField(
                                    controller: _tagsController,
                                    icon: Icons.tag_rounded,
                                    hintText:
                                        'Tags (e.g., adventure, culture, food)',
                                    textCapitalization: TextCapitalization.none,
                                  ),
                                  const SizedBox(height: 80),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Create Button
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            border: Border(
                              top: BorderSide(
                                color: AppColors.text1.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: CustomButton(
                            text: _isCreating
                                ? 'Creating...'
                                : 'Create Blog Post',
                            backgroundColor: AppColors.primary,
                            icon: Icons.check_rounded,
                            isFullWidth: true,
                            height: 50,
                            borderRadius: 25,
                            isLoading: _isCreating,
                            onPressed: _isCreating ? null : _createBlog,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType? keyboardType,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.text1.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.text1.withOpacity(0.15)),
          ),
          child: TextFormField(
            controller: controller,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text1),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text1.withOpacity(0.5),
              ),
              prefixIcon: Icon(icon, color: AppColors.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            maxLines: maxLines,
            validator: validator,
            textCapitalization: textCapitalization,
            keyboardType: keyboardType,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required IconData icon,
    required String label,
    required DateTime? date,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.text1.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.text1.withOpacity(0.15)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: date != null
                        ? AppColors.text1
                        : AppColors.text1.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
