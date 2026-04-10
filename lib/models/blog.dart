class Blog {
  final String id;
  final String title;
  final String content;
  final String author;
  final String authorId;
  final String startPlace;
  final String destination;
  final String distance;
  final String duration;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> tags;
  final List<String> imageUrls;
  final DateTime dateCreated;
  final int likes;
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
