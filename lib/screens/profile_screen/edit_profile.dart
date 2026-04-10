import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:backpackr/aws/aws_module.dart';
import '../../common_widgets/app_colors.dart';
import '../../services/auth_service.dart';
import 'package:firebase_database/firebase_database.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.3,
          maxChildSize: 0.6,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.background2, AppColors.mainBackground],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.text2.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.cta1, AppColors.cta2],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.photo_camera_back,
                            color: AppColors.text1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Change Profile Photo',
                                style: TextStyle(
                                  color: AppColors.text1,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Choose a source to update your profile picture',
                                style: TextStyle(
                                  color: AppColors.text2,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Camera card
                            Expanded(
                              child: _imageSourceCard(
                                icon: Icons.photo_camera,
                                title: 'Take a photo',
                                subtitle: 'Open camera',
                                primaryLabel: 'Camera',
                                onPrimary: () async {
                                  Navigator.pop(context);
                                  await _handleImageFromSource(
                                    ImageSource.camera,
                                  );
                                },
                                secondaryLabel: null,
                                onSecondary: null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Gallery card
                            Expanded(
                              child: _imageSourceCard(
                                icon: Icons.photo_library,
                                title: 'Choose from gallery',
                                subtitle: 'Pick a photo',
                                primaryLabel: 'Gallery',
                                onPrimary: () async {
                                  Navigator.pop(context);
                                  await _handleImageFromSource(
                                    ImageSource.gallery,
                                  );
                                },
                                secondaryLabel: null,
                                onSecondary: null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _imageSourceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background2.withOpacity(0.5),
        border: Border.all(color: AppColors.text2.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.cta1, AppColors.cta2],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.text1, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text1,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 28,
                child: Center(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.text2,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.text1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                primaryLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (secondaryLabel != null && onSecondary != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSecondary,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.text2.withOpacity(0.5),
                    width: 1.2,
                  ),
                  foregroundColor: AppColors.text2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(
                  secondaryLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
        ),
        title: const Text(
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
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
                                    color: Colors.white,
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
                                                (context, url, error) =>
                                                    const Icon(
                                                      Icons.person,
                                                      size: 60,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                          ),
                                        )
                                      : const Icon(
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
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          const Text(
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
                        const Text(
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
                            decoration: const InputDecoration(
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
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
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
        style: const TextStyle(
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
          style: const TextStyle(
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
              hintStyle: const TextStyle(
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
            style: const TextStyle(fontSize: 16, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
