import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

class PostsService {
  static final _db = FirebaseFirestore.instance;

  static Stream<List<Post>> streamPosts() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .withConverter<Post>(
          fromFirestore: (snap, _) => Post.fromDoc(snap),
          toFirestore: (_, __) => {},
        )
        .snapshots()
        .map((qs) => qs.docs.map((d) => d.data()).toList());
  }

  static Stream<Post?> streamPost(String id) {
    return _db
        .collection('posts')
        .doc(id)
        .withConverter<Post>(
          fromFirestore: (snap, _) => Post.fromDoc(snap),
          toFirestore: (_, __) => {},
        )
        .snapshots()
        .map((snap) => snap.data());
  }

  static Future<void> createPost({
    required String title,
    required String content,
    required String category,
    required String authorId,
    required String authorName,
  }) async {
    await _db.collection('posts').add({
      'title': title.trim(),
      'content': content.trim(),
      'category': category,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updatePost({
    required String id,
    required String title,
    required String content,
    required String category,
  }) async {
    await _db.collection('posts').doc(id).update({
      'title': title.trim(),
      'content': content.trim(),
      'category': category,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deletePost(String id) async {
    await _db.collection('posts').doc(id).delete();
  }
}
