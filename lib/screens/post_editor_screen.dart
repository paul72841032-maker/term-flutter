import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/posts_service.dart';
import '../ui/glass.dart';

enum EditorMode { create, edit }

class PostEditorScreen extends StatefulWidget {
  final EditorMode mode;
  final String? postId;
  final String? initialTitle;
  final String? initialContent;
  final String? initialCategory;

  const PostEditorScreen({
    super.key,
    required this.mode,
    this.postId,
    this.initialTitle,
    this.initialContent,
    this.initialCategory,
  });

  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  static const categories = ['자유', '공지', 'QnA'];

  late final TextEditingController titleCtl;
  late final TextEditingController contentCtl;
  late String category;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    titleCtl = TextEditingController(text: widget.initialTitle ?? '');
    contentCtl = TextEditingController(text: widget.initialContent ?? '');
    category = widget.initialCategory ?? categories.first;
  }

  @override
  void dispose() {
    titleCtl.dispose();
    contentCtl.dispose();
    super.dispose();
  }

  Future<void> onSave() async {
    final title = titleCtl.text.trim();
    final content = contentCtl.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목/내용을 입력하세요')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final user = AuthService.user;
      if (user == null) throw Exception('Not signed in');

      if (widget.mode == EditorMode.create) {
        await PostsService.createPost(
          title: title,
          content: content,
          category: category,
          authorId: user.uid,
          authorName: user.isAnonymous ? 'anonymous' : (user.displayName ?? user.email ?? 'user'),
        );
      } else {
        await PostsService.updatePost(
          id: widget.postId!,
          title: title,
          content: content,
          category: category,
        );
      }

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.mode == EditorMode.edit;

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
          child: Column(
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
                    Text(isEdit ? '글 수정' : '글 작성',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    GlassButton(
                      text: saving ? '저장중...' : '저장',
                      icon: Icons.check_rounded,
                      onTap: saving ? null : onSave,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: DropdownButtonFormField<String>(
                        value: category,
                        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: saving ? null : (v) => setState(() => category = v ?? categories.first),
                        decoration: const InputDecoration(
                          labelText: '카테고리',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: TextField(
                        controller: titleCtl,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: '제목',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: TextField(
                        controller: contentCtl,
                        enabled: !saving,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          labelText: '내용',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
