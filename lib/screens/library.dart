import 'package:flutter/material.dart';

import "../data/catalog.dart";
import "../data/models.dart";
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth.dart';
import 'reader.dart';
import 'subscriptions.dart';

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          if (!app.loggedIn) {
            return Scaffold(
              appBar: AppBar(title: Text(app.t('library'))),
              body: EmptyState(Icons.auto_stories, 'Your digital library', 'Sign in to see books unlocked by your reading subscriptions, with progress synced across devices.', action: 'Sign in', onAction: () => push(context, const LoginScreen())),
            );
          }
          final lib = app.library;
          final reading = lib.where((b) => app.progress.containsKey(b.id)).toList();
          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: Text(app.t('library')),
                actions: [TextButton.icon(onPressed: () => push(context, const ManageSubscriptionsScreen()), icon: const Icon(Icons.workspace_premium, size: 18), label: const Text('Manage'))],
                bottom: const TabBar(tabs: [Tab(text: 'Reading'), Tab(text: 'All access'), Tab(text: 'Offline')]),
              ),
              body: TabBarView(children: [
                reading.isEmpty
                    ? EmptyState(Icons.menu_book, 'Nothing in progress', 'Open any unlocked title to start reading.', action: 'Browse plans', onAction: () => push(context, const PlansScreen()))
                    : ListView(padding: const EdgeInsets.all(16), children: [for (final b in reading) _Row(b)]),
                lib.isEmpty
                    ? EmptyState(Icons.lock_outline, 'No subscriptions yet', 'Start a free trial to unlock books.', action: 'View plans', onAction: () => push(context, const PlansScreen()))
                    : ListView(padding: const EdgeInsets.all(16), children: [
                        for (final s in app.subscriptions.where((s) => s.status != 'cancelled'))
                          Padding(padding: const EdgeInsets.only(bottom: 8), child: Pill('${s.title} · ${s.status}', color: BvtColors.deepSaffron, icon: Icons.verified)),
                        const SizedBox(height: 8),
                        for (final b in lib) _Row(b),
                      ]),
                _Offline(),
              ]),
            ),
          );
        },
      );
}

class _Row extends StatelessWidget {
  final Book b;
  const _Row(this.b);
  @override
  Widget build(BuildContext context) {
    final p = app.progress[b.id] ?? 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => push(context, ReaderScreen(b)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              BookCover(b, width: 56, showLang: false),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(langOf(b.language).name, style: const TextStyle(fontSize: 12, color: BvtColors.muted)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: p, minHeight: 5, borderRadius: BorderRadius.circular(3), color: BvtColors.saffron, backgroundColor: BvtColors.sand),
                const SizedBox(height: 3),
                Text(p == 0 ? 'Not started' : '${(p * 100).round()}% read · synced', style: const TextStyle(fontSize: 11.5, color: BvtColors.muted)),
              ])),
              const Icon(Icons.chevron_right),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Offline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = app.downloaded.toList();
    if (items.isEmpty) return const EmptyState(Icons.download_for_offline_outlined, 'No offline chapters', 'Open the reader → Contents → tap the download icon next to a chapter.');
    return ListView(padding: const EdgeInsets.all(16), children: [
      for (final k in items)
        ListTile(
          leading: const Icon(Icons.download_done, color: BvtColors.green),
          title: Text(bookById(k.split(':')[0]).title),
          subtitle: Text(readerChapters[int.parse(k.split(':')[1])].title),
          trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => app.update(() => app.downloaded.remove(k))),
        ),
    ]);
  }
}
