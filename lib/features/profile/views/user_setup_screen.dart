// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:backpackr/features/profile/controllers/profile_controller.dart';
import 'package:backpackr/shared/widgets/app_colors.dart';
import 'package:backpackr/shared/widgets/app_text_styles.dart';
import 'package:backpackr/shared/widgets/custom_button.dart';
import 'package:backpackr/shared/widgets/image_source_bottom_sheet.dart';

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
  final ProfileController _profileController = ProfileController();

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
    _profileController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    try {
      final setupData = await _profileController.loadSetupData();
      setState(() {
        _userNameController.text = setupData.displayName;
        _bioController.text = setupData.bio;
        _locationController.text = setupData.currentLocation;
        _selectedTags = List<String>.from(setupData.tags);
        _destinations = setupData.destinations
            .map((d) => Map<String, dynamic>.from(d))
            .toList();
        _imageUrl = setupData.avatarUrl;
        _currentLat = setupData.latitude;
        _currentLng = setupData.longitude;
      });
    } catch (e) {
      // Handle error silently
      debugPrint('Error loading existing data: $e');
    }
  }

  Future<void> _pickImage() async {
    await ImageSourceBottomSheet.show(
      context: context,
      title: 'Change Profile Photo',
      subtitle: 'Choose a source to update your profile picture',
      onCameraSelected: () => _handlePick(ProfileImageSource.camera),
      onGallerySelected: () => _handlePick(ProfileImageSource.gallery),
    );
  }

  Future<void> _handlePick(ProfileImageSource source) async {
    try {
      final file = await _profileController.pickProfileImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
        maxBytes: 2 * 1024 * 1024,
      );

      if (file != null) {
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
      final location = await _profileController.fetchCurrentLocation();
      setState(() {
        _currentLat = location.latitude;
        _currentLng = location.longitude;
        _locationController.text = location.displayName;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
      // Auto-add pending destination if not explicitly added
      if (_destinationController.text.isNotEmpty && _destinationDate != null) {
        _destinations.add({
          'city': _destinationController.text,
          'date': '${_destinationDate!.month}/${_destinationDate!.year}',
        });
        _destinationController.clear();
        _destinationDate = null;
      }

      await _profileController.saveSetupProfile(
        displayName: _userNameController.text,
        bio: _bioController.text,
        currentLocation: _locationController.text,
        latitude: _currentLat,
        longitude: _currentLng,
        existingAvatarUrl: _imageUrl,
        selectedImage: _selectedImage,
        tags: _selectedTags,
        destinations: _destinations,
      );

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
              borderSide: BorderSide(color: AppColors.text1.withOpacity(0.20)),
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
