import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home.dart';

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: Text(app.t('blog'))),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: app.blog.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (_, i) {
              final a = app.blog[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => push(context, ArticleScreen(a)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(height: 120, width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(colors: [a.color, shade(a.color, -0.15)])), child: Icon(Icons.auto_stories, size: 56, color: Colors.white.withValues(alpha: 0.5))),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, height: 1.25)),
                        const SizedBox(height: 6),
                        Text(a.excerpt, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: BvtColors.muted)),
                        const SizedBox(height: 8),
                        Text('${a.author} · ${a.date} · ${a.readTime} read', style: const TextStyle(fontSize: 12, color: BvtColors.muted)),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      );
}

class ArticleScreen extends StatelessWidget {
  final Article a;
  const ArticleScreen(this.a, {super.key});
  @override
  Widget build(BuildContext context) {
    final related = <Book>[];
    for (final g in a.relatedGroups) {
      final cand = catalog.where((b) => b.group == g);
      if (cand.isEmpty) continue;
      related.add(cand.firstWhere((b) => b.language == app.preferredBookLang, orElse: () => cand.first));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Article')),
      body: ListView(children: [
        Container(height: 180, decoration: BoxDecoration(gradient: LinearGradient(colors: [a.color, shade(a.color, -0.2)])), child: Center(child: Icon(Icons.spa, size: 80, color: Colors.white.withValues(alpha: 0.4)))),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, height: 1.2)),
            const SizedBox(height: 8),
            Text('${a.author} · ${a.date} · ${a.readTime} read', style: const TextStyle(color: BvtColors.muted, fontSize: 12.5)),
            const SizedBox(height: 18),
            for (final p in a.body) Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(p, style: const TextStyle(fontSize: 16, height: 1.65))),
            const Divider(height: 36),
            const Text('Related books', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ]),
        ),
        Shelf(related, onTap: (b) => openBook(context, b)),
        const SizedBox(height: 30),
      ]),
    );
  }
}
