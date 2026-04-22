// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:permission_handler/permission_handler.dart' as perm;
import '../../common_widgets/app_colors.dart';
import '../../common_widgets/app_text_styles.dart';
import '../../services/user_profile_service.dart';
import '../../models/user_profile.dart';
import '../../aws/aws_module.dart';

class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _destinationController = TextEditingController();
  final _userNameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final UserProfileService _profileService = UserProfileService();

  File? _selectedImage;
  String? _imageUrl;
  bool _isSaving = false;
  String _errorMessage = '';
  bool _isLocating = false;
  double? _currentLat;
  double? _currentLng;

  // Form data
  List<String> _selectedTags = [];
  List<Map<String, dynamic>> _destinations = [];
  DateTime? _destinationDate;
  String _userName = '';

  // Available tags
  final List<String> _availableTags = [
    'Budget Traveler',
    'Foodie',
    'Digital Nomad',
    'Adventure Seeker',
    'Culture Explorer',
    'Solo Traveler',
    'Family Traveler',
    'Business Traveler',
    'Photography Enthusiast',
    'Backpacker',
    'Luxury Traveler',
    'Nature Lover',
  ];

  // Popular cities for autocomplete
  final List<String> _popularCities = [
    'New York, US',
    'London, UK',
    'Paris, FR',
    'Tokyo, JP',
    'Sydney, AU',
    'Berlin, DE',
    'Rome, IT',
    'Barcelona, ES',
    'Amsterdam, NL',
    'Prague, CZ',
    'Vienna, AT',
    'Bangkok, TH',
    'Singapore, SG',
    'Dubai, AE',
    'Istanbul, TR',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _locationController.dispose();
    _destinationController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    try {
      // First, try to get username from Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? name = user.displayName;
        if (name == null || name.isEmpty) {
          // Fallback to email prefix
          name = user.email?.split('@').first ?? 'User';
        }
        setState(() {
          _userName = name!;
          _userNameController.text = name;
        });
      }

      // Then load existing profile data
      final profile = await _profileService.getCurrentUserProfile();
      if (profile != null) {
        setState(() {
          _bioController.text = profile.bio;
          _locationController.text = profile.currentLocation;
          _selectedTags = List<String>.from(profile.tags);
          _destinations = profile.destinations
              .map((d) => {'city': d.city, 'date': d.date})
              .toList();
          _imageUrl = profile.avatarUrl;
          if (profile.latitude != null && profile.longitude != null) {
            _currentLat = profile.latitude;
            _currentLng = profile.longitude;
          }
          // Use existing profile displayName if available and not empty
          if (profile.displayName.isNotEmpty) {
            _userName = profile.displayName;
            _userNameController.text = profile.displayName;
          }
        });
      }
    } catch (e) {
      // Handle error silently
      debugPrint('Error loading existing data: $e');
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

  Future<void> _pickImage() async {
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
                                  await _handlePick(ImageSource.camera);
                                },
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
                                  await _handlePick(ImageSource.gallery);
                                },
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
        ],
      ),
    );
  }

  Future<void> _handlePick(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final bytes = await file.readAsBytes();

        // Check file size (2MB max)
        if (bytes.length > 2 * 1024 * 1024) {
          setState(() {
            _errorMessage =
                'Photo too large. Please choose an image under 2MB.';
          });
          return;
        }

        setState(() {
          _selectedImage = file;
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image. Please try again.';
      });
    }
  }

  Future<void> _fetchAndSetCurrentLocation() async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
      _errorMessage = '';
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();

        setState(() {
          _errorMessage = 'Location services are disabled';
        });
        return;
      }

      // Permission flow via permission_handler for reliability
      var status = await perm.Permission.locationWhenInUse.status;
      if (status.isDenied) {
        status = await perm.Permission.locationWhenInUse.request();
      }
      if (status.isDenied) {
        setState(() {
          _errorMessage = 'Location permission denied';
        });
        return;
      }
      if (status.isPermanentlyDenied) {
        setState(() {
          _errorMessage =
              'Location permission permanently denied. Enable in Settings';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Cache coordinates
      _currentLat = position.latitude;
      _currentLng = position.longitude;

      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String display = '';
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city = p.locality?.isNotEmpty == true
            ? p.locality
            : p.subAdministrativeArea;
        final country = p.isoCountryCode ?? p.country;
        if (city != null && city.toString().isNotEmpty) {
          display = country != null && country.toString().isNotEmpty
              ? '$city, $country'
              : city.toString();
        } else if (p.administrativeArea != null &&
            p.administrativeArea!.isNotEmpty) {
          display = country != null && country.toString().isNotEmpty
              ? '${p.administrativeArea}, $country'
              : p.administrativeArea!;
        }
      }

      if (display.isEmpty) {
        display =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      setState(() {
        _locationController.text = display;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch location';
      });
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }

  void _addDestination() {
    if (_destinationController.text.isNotEmpty && _destinationDate != null) {
      setState(() {
        _destinations.add({
          'city': _destinationController.text,
          'date': '${_destinationDate!.month}/${_destinationDate!.year}',
        });
        _destinationController.clear();
        _destinationDate = null;
      });
    }
  }

  void _removeDestination(int index) {
    setState(() {
      _destinations.removeAt(index);
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else if (_selectedTags.length < 5) {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isSaving = false;
        });
        return;
      }

      // Auto-add pending destination if not explicitly added
      if (_destinationController.text.isNotEmpty && _destinationDate != null) {
        _destinations.add({
          'city': _destinationController.text,
          'date': '${_destinationDate!.month}/${_destinationDate!.year}',
        });
        _destinationController.clear();
        _destinationDate = null;
      }

      // Upload image if selected
      String? avatarUrl = _imageUrl;
      if (_selectedImage != null) {
        // Upload to AWS and get CDN URL
        avatarUrl = await uploadProfileImage(_selectedImage!.path);
        if (avatarUrl == null) {
          setState(() {
            _errorMessage = 'Failed to upload image. Please try again.';
            _isSaving = false;
          });
          return;
        }
      }

      // Create UserProfile object
      final profile = UserProfile(
        displayName: _userName.isNotEmpty
            ? _userName
            : (user.displayName ?? ''),
        bio: _bioController.text,
        currentLocation: _locationController.text,
        latitude: _currentLat,
        longitude: _currentLng,
        avatarUrl: avatarUrl,
        tags: _selectedTags,
        destinations: _destinations
            .map(
              (e) => Destination(
                city: (e['city'] as String?) ?? '',
                date: (e['date'] as String?) ?? '',
              ),
            )
            .toList(),
        setupCompleted: true,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      );

      // Save profile using service
      await _profileService.setCurrentUserProfile(profile);

      // Mark setup as completed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('userSetupCompleted', true);

      if (mounted) {
        Navigator.of(
          context,
        ).pop(true); // Return true to indicate successful setup
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save profile. Please try again.';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Complete Your Profile'),
        foregroundColor: AppColors.text1,
        iconTheme: const IconThemeData(color: AppColors.text1),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: Column(
        children: [
          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 24),
                    _buildUserNameSection(),
                    const SizedBox(height: 20),
                    _buildBioSection(),
                    const SizedBox(height: 20),
                    _buildLocationSection(),
                    const SizedBox(height: 20),
                    _buildDestinationsSection(),
                    const SizedBox(height: 20),
                    _buildTagsSection(),
                    const SizedBox(height: 20),
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _errorMessage,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          color: AppColors.background,
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.text1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.text1),
                      ),
                    )
                  : Text(
                      'Save Profile',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.text1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Photo',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.text1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _selectedImage != null
                  ? ClipOval(
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : _imageUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : Icon(Icons.add_a_photo, size: 40, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Tap to add photo',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.text1.withOpacity(0.70)),
          ),
        ),
      ],
    );
  }

  Widget _buildUserNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Name',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.text1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.text1.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: _userNameController,
            enabled: false,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text1.withOpacity(0.70)),
            decoration: InputDecoration(
              hintText: 'Loading user name...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text1.withOpacity(0.54),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.text1.withOpacity(0.20)),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.text1.withOpacity(0.20)),
              ),
              suffixIcon: Icon(
                Icons.person,
                color: AppColors.text1.withOpacity(0.6),
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'This is your display name from your account',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.text1.withOpacity(0.54)),
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bio',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.text1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bioController,
          maxLines: 3,
          maxLength: 120,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text1),
          decoration: InputDecoration(
            hintText: 'Tell us about your travel vibe!',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.text1.withOpacity(0.70)),
            filled: true,
            fillColor: AppColors.text1.withOpacity(0.10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.text1.withOpacity(0.20)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            counterStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.text1.withOpacity(0.54),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please add a bio';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Location',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.text1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _fetchAndSetCurrentLocation,
          child: AbsorbPointer(
            child: TextFormField(
              controller: _locationController,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text1),
              decoration: InputDecoration(
                hintText: 'Tap to fetch your current city',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.text1.withOpacity(0.70),
                ),
                filled: true,
                fillColor: AppColors.text1.withOpacity(0.10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.text1.withOpacity(0.20)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                suffixIcon: _isLocating
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Icon(Icons.my_location, color: AppColors.primary),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please add your current location';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Popular cities: ${_popularCities.take(5).join(', ')}',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.text1.withOpacity(0.54)),
        ),
      ],
    );
  }

  Widget _buildDestinationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next Destinations (up to 3)',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.text1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Add destination form
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _destinationController,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text1),
                decoration: InputDecoration(
                  hintText: 'City name',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.text1.withOpacity(0.70),
                  ),
                  filled: true,
                  fillColor: AppColors.text1.withOpacity(0.10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.text1.withOpacity(0.20),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (date != null) {
                  setState(() {
                    _destinationDate = date;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.text1.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addDestination,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.text1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
              ),
              child: const Icon(Icons.add, size: 20),
            ),
          ],
        ),

        // Show selected date
        if (_destinationDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Selected: ${_destinationDate!.month}/${_destinationDate!.year}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),

        // List of destinations
        if (_destinations.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...List.generate(_destinations.length, (index) {
            final dest = _destinations[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.text1.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${dest['city']} - ${dest['date']}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.text1,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeDestination(index),
                    icon: const Icon(
                      Icons.remove_circle,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Travel Tags',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.text1,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_selectedTags.length}/5',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () => _toggleTag(tag),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.text1.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.text1.withOpacity(0.40),
                  ),
                ),
                child: Text(
                  tag,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? AppColors.text1 : AppColors.text1,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
