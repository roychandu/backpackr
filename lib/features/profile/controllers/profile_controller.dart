import 'dart:io';

import 'package:backpackr/features/auth/repositories/auth_repository.dart';
import 'package:backpackr/features/profile/repositories/profile_repository.dart';
import 'package:backpackr/features/travelers/models/user_profile.dart';
import 'package:backpackr/shared/services/storage_service.dart';
import 'package:backpackr/shared/services/theme_service.dart';
import 'package:backpackr/shared/services/upload/aws_module.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

enum ProfileImageSource { camera, gallery }

class ProfileLocationResult {
  const ProfileLocationResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  final String displayName;
  final double latitude;
  final double longitude;
}

class ProfileSetupData {
  const ProfileSetupData({
    required this.displayName,
    required this.bio,
    required this.currentLocation,
    required this.tags,
    required this.destinations,
    this.avatarUrl,
    this.latitude,
    this.longitude,
  });

  final String displayName;
  final String bio;
  final String currentLocation;
  final String? avatarUrl;
  final List<String> tags;
  final List<Map<String, dynamic>> destinations;
  final double? latitude;
  final double? longitude;
}

class ProfileController extends ChangeNotifier {
  ProfileController({
    ProfileRepository? repository,
    AuthRepository? authRepository,
    StorageService? storageService,
    ImagePicker? imagePicker,
  }) : _repository = repository ?? ProfileRepository(),
       _authRepository = authRepository ?? AuthRepository(),
       _storageService = storageService ?? StorageService(),
       _imagePicker = imagePicker ?? ImagePicker();

  final ProfileRepository _repository;
  final AuthRepository _authRepository;
  final StorageService _storageService;
  final ImagePicker _imagePicker;

  UserProfile? profile;
  bool isLoading = false;
  String? errorMessage;

  bool get isDarkMode => ThemeService.to.isDarkMode.value;

  void switchTheme() {
    ThemeService.to.switchTheme();
  }

  String? get currentUserId => _authRepository.currentUser?.uid;

  Future<Map<String, dynamic>> getUserData() {
    return _authRepository.getUserData();
  }

  Future<void> signOut() {
    return _authRepository.logout();
  }

  Future<void> deleteAccount() {
    return _authRepository.deleteAccount();
  }

  Future<void> loadProfile() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      profile = await _repository.getCurrentUserProfile();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile(UserProfile nextProfile) async {
    await _repository.setCurrentUserProfile(nextProfile);
    profile = nextProfile;
    notifyListeners();
  }

  Future<ProfileSetupData> loadSetupData() async {
    final user = _authRepository.currentUser;
    var displayName =
        user?.displayName ?? user?.email?.split('@').first ?? 'User';

    final savedProfile = await _repository.getCurrentUserProfile();
    if (savedProfile != null) {
      await _cacheProfile(savedProfile);
      displayName = savedProfile.displayName.isNotEmpty
          ? savedProfile.displayName
          : displayName;

      return ProfileSetupData(
        displayName: displayName,
        bio: savedProfile.bio,
        currentLocation: savedProfile.currentLocation,
        avatarUrl: savedProfile.avatarUrl,
        tags: List<String>.from(savedProfile.tags),
        destinations: savedProfile.destinations
            .map((d) => {'city': d.city, 'date': d.date})
            .toList(),
        latitude: savedProfile.latitude,
        longitude: savedProfile.longitude,
      );
    }

    final cachedDisplayName = await _storageService.getProfileDisplayName();
    final cachedBio = await _storageService.getProfileBio();
    final cachedLocation = await _storageService.getProfileCurrentLocation();
    final cachedAvatarUrl = await _storageService.getProfileAvatarUrl();
    final cachedTags = await _storageService.getTravelerTags();

    if ((cachedDisplayName ?? '').isNotEmpty) {
      displayName = cachedDisplayName!;
    }

    return ProfileSetupData(
      displayName: displayName,
      bio: cachedBio ?? '',
      currentLocation: cachedLocation ?? '',
      avatarUrl: cachedAvatarUrl,
      tags: cachedTags,
      destinations: const [],
    );
  }

