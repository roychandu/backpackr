import 'dart:io';

import 'package:backpackr/features/blogs/data_sources/firebase_blog_data_source.dart';
import 'package:backpackr/features/blogs/models/blog.dart';

class BlogRepository {
  BlogRepository({FirebaseBlogDataSource? dataSource})
    : _dataSource = dataSource ?? FirebaseBlogDataSource();

  final FirebaseBlogDataSource _dataSource;

  Future<List<Blog>> getAllBlogs() => _dataSource.getAllBlogs();

  Future<List<Blog>> getUserBlogs(String userId) {
    return _dataSource.getUserBlogs(userId);
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
    return _dataSource.createBlog(
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
    return _dataSource.deleteBlog(blogId);
  }
}
