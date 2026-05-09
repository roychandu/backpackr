import 'package:backpackr/features/blogs/models/blog.dart';
import 'package:backpackr/features/blogs/repositories/blog_repository.dart';
import 'package:flutter/foundation.dart';

class BlogController extends ChangeNotifier {
  BlogController({BlogRepository? repository})
    : _repository = repository ?? BlogRepository();

  final BlogRepository _repository;

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
}
