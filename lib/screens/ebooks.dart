import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home.dart';
import 'reader.dart';

class EbooksScreen extends StatelessWidget {
  final Book? highlight;
  const EbooksScreen({super.key, this.highlight});

  @override
  Widget build(BuildContext context) {
    final books = allBooks.where((b) => b.hasEbook).toList();
    if (highlight != null) {
      books.remove(highlight);
      books.insert(0, highlight!);
    }
    return Scaffold(
      appBar: AppBar(title: Text(app.t('ebooks'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: BvtColors.sand, borderRadius: BorderRadius.circular(14)),
          child: const Row(children: [Icon(Icons.info_outline, color: BvtColors.deepSaffron), SizedBox(width: 10), Expanded(child: Text('eBooks are sold on Kindle, Apple Books and Google Play. Purchases happen on those stores — there are no in-app purchases for eBooks. Prefer reading here? Try a reading subscription.', style: TextStyle(fontSize: 12.5, height: 1.4)))]),
        ),
        const SizedBox(height: 14),
        for (final b in books)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: b == highlight ? BvtColors.saffron : const Color(0xFFEBD9BC), width: b == highlight ? 2 : 1)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    InkWell(onTap: () => openBook(context, b), child: BookCover(b, width: 62)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('${langOf(b.language).name} · eBook ${inr(b.prices[BookFormat.ebook]!)}', style: const TextStyle(fontSize: 12.5, color: BvtColors.muted)),
                      const SizedBox(height: 6),
                      TextButton.icon(style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)), onPressed: () => push(context, SampleReaderScreen(b)), icon: const Icon(Icons.picture_as_pdf, size: 16), label: const Text('Free sample')),
                    ])),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    for (final s in ebookStores)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _open(context, s.$1, b),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(color: s.$3, borderRadius: BorderRadius.circular(10)),
                              child: Column(children: [Icon(s.$2, color: Colors.white, size: 20), const SizedBox(height: 2), Text(s.$1, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))]),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  void _open(BuildContext context, String store, Book b) {
    final url = switch (store) {
      'Kindle' => 'https://www.amazon.in/dp/${b.isbn.replaceAll('-', '')}',
      'Apple Books' => 'https://books.apple.com/in/book/${b.group}',
      _ => 'https://play.google.com/store/books/details?id=${b.group}',
    };
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Open $store'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('This deep-links to the ${b.title} listing in the $store app or website.'),
          const SizedBox(height: 10),
          SelectableText(url, style: const TextStyle(fontSize: 12, color: BvtColors.deepSaffron)),
        ]),
        actions: [
          TextButton(onPressed: () { Clipboard.setData(ClipboardData(text: url)); Navigator.pop(ctx); toast(context, 'Link copied', icon: Icons.check); }, child: const Text('Copy link')),
          FilledButton(onPressed: () { Navigator.pop(ctx); toast(context, 'Opening $store… (demo)', icon: Icons.open_in_new); }, child: const Text('Open')),
        ],
      ),
    );
  }
}
