import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/post.dart';
import '../services/posts_service.dart';
import '../ui/glass.dart';
import 'post_editor_screen.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.25,
            colors: [Color(0xFF3B2A78), Color(0xFF0B1020)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<Post?>(
            stream: PostsService.streamPost(postId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final post = snap.data;
              if (post == null) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Row(
                        children: [
                          GlassIconButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 10),
                          const Text('게시글', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    const Expanded(child: Center(child: Text('없는 글입니다.'))),
                  ],
                );
              }

              final mine = uid.isNotEmpty && post.authorId == uid;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Row(
                      children: [
                        GlassIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10),
                        const Text('게시글', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        const Spacer(),
                        if (mine) ...[
                          GlassIconButton(
                            icon: Icons.edit_rounded,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PostEditorScreen(
                                  mode: EditorMode.edit,
                                  postId: post.id,
                                  initialTitle: post.title,
                                  initialContent: post.content,
                                  initialCategory: post.category,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GlassIconButton(
                            icon: Icons.delete_outline_rounded,
                            onTap: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('삭제'),
                                  content: const Text('정말 삭제할까요?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await PostsService.deletePost(post.id);
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              children: [
                                Pill(text: post.category),
                                if (mine) const Pill(text: '내 글'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              post.title,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            Text('작성자: ${post.authorName}', style: const TextStyle(color: Colors.white70)),
                            const Divider(height: 24),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(post.content, style: const TextStyle(fontSize: 16, height: 1.45)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
