import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'subscriptions.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;
  const ReaderScreen(this.book, {super.key});
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final PageController _pc;
  int chapter = 0;
  double fontSize = 17, brightness = 1;
  bool night = false, chrome = true, serif = true;
  int theme = 0; // 0 paper, 1 sepia, 2 night

  @override
  void initState() {
    super.initState();
    final p = app.progress[widget.book.id] ?? 0;
    chapter = (p * readerChapters.length).floor().clamp(0, readerChapters.length - 1);
    _pc = PageController(initialPage: chapter);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Color get bg => switch (theme) { 1 => const Color(0xFFF3E6C8), 2 => const Color(0xFF14110F), _ => const Color(0xFFFFFCF5) };
  Color get fg => theme == 2 ? const Color(0xFFD8CBB8) : const Color(0xFF2B1B10);

  void _setProgress(double v) => app.progress[widget.book.id] = v.clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    final b = widget.book;
    final key = '$chapter:bm';
    final marked = app.bookmarks[b.id]?.contains(key) ?? false;
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Scaffold(
        backgroundColor: bg,
        body: Stack(children: [
          PageView.builder(
            controller: _pc,
            itemCount: readerChapters.length,
            onPageChanged: (i) => setState(() {
              chapter = i;
              _setProgress((i + 1) / readerChapters.length);
            }),
            itemBuilder: (_, ci) {
              final ch = readerChapters[ci];
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => chrome = !chrome),
                child: ListView(padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 70, 24, 120), children: [
                  Text(ch.title, style: TextStyle(fontSize: fontSize + 8, fontWeight: FontWeight.w800, color: BvtColors.deepSaffron, fontFamily: serif ? 'serif' : null)),
                  const SizedBox(height: 18),
                  for (var pi = 0; pi < ch.paragraphs.length; pi++) _para(b, ci, pi, ch.paragraphs[pi]),
                  const SizedBox(height: 30),
                  Center(child: Text(ci < readerChapters.length - 1 ? 'Swipe for next chapter →' : '— End of sample content —', style: TextStyle(color: fg.withValues(alpha: 0.5), fontSize: 12))),
                ]),
              );
            },
          ),
          // brightness overlay
          IgnorePointer(child: Container(color: Colors.black.withValues(alpha: (1 - brightness) * 0.7))),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: chrome ? 0 : -120,
            left: 0,
            right: 0,
            child: Material(
              color: bg.withValues(alpha: 0.97),
              elevation: 2,
              child: SafeArea(
                bottom: false,
                child: Row(children: [
                  IconButton(icon: Icon(Icons.arrow_back, color: fg), onPressed: () => Navigator.pop(context)),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
                    Row(children: [Icon(Icons.lock, size: 11, color: fg.withValues(alpha: 0.6)), const SizedBox(width: 3), Text('DRM protected · session valid 59:41', style: TextStyle(fontSize: 10.5, color: fg.withValues(alpha: 0.6)))]),
                  ])),
                  IconButton(tooltip: 'Bookmark', icon: Icon(marked ? Icons.bookmark : Icons.bookmark_border, color: marked ? BvtColors.saffron : fg), onPressed: () { final added = app.toggleMark(app.bookmarks, b.id, key); toast(context, added ? 'Bookmark added' : 'Bookmark removed', icon: Icons.bookmark); }),
                  IconButton(tooltip: 'Contents', icon: Icon(Icons.list, color: fg), onPressed: _contents),
                  IconButton(tooltip: 'Display settings', icon: Icon(Icons.text_fields, color: fg), onPressed: _settings),
                ]),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: chrome ? 0 : -120,
            left: 0,
            right: 0,
            child: Material(
              color: bg.withValues(alpha: 0.97),
              elevation: 4,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      Text('${chapter + 1}/${readerChapters.length}', style: TextStyle(color: fg, fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: chapter.toDouble(),
                          min: 0,
                          max: (readerChapters.length - 1).toDouble(),
                          divisions: readerChapters.length - 1,
                          onChanged: (v) => _pc.animateToPage(v.round(), duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                        ),
                      ),
                      Text('${(((chapter + 1) / readerChapters.length) * 100).round()}%', style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _para(Book b, int ci, int pi, String text) {
    final k = '$ci:$pi';
    final hl = app.highlights[b.id]?.contains(k) ?? false;
    return GestureDetector(
      onDoubleTap: () { final a = app.toggleMark(app.highlights, b.id, k); toast(context, a ? 'Highlight saved' : 'Highlight removed', icon: Icons.highlight); },
      onLongPress: () { final a = app.toggleMark(app.highlights, b.id, k); toast(context, a ? 'Highlight saved' : 'Highlight removed', icon: Icons.highlight); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: hl ? const EdgeInsets.all(6) : EdgeInsets.zero,
        decoration: hl ? BoxDecoration(color: BvtColors.saffron.withValues(alpha: 0.28), borderRadius: BorderRadius.circular(6)) : null,
        child: Text(text, style: TextStyle(fontSize: fontSize, height: 1.65, color: fg, fontFamily: serif ? 'serif' : null)),
      ),
    );
  }

  void _settings() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Display', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 10),
            Row(children: [const Text('A', style: TextStyle(fontSize: 13)), Expanded(child: Slider(value: fontSize, min: 13, max: 28, divisions: 15, label: '${fontSize.round()}', onChanged: (v) { set(() {}); setState(() => fontSize = v); })), const Text('A', style: TextStyle(fontSize: 26))]),
            Row(children: [const Icon(Icons.brightness_low), Expanded(child: Slider(value: brightness, min: 0.3, max: 1, onChanged: (v) { set(() {}); setState(() => brightness = v); })), const Icon(Icons.brightness_high)]),
            const SizedBox(height: 6),
            Wrap(spacing: 10, children: [
              for (final t in [(0, 'Paper', Icons.description_outlined), (1, 'Sepia', Icons.coffee_outlined), (2, 'Night', Icons.nightlight_round)])
                ChoiceChip(avatar: Icon(t.$3, size: 16), label: Text(t.$2), selected: theme == t.$1, onSelected: (_) { set(() {}); setState(() { theme = t.$1; night = t.$1 == 2; }); }),
            ]),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Serif typeface'), value: serif, onChanged: (v) { set(() {}); setState(() => serif = v); }),
          ]),
        ),
      ),
    );
  }

  void _contents() {
    final b = widget.book;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DefaultTabController(
        length: 3,
        child: ListenableBuilder(
          listenable: app,
          builder: (ctx, _) => Column(children: [
            const TabBar(tabs: [Tab(text: 'Chapters'), Tab(text: 'Bookmarks'), Tab(text: 'Highlights')]),
            Expanded(
              child: TabBarView(children: [
                ListView(children: [
                  for (var i = 0; i < readerChapters.length; i++)
                    ListTile(
                      selected: i == chapter,
                      leading: CircleAvatar(radius: 14, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                      title: Text(readerChapters[i].title),
                      trailing: IconButton(
                        tooltip: 'Download for offline',
                        icon: Icon(app.downloaded.contains('${b.id}:$i') ? Icons.download_done : Icons.download_outlined, color: app.downloaded.contains('${b.id}:$i') ? BvtColors.green : null),
                        onPressed: () => app.update(() => app.downloaded.contains('${b.id}:$i') ? app.downloaded.remove('${b.id}:$i') : app.downloaded.add('${b.id}:$i')),
                      ),
                      onTap: () { Navigator.pop(ctx); _pc.jumpToPage(i); },
                    ),
                  const Padding(padding: EdgeInsets.all(16), child: Text('Downloaded chapters stay encrypted and are bound to your account. DRM token is never written to disk.', style: TextStyle(fontSize: 12, color: BvtColors.muted))),
                ]),
                _markList(b, app.bookmarks, Icons.bookmark, 'No bookmarks yet', ctx),
                _markList(b, app.highlights, Icons.highlight, 'Double-tap a paragraph to highlight it', ctx),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _markList(Book b, Map<String, Set<String>> m, IconData icon, String empty, BuildContext ctx) {
    final items = (m[b.id] ?? {}).toList()..sort();
    if (items.isEmpty) return Center(child: Text(empty, style: const TextStyle(color: BvtColors.muted)));
    return ListView(children: [
      for (final k in items)
        ListTile(
          leading: Icon(icon, color: BvtColors.saffron),
          title: Text(readerChapters[int.parse(k.split(':')[0])].title),
          subtitle: k.endsWith('bm') ? const Text('Page bookmark') : Text(readerChapters[int.parse(k.split(':')[0])].paragraphs[int.parse(k.split(':')[1])], maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () { Navigator.pop(ctx); _pc.jumpToPage(int.parse(k.split(':')[0])); },
        ),
    ]);
  }
}

/// PDF-style sample preview used on product pages and the eBooks page.
class SampleReaderScreen extends StatefulWidget {
  final Book book;
  const SampleReaderScreen(this.book, {super.key});
  @override
  State<SampleReaderScreen> createState() => _SampleReaderScreenState();
}

class _SampleReaderScreenState extends State<SampleReaderScreen> {
  int page = 0;
  static const total = 6;
  @override
  Widget build(BuildContext context) {
    final b = widget.book;
    return Scaffold(
      backgroundColor: const Color(0xFF3A2F28),
      appBar: AppBar(backgroundColor: const Color(0xFF2A211B), foregroundColor: Colors.white, title: Text('Sample · ${b.title}', style: const TextStyle(fontSize: 15, color: Colors.white)), actions: [Center(child: Padding(padding: const EdgeInsets.only(right: 16), child: Text('${page + 1} / $total', style: const TextStyle(color: Colors.white70))))]),
      body: PageView.builder(
        itemCount: total,
        onPageChanged: (i) => setState(() => page = i),
        itemBuilder: (_, i) {
          if (i == total - 1) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.lock_outline, size: 44, color: BvtColors.saffron),
                      const SizedBox(height: 12),
                      const Text('End of sample', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                      const SizedBox(height: 6),
                      const Text('Continue reading with a subscription or buy the book.', textAlign: TextAlign.center, style: TextStyle(color: BvtColors.muted)),
                      const SizedBox(height: 18),
                      FilledButton(onPressed: () => push(context, PlansScreen(forBook: b)), child: Text(app.t('subscribe_to_read'))),
                      const SizedBox(height: 8),
                      OutlinedButton(onPressed: () { app.addToCart(b, b.purchasable.first); Navigator.pop(context); toast(context, 'Added to cart', icon: Icons.check_circle); }, child: Text('Buy · ${inr(b.basePrice)}')),
                    ]),
                  ),
                ),
              ),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: AspectRatio(
                aspectRatio: 0.68,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: const Color(0xFFFFFBF2), borderRadius: BorderRadius.circular(4), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 14)]),
                  child: Stack(children: [
                    Center(child: Transform.rotate(angle: -0.5, child: Text('SAMPLE', style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.black.withValues(alpha: 0.05))))),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (i == 0) ...[
                        const Spacer(),
                        Center(child: BookCover(b, width: 140)),
                        const SizedBox(height: 16),
                        Center(child: Text(b.title, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w800))),
                        const Spacer(),
                      ] else ...[
                        Text(i == 1 ? 'Copyright & Dedication' : i == 2 ? 'Contents' : 'Preface', style: const TextStyle(color: BvtColors.deepSaffron, fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 14),
                        for (var k = 0; k < 14; k++) Padding(padding: const EdgeInsets.only(bottom: 9), child: FractionallySizedBox(widthFactor: k % 5 == 4 ? 0.5 : 1, child: Container(height: 7, color: Colors.black12))),
                      ],
                      Center(child: Text('${i + 1}', style: const TextStyle(color: BvtColors.muted, fontSize: 12))),
                    ]),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
