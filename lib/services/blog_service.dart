// ignore_for_file: avoid_print

import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/blog.dart';
import '../aws/aws_module.dart';
import 'package:backpackr/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';

class BlogService {
  static final BlogService _instance = BlogService._internal();
  factory BlogService() => _instance;
  BlogService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Database references
  DatabaseReference get _userProfilesRef => _database.ref('userProfiles');

  /// Get user's display name
  Future<String> _getUserDisplayName(String uid) async {
    try {
      final snapshot = await _userProfilesRef.child(uid).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data['name'] ?? data['displayName'] ?? 'Anonymous User';
      }
    } catch (e) {
      debugPrint('Error getting user display name: $e');
    }
    return 'Anonymous User';
  }

  /// Upload images to AWS and return URLs
  Future<List<String>> _uploadImages(List<File> images) async {
    final List<String> imageUrls = [];

    for (int i = 0; i < images.length; i++) {
      try {
        final fileName =
            "blogimg_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg";

        final uploadedFileName = await uploadImageToAWS(
          file: images[i],
          fileName: fileName,
        );

        if (uploadedFileName != null && uploadedFileName.isNotEmpty) {
          final imageUrl = getUrlForUserUploadedImage(uploadedFileName);
          imageUrls.add(imageUrl);
          debugPrint('Uploaded image $i: $imageUrl');
        }
      } catch (e) {
        debugPrint('Error uploading image $i: $e');
        // Continue with other images even if one fails
      }
    }

    return imageUrls;
  }

  /// Create a new blog post
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
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (images.isEmpty) {
      throw Exception('At least one image is required');
    }

    // Upload images to AWS
    debugPrint('Uploading ${images.length} images...');
    final imageUrls = await _uploadImages(images);

    if (imageUrls.isEmpty) {
      throw Exception('Failed to upload images');
    }

    // Get user's display name
    final userName = await _getUserDisplayName(currentUserId!);

    // Generate blog ID
    final blogRef = _userProfilesRef
        .child(currentUserId!)
        .child('travelingBlogs')
        .push();
    final blogId = blogRef.key!;

    final now = DateTime.now();

    final blog = Blog(
      id: blogId,
      title: title,
      content: description,
      author: userName,
      authorId: currentUserId!,
      startPlace: startPlace,
      destination: destination,
      distance: distance,
      duration: duration,
      startDate: startDate,
      endDate: endDate,
      tags: tags,
      imageUrls: imageUrls,
      dateCreated: now,
      likes: 0,
      comments: 0,
    );

    // Save blog to Firebase
    await blogRef.set(blog.toMap());

    // Save blog locally
    await LocalStorageService.saveBlog(blog);

    debugPrint('Blog created successfully with ID: $blogId');
    return blogId;
  }

  /// Get all blogs for current user
  Future<List<Blog>> getAllBlogs() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final snapshot = await _userProfilesRef
          .child(currentUserId!)
          .child('travelingBlogs')
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final List<Blog> blogs = [];

      for (final child in snapshot.children) {
        try {
          final blogData = Map<String, dynamic>.from(
            child.value as Map<dynamic, dynamic>,
          );
          final blog = Blog.fromMap(blogData);
          blogs.add(blog);
        } catch (e) {
          debugPrint('Error parsing blog: $e');
        }
      }

      // Sort by date created (newest first)
      blogs.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

      // Save to local storage for offline access
      await LocalStorageService.saveAllBlogs(blogs);

      debugPrint(
        'Loaded ${blogs.length} blogs for current user $currentUserId',
      );
      return blogs;
    } catch (e) {
      debugPrint('Error loading blogs: $e');
      throw Exception('Failed to load blogs: $e');
    }
  }

  /// Get blogs by a specific user
  Future<List<Blog>> getUserBlogs(String userId) async {
    try {
      final path = 'userProfiles/$userId/travelingBlogs';
      debugPrint('Accessing Firebase path: $path');

      final snapshot = await _userProfilesRef
          .child(userId)
          .child('travelingBlogs')
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final List<Blog> blogs = [];

      for (final child in snapshot.children) {
        try {
          final blogData = Map<String, dynamic>.from(
            child.value as Map<dynamic, dynamic>,
          );
          final blog = Blog.fromMap(blogData);
          blogs.add(blog);
        } catch (e) {
          debugPrint('Error parsing blog: $e');
        }
      }

      // Sort by date created (newest first)
      blogs.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

      return blogs;
    } catch (e) {
      debugPrint('Error loading user blogs: $e');
      throw Exception('Failed to load user blogs: $e');
    }
  }

  /// Delete a blog
  Future<void> deleteBlog(String blogId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _userProfilesRef
          .child(currentUserId!)
          .child('travelingBlogs')
          .child(blogId)
          .remove();

      // Delete from local storage
      await LocalStorageService.deleteBlog(blogId);

      debugPrint('Blog deleted successfully: $blogId');
    } catch (e) {
      debugPrint('Error deleting blog: $e');
      throw Exception('Failed to delete blog: $e');
    }
  }
}

void debugPrint(String message) {
  print(message);
}
