// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:permission_handler/permission_handler.dart' as perm;
import '../../common_widgets/app_colors.dart';
import '../../common_widgets/app_text_styles.dart';
import '../../common_widgets/custom_button.dart';
import '../../common_widgets/image_source_bottom_sheet.dart';
import '../../services/user_profile_service.dart';
import '../../services/storage_service.dart';
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
  final StorageService _storageService = StorageService();

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
        await _storageService.setProfileDisplayName(profile.displayName);
        await _storageService.setProfileBio(profile.bio);
        await _storageService.setProfileCurrentLocation(
          profile.currentLocation,
        );
        await _storageService.setProfileAvatarUrl(profile.avatarUrl ?? '');
        await _storageService.setTravelerTags(profile.tags);
        await _storageService.setProfileSetupCompleted(profile.setupCompleted);

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
      } else {
        final cachedDisplayName = await _storageService.getProfileDisplayName();
        final cachedBio = await _storageService.getProfileBio();
        final cachedLocation = await _storageService.getProfileCurrentLocation();
        final cachedAvatarUrl = await _storageService.getProfileAvatarUrl();
        final cachedTags = await _storageService.getTravelerTags();

        setState(() {
          if ((cachedDisplayName ?? '').isNotEmpty) {
            _userName = cachedDisplayName!;
            _userNameController.text = cachedDisplayName;
          }
          if ((cachedBio ?? '').isNotEmpty) {
            _bioController.text = cachedBio!;
          }
          if ((cachedLocation ?? '').isNotEmpty) {
            _locationController.text = cachedLocation!;
          }
          _imageUrl = cachedAvatarUrl;
          if (cachedTags.isNotEmpty) {
            _selectedTags = cachedTags;
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
    await ImageSourceBottomSheet.show(
      context: context,
      title: 'Change Profile Photo',
      subtitle: 'Choose a source to update your profile picture',
      onCameraSelected: () => _handlePick(ImageSource.camera),
      onGallerySelected: () => _handlePick(ImageSource.gallery),
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

      // Use Geolocator permission flow
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'Location permission denied';
        });
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'Location permission permanently denied. Enable in Settings';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('Location fetching timed out');
      });

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
        displayName: _userNameController.text.trim().isNotEmpty
            ? _userNameController.text.trim()
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

      await _storageService.setProfileDisplayName(profile.displayName);
      await _storageService.setProfileBio(profile.bio);
      await _storageService.setProfileCurrentLocation(profile.currentLocation);
      await _storageService.setProfileAvatarUrl(profile.avatarUrl ?? '');
      await _storageService.setTravelerTags(profile.tags);
      await _storageService.setProfileSetupCompleted(true);

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
        iconTheme: IconThemeData(color: AppColors.text1),
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
            child: CustomButton(
              text: 'Save Profile',
              backgroundColor: AppColors.primary,
              isFullWidth: true,
              borderRadius: 12,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveProfile,
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
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.text1.withOpacity(0.70),
            ),
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
        TextFormField(
          controller: _userNameController,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text1),
          decoration: InputDecoration(
            hintText: 'Enter your user name',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.text1.withOpacity(0.54),
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
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a user name';
            }
            return null;
          },
        ),
        const SizedBox(height: 4),
        Text(
          'This is your display name shown to other travelers',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.text1.withOpacity(0.54),
          ),
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
        TextFormField(
          controller: _locationController,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text1),
          decoration: InputDecoration(
            hintText: 'Enter city or tap icon to fetch',
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
                : IconButton(
                    icon: Icon(Icons.my_location, color: AppColors.primary),
                    onPressed: _fetchAndSetCurrentLocation,
                    tooltip: 'Fetch current location',
                  ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please add your current location';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Popular cities: ${_popularCities.take(5).join(', ')}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.text1.withOpacity(0.54),
          ),
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
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.text1,
                ),
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
            CustomButton(
              text: '',
              icon: Icons.add,
              backgroundColor: AppColors.primary,
              borderRadius: 12,
              width: 48,
              height: 48,
              onPressed: _addDestination,
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
                    icon: Icon(
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
