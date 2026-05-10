import 'dart:io';

import 'package:backpackr/features/blogs/models/blog.dart';
import 'package:backpackr/features/blogs/data_sources/blog_service.dart';

class FirebaseBlogDataSource {
  FirebaseBlogDataSource({BlogService? blogService})
    : _blogService = blogService ?? BlogService();

  final BlogService _blogService;

  Future<List<Blog>> getAllBlogs() => _blogService.getAllBlogs();

  Future<List<Blog>> getUserBlogs(String userId) {
    return _blogService.getUserBlogs(userId);
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
    return _blogService.createBlog(
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

  Future<void> deleteBlog(String blogId) {
    return _blogService.deleteBlog(blogId);
  }
}
