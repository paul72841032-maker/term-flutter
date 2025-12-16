import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String title;
  final String content;
  final String category;
  final String authorId;
  final String authorName;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.authorId,
    required this.authorName,
    this.createdAt,
    this.updatedAt,
  });

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Post(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      content: (data['content'] ?? '') as String,
      category: (data['category'] ?? '자유') as String,
      authorId: (data['authorId'] ?? '') as String,
      authorName: (data['authorName'] ?? 'anonymous') as String,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }
}