  Future<File?> pickProfileImage({
    required ProfileImageSource source,
    required double maxWidth,
    required double maxHeight,
    required int imageQuality,
    int? maxBytes,
    bool compress = false,
  }) async {
    final image = await _imagePicker.pickImage(
      source: source == ProfileImageSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    if (image == null) return null;

    var file = File(image.path);
    if (maxBytes != null) {
      final bytes = await file.readAsBytes();
      if (bytes.length > maxBytes) {
        throw Exception('Photo too large. Please choose an image under 2MB.');
      }
    }

    if (compress) {
      file = await pickAndCompressImage(file);
    }

    return file;
  }

  Future<String?> uploadProfileImage(String imagePath) async {
    final uid = _authRepository.currentUser?.uid ?? 'unknown';
    final fileName =
        'profileimg_${uid}_${DateTime.now().millisecondsSinceEpoch}.png';
    final imageName = await uploadImageToAWS(
      file: File(imagePath),
      fileName: fileName,
    );

    if (imageName == null || imageName.isEmpty) return null;
    return getUrlForUserUploadedImage(imageName);
  }

  Future<ProfileLocationResult> fetchCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception('Location services are disabled');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Enable in Settings',
      );
    }

    final position =
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Location fetching timed out'),
        );

    final placemarks = await geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    var display = '';
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      final city = place.locality?.isNotEmpty == true
          ? place.locality
          : place.subAdministrativeArea;
      final country = place.isoCountryCode ?? place.country;
      if (city != null && city.toString().isNotEmpty) {
        display = country != null && country.toString().isNotEmpty
            ? '$city, $country'
            : city.toString();
      } else if (place.administrativeArea != null &&
          place.administrativeArea!.isNotEmpty) {
        display = country != null && country.toString().isNotEmpty
            ? '${place.administrativeArea}, $country'
            : place.administrativeArea!;
      }
    }

    if (display.isEmpty) {
      display =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }

    return ProfileLocationResult(
      displayName: display,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<String?> saveEditedProfile({
    required String displayName,
    String? existingPhotoUrl,
    File? pickedImage,
  }) async {
    String? uploadedImageUrl;
    if (pickedImage != null) {
      uploadedImageUrl = await uploadProfileImage(pickedImage.path);
    }

    final finalPhotoUrl = uploadedImageUrl ?? existingPhotoUrl;
    await _authRepository.updateUserProfile(
      displayName: displayName,
      photoURL: uploadedImageUrl,
    );

    final updates = <String, dynamic>{'name': displayName};
    if ((finalPhotoUrl ?? '').isNotEmpty) {
      updates['photoURL'] = finalPhotoUrl;
    }
    await _authRepository.updateUserData(updates);

    await _storageService.setProfileDisplayName(displayName);
    if ((finalPhotoUrl ?? '').isNotEmpty) {
      await _storageService.setProfileAvatarUrl(finalPhotoUrl!);
    }

    return finalPhotoUrl;
  }

  Future<void> saveSetupProfile({
    required String displayName,
    required String bio,
    required String currentLocation,
    required List<String> tags,
    required List<Map<String, dynamic>> destinations,
    required double? latitude,
    required double? longitude,
    File? selectedImage,
    String? existingAvatarUrl,
  }) async {
    final user = _authRepository.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    var avatarUrl = existingAvatarUrl;
    if (selectedImage != null) {
      avatarUrl = await uploadProfileImage(selectedImage.path);
      if (avatarUrl == null) {
        throw Exception('Failed to upload image. Please try again.');
      }
    }

    final nextProfile = UserProfile(
      displayName: displayName.trim().isNotEmpty
          ? displayName.trim()
          : (user.displayName ?? ''),
      bio: bio,
      currentLocation: currentLocation,
      latitude: latitude,
      longitude: longitude,
      avatarUrl: avatarUrl,
      tags: tags,
      destinations: destinations
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

    await _repository.setCurrentUserProfile(nextProfile);
    await _cacheProfile(nextProfile);
  }

  Future<void> _cacheProfile(UserProfile nextProfile) async {
    await _storageService.setProfileDisplayName(nextProfile.displayName);
    await _storageService.setProfileBio(nextProfile.bio);
    await _storageService.setProfileCurrentLocation(
      nextProfile.currentLocation,
    );
    await _storageService.setProfileAvatarUrl(nextProfile.avatarUrl ?? '');
    await _storageService.setTravelerTags(nextProfile.tags);
    await _storageService.setProfileSetupCompleted(nextProfile.setupCompleted);
  }
}
