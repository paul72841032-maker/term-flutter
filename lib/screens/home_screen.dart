import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/posts_service.dart';
import '../ui/glass.dart';
import 'post_detail_screen.dart';
import 'post_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const categories = ['전체', '자유', '공지', 'QnA'];
  String selected = '전체';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // ✅ 웹과 같은 느낌: 어두운 보라/남색 그라데이션
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.25,
            colors: [
              Color(0xFF3B2A78),
              Color(0xFF0B1020),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    GlassIconButton(
                      icon: Icons.home_rounded,
                      onTap: () => setState(() => selected = '전체'),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Community',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    _LoginArea(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '커뮤니티',
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                      ),
                    ),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selected,
                          dropdownColor: const Color(0xFF1A223A),
                          items: categories
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setState(() => selected = v ?? '전체'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    selected == '전체' ? '전체 글' : '$selected 글',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Post>>(
                  stream: PostsService.streamPosts(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final all = snap.data!;
                    final posts = selected == '전체'
                        ? all
                        : all.where((p) => p.category == selected).toList();

                    if (posts.isEmpty) {
                      return const Center(child: Text('글이 없습니다.'));
                    }

                    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                      itemCount: posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final p = posts[i];
                        final mine = uid.isNotEmpty && p.authorId == uid;

                        return GlassCard(
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PostDetailScreen(postId: p.id),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Pill(text: p.category),
                                      const SizedBox(width: 8),
                                      if (mine) const Pill(text: '내 글'),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    p.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    p.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '작성자: ${p.authorName}',
                                    style: const TextStyle(color: Colors.white60),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostEditorScreen(mode: EditorMode.create)),
        ),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('글 작성'),
      ),
    );
  }
}

class _LoginArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;

        // 로그인 안 됨(거의 없음) -> 로그인 버튼
        if (user == null) {
          return GlassButton(
            text: '로그인',
            icon: Icons.login_rounded,
            onTap: () async {
              try {
                await AuthService.signInWithGoogle();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('로그인 실패: $e')),
                  );
                }
              }
            },
          );
        }

        // 익명 -> "Google 로그인" 버튼 보여주기 (지금 니가 원하는 동작)
        if (user.isAnonymous) {
          return GlassButton(
            text: 'Google 로그인',
            icon: Icons.login_rounded,
            onTap: () async {
              try {
                await AuthService.signInWithGoogle();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('로그인 완료')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('로그인 실패: $e')),
                  );
                }
              }
            },
          );
        }

        // 구글 로그인 완료 -> 로그아웃
        return GlassButton(
          text: '로그아웃',
          icon: Icons.logout_rounded,
          onTap: () async {
            await AuthService.signOut();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그아웃 완료')),
              );
            }
          },
        );
      },
    );
  }
}
