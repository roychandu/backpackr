// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:backpackr/shared/services/upload/aws_module.dart';
import 'package:backpackr/shared/widgets/custom_button.dart';
import 'package:backpackr/shared/widgets/app_colors.dart';
import 'package:backpackr/features/auth/repositories/auth_service.dart';
import 'package:backpackr/shared/services/storage_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:backpackr/shared/widgets/image_source_bottom_sheet.dart';
// profileimg_HIr4SpWp8Oei0qxLdlzxMlLb1i82_1756382329336.png

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  File? pickedImage;
  File? _profileImage;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? newUploadedImgPath;
  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _userEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        _isLoadingData = true;
      });
      // Load user data
      final userData = await _authService.getUserData();
      if (userData['email'] != null) {
        _userEmailController.text = userData['email']!;
      }
      if (userData['name'] != null) {
        _userNameController.text = userData['name']!;
      }
      if (userData['photoURL'] != null &&
          (userData['photoURL'] as String).isNotEmpty) {
        newUploadedImgPath = userData['photoURL'];
      }

      setState(() {
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        _showSnackBar('Error loading profile data: $e', AppColors.error);
      }
    }
  }

  Future<String?> uploadProfileImage(String imagePath) async {
    try {
      String fileName =
          "profileimg_${FirebaseAuth.instance.currentUser?.uid}_${DateTime.now().millisecondsSinceEpoch}.png";
      String? newImageName = await uploadImageToAWS(
        file: File(imagePath),
        fileName: fileName,
      );

      // Return the CDN URL for immediate use in the UI and profile
      if (newImageName != null && newImageName.isNotEmpty) {
        return getUrlForUserUploadedImage(newImageName);
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
    }
    return null;
  }

  Future<String?> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // Navigator.of(context).pop(image.path);
        return image.path;
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            content: Text('Error selecting image: $e'),
          ),
        );
      }
    }
    return null;
  }

  Future<void> _handleImageFromSource(ImageSource source) async {
    try {
      final String? imagePath = await _pickImage(source);
      if (imagePath == null) return;

      final File compressedImage = await pickAndCompressImage(File(imagePath));

      if (!mounted) return;
      setState(() {
        pickedImage = compressedImage;
        _profileImage = compressedImage;
        // Clear the previous uploaded path since we have a new image
        newUploadedImgPath = null;
      });
    } catch (e) {
      debugPrint('Error handling selected image: $e');
    }
  }

  void _openImageSourceSheet() {
    ImageSourceBottomSheet.show(
      context: context,
      title: 'Change Profile Photo',
      subtitle: 'Choose a source to update your profile picture',
      onCameraSelected: () async {
        await _handleImageFromSource(ImageSource.camera);
      },
      onGallerySelected: () async {
        await _handleImageFromSource(ImageSource.gallery);
      },
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload new image if selected
      String? uploadedImageUrl;
      if (pickedImage != null) {
        uploadedImageUrl = await uploadProfileImage(pickedImage!.path);
        setState(() {
          newUploadedImgPath = uploadedImageUrl;
        });
      }

      // Update user profile (displayName and optional photoURL)
      await _authService.updateUserProfile(
        displayName: _userNameController.text.trim(),
        photoURL: uploadedImageUrl,
      );

      // Persist to Realtime Database so other screens fetch the latest values
      try {
        final String? uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final String? finalPhoto = uploadedImageUrl ?? newUploadedImgPath;
          final Map<String, dynamic> updates = {
            'name': _userNameController.text.trim(),
          };
          if (finalPhoto != null && finalPhoto.isNotEmpty) {
            updates['photoURL'] = finalPhoto;
          }
          await FirebaseDatabase.instance
              .ref('users')
              .child(uid)
              .update(updates);
        }
      } catch (e) {
        debugPrint('Failed to persist profile to DB: $e');
      }

      await _storageService.setProfileDisplayName(
        _userNameController.text.trim(),
      );
      if ((uploadedImageUrl ?? newUploadedImgPath ?? '').isNotEmpty) {
        await _storageService.setProfileAvatarUrl(
          uploadedImageUrl ?? newUploadedImgPath!,
        );
      }

      // Update password if provided
      if (_passwordController.text.isNotEmpty) {
        // Note: Password update requires re-authentication
        // For now, we'll just show a message
        _showSnackBar(
          'Password update requires re-authentication',
          AppColors.error,
        );
      }

      if (mounted) {
        _showSnackBar('Profile updated successfully!', AppColors.success);
        _passwordController.clear();
        // Clear the picked image since it's now saved
        pickedImage = null;
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating profile: $e', AppColors.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingData
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Picture Section
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _openImageSourceSheet,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.text1,
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.shadow,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: _profileImage != null
                                      ? ClipOval(
                                          child: Image.file(
                                            _profileImage!,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : (newUploadedImgPath != null &&
                                            newUploadedImgPath!.isNotEmpty)
                                      ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                getUrlForUserUploadedImage(
                                                  newUploadedImgPath!,
                                                ),
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                            errorWidget:
                                                (context, url, error) => Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.person,
                                          size: 60,
                                          color: AppColors.textSecondary,
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _openImageSourceSheet,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.text1,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      color: AppColors.text1,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          Text(
                            'Profile Photo',
                            style: TextStyle(
                              color: AppColors.text1,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // User Information Section
                    _buildSectionHeader('User Information'),
                    const SizedBox(height: 16),

                    // User Name Field
                    _buildFormField(
                      label: 'User Name',
                      controller: _userNameController,
                      hint: 'Enter your name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'User name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // User Email Field (Read-only)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Email',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.textFieldBackground.withOpacity(
                              0.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _userEmailController,
                            enabled: false,
                            decoration: InputDecoration(
                              hintText: 'user@email.com',
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              suffixIcon: Icon(
                                Icons.lock,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    CustomButton(
                      text: 'Save',
                      backgroundColor: AppColors.primary,
                      isFullWidth: true,
                      height: 50,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _saveProfile,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.textFieldBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword && !_isPasswordVisible,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: _togglePasswordVisibility,
                    )
                  : null,
            ),
            style: TextStyle(fontSize: 16, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
