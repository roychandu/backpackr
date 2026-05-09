import 'package:hive/hive.dart';

part 'blog.g.dart';

@HiveType(typeId: 5)
class Blog {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String content;
  @HiveField(3)
  final String author;
  @HiveField(4)
  final String authorId;
  @HiveField(5)
  final String startPlace;
  @HiveField(6)
  final String destination;
  @HiveField(7)
  final String distance;
  @HiveField(8)
  final String duration;
  @HiveField(9)
  final DateTime startDate;
  @HiveField(10)
  final DateTime? endDate;
  @HiveField(11)
  final List<String> tags;
  @HiveField(12)
  final List<String> imageUrls;
  @HiveField(13)
  final DateTime dateCreated;
  @HiveField(14)
  final int likes;
  @HiveField(15)
  final int comments;

  Blog({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.authorId,
    required this.startPlace,
    required this.destination,
    required this.distance,
    required this.duration,
    required this.startDate,
    this.endDate,
    required this.tags,
    required this.imageUrls,
    required this.dateCreated,
    this.likes = 0,
    this.comments = 0,
  });

  // Factory method to create from Firebase data
  factory Blog.fromMap(Map<String, dynamic> data) {
    return Blog(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      author: data['author'] ?? '',
      authorId: data['authorId'] ?? '',
      startPlace: data['startPlace'] ?? '',
      destination: data['destination'] ?? '',
      distance: data['distance'] ?? '',
      duration: data['duration'] ?? '',
      startDate: DateTime.parse(
        data['startDate'] ?? DateTime.now().toIso8601String(),
      ),
      endDate: data['endDate'] != null ? DateTime.parse(data['endDate']) : null,
      tags: List<String>.from(data['tags'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      dateCreated: DateTime.parse(
        data['dateCreated'] ?? DateTime.now().toIso8601String(),
      ),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
    );
  }

  // Convert to Map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      'authorId': authorId,
      'startPlace': startPlace,
      'destination': destination,
      'distance': distance,
      'duration': duration,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'tags': tags,
      'imageUrls': imageUrls,
      'dateCreated': dateCreated.toIso8601String(),
      'likes': likes,
      'comments': comments,
    };
  }
}
