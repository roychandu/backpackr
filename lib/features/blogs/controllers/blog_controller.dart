import 'dart:io';

import 'package:backpackr/features/auth/repositories/auth_repository.dart';
import 'package:backpackr/features/blogs/models/blog.dart';
import 'package:backpackr/features/blogs/repositories/blog_repository.dart';
import 'package:backpackr/shared/services/local_storage_service.dart';
import 'package:backpackr/shared/services/user_setup_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum BlogImageSource { camera, gallery }

class BlogController extends ChangeNotifier {
  BlogController({
    BlogRepository? repository,
    AuthRepository? authRepository,
    ImagePicker? imagePicker,
  }) : _repository = repository ?? BlogRepository(),
       _authRepository = authRepository ?? AuthRepository(),
       _imagePicker = imagePicker ?? ImagePicker();

  final BlogRepository _repository;
  final AuthRepository _authRepository;
  final ImagePicker _imagePicker;

  List<Blog> blogs = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadBlogs() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      blogs = await _repository.getAllBlogs();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<Blog> getCachedBlogs() {
    return LocalStorageService.getAllBlogs();
  }

  Future<List<Blog>> getAllBlogs() {
    return _repository.getAllBlogs();
  }

  Future<List<Blog>> getUserBlogs(String userId) {
    return _repository.getUserBlogs(userId);
  }

  Future<String> createBlog({
    required String title,
    required String description,
    required String startPlace,
    required String destination,
    required String distance,
    required String duration,
    required DateTime startDate,
    DateTime? endDate,
    required List<File> images,
    List<String> tags = const [],
  }) {
    return _repository.createBlog(
      title: title,
      description: description,
      startPlace: startPlace,
      destination: destination,
      distance: distance,
      duration: duration,
      startDate: startDate,
      endDate: endDate,
      images: images,
      tags: tags,
    );
  }

  Future<List<File>> pickImagesFromGallery({
    required int remainingSlots,
    double maxWidth = 1920,
    double maxHeight = 1080,
    int imageQuality = 85,
  }) async {
    if (remainingSlots <= 0) return [];

    final images = await _imagePicker.pickMultiImage(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    return images
        .take(remainingSlots)
        .map((image) => File(image.path))
        .toList();
  }

  Future<File?> pickImageFromCamera({
    double maxWidth = 1920,
    double maxHeight = 1080,
    int imageQuality = 85,
  }) async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    if (image == null) return null;
    return File(image.path);
  }

  Future<bool> hasCompletedSetup() {
    return UserSetupService.hasCompletedSetup();
  }

  Future<bool> isProfileStrictlyComplete() {
    return UserSetupService.isProfileStrictlyComplete();
  }

  Future<void> showSetupPopup(BuildContext context) {
    return UserSetupService.showSetupPopup(context);
  }

  Future<bool> hasAcceptedEula() {
    return _authRepository.hasAcceptedEula();
  }

  Future<void> acceptEula() {
    return _authRepository.acceptEula();
  }
}
