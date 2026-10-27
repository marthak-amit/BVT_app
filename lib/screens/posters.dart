import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class PostersScreen extends StatelessWidget {
  const PostersScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: Text(app.t('posters'))),
          body: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, childAspectRatio: 0.66, mainAxisSpacing: 16, crossAxisSpacing: 16),
            itemCount: posters.length,
            itemBuilder: (_, i) {
              final p = posters[i];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => push(context, PosterViewer(i)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Center(child: LayoutBuilder(builder: (_, c) => Hero(tag: 'cover-${p.id}', child: BookCover(p, width: (c.maxWidth * 0.8).clamp(80, 170), showLang: false))))),
                  const SizedBox(height: 8),
                  Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Row(children: [PriceText(p.basePrice), const Spacer(), StockBadge(p)]),
                ]),
              );
            },
          ),
        ),
      );
}

class PosterViewer extends StatefulWidget {
  final int index;
  const PosterViewer(this.index, {super.key});
  @override
  State<PosterViewer> createState() => _PosterViewerState();
}

class _PosterViewerState extends State<PosterViewer> {
  late final PageController _pc = PageController(initialPage: widget.index);
  late int i = widget.index;
  @override
  Widget build(BuildContext context) {
    final p = posters[i];
    return ListenableBuilder(
      listenable: app,
      builder: (_, _) => Scaffold(
        backgroundColor: const Color(0xFF1B1411),
        appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, title: Text(p.title, style: const TextStyle(color: Colors.white)), actions: [IconButton(icon: Icon(app.wishlist.contains(p.id) ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent), onPressed: () => app.toggleWish(p.id))]),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2A211B),
            child: Row(children: [
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(inr(p.basePrice), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), const Text('A2 · 170 GSM matte', style: TextStyle(color: Colors.white60, fontSize: 12))]),
              const Spacer(),
              SizedBox(width: 170, child: AddButton(p, BookFormat.poster)),
            ]),
          ),
        ),
        body: Column(children: [
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: posters.length,
              onPageChanged: (v) => setState(() => i = v),
              itemBuilder: (_, k) => InteractiveViewer(minScale: 1, maxScale: 5, child: Center(child: Hero(tag: 'cover-${posters[k].id}', child: BookCover(posters[k], width: 280, showLang: false)))),
            ),
          ),
          const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('Pinch to zoom · swipe for more posters', style: TextStyle(color: Colors.white54, fontSize: 12))),
        ]),
      ),
    );
  }
}
