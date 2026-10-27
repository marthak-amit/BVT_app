import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/recs.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth.dart';
import 'checkout.dart';
import 'ebooks.dart';
import 'home.dart';
import 'reader.dart';
import 'subscriptions.dart';

class ProductScreen extends StatefulWidget {
  final Book book;
  const ProductScreen(this.book, {super.key});
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late Book book = widget.book;
  late BookFormat format = book.purchasable.first;
  int qty = 1;
  int gallery = 0;
  final _pin = TextEditingController();
  String eta = '';
  final List<Review> myReviews = [];

  @override
  void initState() {
    super.initState();
    app.viewed(book.id);
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _switchLang(Book b) {
    setState(() {
      book = b;
      format = b.purchasable.contains(format) ? format : b.purchasable.first;
      app.viewed(b.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final price = book.prices[format] ?? book.basePrice;
        final bulk = app.bulkPct(qty);
        final sibs = siblings(book);
        final access = app.hasAccess(book);
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(icon: Icon(app.wishlist.contains(book.id) ? Icons.favorite : Icons.favorite_border, color: BvtColors.red), onPressed: () {
                app.toggleWish(book.id);
                if (app.wishlist.contains(book.id)) toast(context, 'Saved to wishlist', icon: Icons.favorite);
              }),
              IconButton(icon: const Icon(Icons.share_outlined), onPressed: () => _share(context)),
              IconButton(
                icon: Badge(isLabelVisible: app.cartCount > 0, label: Text('${app.cartCount}'), child: const Icon(Icons.shopping_cart_outlined)),
                onPressed: () { tabIndex.value = 3; Navigator.of(context).popUntil((r) => r.isFirst); },
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -4))]),
              child: Row(children: [
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  PriceText(bulk > 0 ? (price * (1 - bulk)).round() : price, mrp: bulk > 0 ? price : null, size: 20),
                  Text(format.label, style: const TextStyle(fontSize: 11.5, color: BvtColors.muted)),
                ]),
                const SizedBox(width: 14),
                Expanded(
                  child: access
                      ? FilledButton.icon(onPressed: () => push(context, ReaderScreen(book)), icon: const Icon(Icons.auto_stories), label: Text(app.t('continue_reading')))
                      : Row(children: [
                          Expanded(flex: 6, child: AddButton(book, format, qty: qty)),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: OutlinedButton(
                              onPressed: !app.inStock(book) ? null : () {
                                app.addToCart(book, format, qty: qty);
                                push(context, const CheckoutScreen());
                              },
                              child: Text(app.t('buy_now')),
                            ),
                          ),
                        ]),
                ),
              ]),
            ),
          ),
          body: ListView(padding: EdgeInsets.zero, children: [
            _Gallery(book: book, index: gallery, onChanged: (i) => setState(() => gallery = i)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 6, children: [
                  Pill(book.category, color: BvtColors.maroon),
                  if (book.isNew) const Pill('NEW', color: BvtColors.green),
                  if (book.subEligible && !book.isPoster) const Pill('Subscription eligible', color: BvtColors.deepSaffron, icon: Icons.auto_stories),
                  if (app.pinned.contains(book.id)) const Pill('Sponsored', color: BvtColors.gold),
                ]),
                const SizedBox(height: 10),
                Text(book.title, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.2, fontSize: 25, fontFamily: 'Playfair', fontFamilyFallback: kFontFallback)),
                const SizedBox(height: 4),
                Text('by ${book.author}', style: const TextStyle(color: BvtColors.muted)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => Scrollable.ensureVisible(_reviewsKey.currentContext!, duration: const Duration(milliseconds: 400)),
                  child: Row(children: [Stars(book.rating, size: 18), const SizedBox(width: 8), Text('${book.rating.toStringAsFixed(1)}  ·  ${book.ratingCount + myReviews.length} ratings', style: const TextStyle(fontWeight: FontWeight.w600))]),
                ),
                const SizedBox(height: 14),
                Row(children: [PriceText(price, size: 26), const SizedBox(width: 10), StockBadge(book)]),
                const Text('Inclusive of all taxes', style: TextStyle(fontSize: 11.5, color: BvtColors.muted)),
              ]),
            ),
            if (sibs.length > 1) ...[
              const _Label('Language'),
              SizedBox(
                height: 40,
                child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                  for (final s in sibs)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(langOf(s.language).native),
                        selected: s.id == book.id,
                        onSelected: (_) => _switchLang(s),
                      ),
                    ),
                ]),
              ),
            ],
            if (!book.isPoster) ...[
              const _Label('Format'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final f in book.prices.keys)
                    ChoiceChip(
                      avatar: Icon(f.icon, size: 16),
                      label: Text('${f.label} · ${inr(book.prices[f]!)}'),
                      selected: f == format,
                      onSelected: (_) {
                        if (f == BookFormat.ebook) {
                          push(context, EbooksScreen(highlight: book));
                        } else {
                          setState(() => format = f);
                        }
                      },
                    ),
                ]),
              ),
            ],
            if (!access && !book.isPoster) _SubscribeBox(book: book),
            if (!book.isPoster)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: OutlinedButton.icon(
                  onPressed: () => push(context, SampleReaderScreen(book)),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Read sample (PDF preview)'),
                ),
              ),
            const _Label('Quantity'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                QtyStepper(qty, (v) => setState(() => qty = v.clamp(1, 500))),
                const SizedBox(width: 12),
                Expanded(child: Text(bulk > 0 ? '🎉 Bulk price: ${(bulk * 100).round()}% off at $qty+' : 'Buy 10+ for 10% off · 50+ for 20% · 100+ for 25%', style: TextStyle(fontSize: 12.5, color: bulk > 0 ? BvtColors.green : BvtColors.muted, fontWeight: bulk > 0 ? FontWeight.w700 : FontWeight.w400))),
              ]),
            ),
            const _Label('Delivery'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _pin,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(hintText: 'Enter PIN code', counterText: '', prefixIcon: Icon(Icons.location_on_outlined)),
                      onChanged: (v) => setState(() => eta = app.estimateEta(v)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(onPressed: () => setState(() => eta = app.estimateEta(_pin.text)), child: const Text('Check')),
                ]),
                if (eta.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('🚚 $eta · Free on orders above ₹999', style: const TextStyle(color: BvtColors.green, fontWeight: FontWeight.w600))),
                const SizedBox(height: 4),
                const Text('Ships worldwide via Delhivery / Shiprocket. COD available in India (physical books).', style: TextStyle(fontSize: 12, color: BvtColors.muted)),
              ]),
            ),
            const SectionHeader('About this book'),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(book.description, style: const TextStyle(height: 1.5))),
            const SectionHeader('Details'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(children: [
                    _Detail('Publisher', 'Bhakti Vikas Trust'),
                    _Detail('Language', '${langOf(book.language).name} (${langOf(book.language).native})'),
                    _Detail(book.isPoster ? 'Size' : 'Pages', book.isPoster ? 'A2 (420 × 594 mm)' : '${book.pages}'),
                    _Detail('ISBN / SKU', book.isbn),
                    _Detail('Category', book.category),
                    _Detail('HSN code', book.isPoster ? '4911' : '4901'),
                  ]),
                ),
              ),
            ),
            SectionHeader('Customers also bought', icon: Icons.people_outline),
            Shelf(alsoBought(book), onTap: (b) => openBook(context, b)),
            SectionHeader('Related books', icon: Icons.menu_book),
            Shelf(relatedBooks(book), onTap: (b) => openBook(context, b)),
            Container(key: _reviewsKey),
            _Reviews(book: book, mine: myReviews, onAdd: (r) => setState(() => myReviews.insert(0, r))),
          ]),
        );
      },
    );
  }

  final _reviewsKey = GlobalKey();

  void _share(BuildContext context) {
    final link = 'https://books.bvks.com/book/${book.id}.html';
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Share this book', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: BvtColors.sand, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Expanded(child: Text(link, style: const TextStyle(fontSize: 12.5))),
              IconButton(icon: const Icon(Icons.copy), onPressed: () { Clipboard.setData(ClipboardData(text: link)); Navigator.pop(context); toast(context, 'Link copied', icon: Icons.check); }),
            ]),
          ),
          const SizedBox(height: 6),
          const Text('App link: opens this page directly in the BVT app (Universal Links / App Links).', style: TextStyle(fontSize: 12, color: BvtColors.muted)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            for (final s in [('WhatsApp', Icons.chat, BvtColors.whatsapp), ('Facebook', Icons.facebook, const Color(0xFF1877F2)), ('X', Icons.alternate_email, Colors.black), ('Email', Icons.mail_outline, BvtColors.maroon)])
              InkWell(
                onTap: () { Navigator.pop(context); toast(context, 'Shared via ${s.$1} (demo)', icon: Icons.send); },
                child: Column(children: [CircleAvatar(radius: 26, backgroundColor: s.$3.withValues(alpha: 0.15), child: Icon(s.$2, color: s.$3)), const SizedBox(height: 6), Text(s.$1, style: const TextStyle(fontSize: 12))]),
              ),
          ]),
        ]),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String t;
  const _Label(this.t);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 8), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)));
}

class _Detail extends StatelessWidget {
  final String k, v;
  const _Detail(this.k, this.v);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(color: BvtColors.muted))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}

class _Gallery extends StatelessWidget {
  final Book book;
  final int index;
  final ValueChanged<int> onChanged;
  const _Gallery({required this.book, required this.index, required this.onChanged});

  Widget _slide(int i, double w) {
    switch (i) {
      case 0:
        return Hero(tag: 'cover-${book.id}', child: BookCover(book, width: w));
      case 1:
        return Container(
          width: w,
          height: book.isPoster ? w * 1.3 : w * 1.5,
          padding: EdgeInsets.all(w * 0.1),
          decoration: BoxDecoration(color: shade(book.color, -0.2), borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(2, 4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BACK COVER', style: TextStyle(color: Colors.white54, fontSize: w * 0.05, letterSpacing: 1.5)),
            SizedBox(height: w * 0.06),
            Text(book.description.split('.').first, maxLines: 6, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: w * 0.065, height: 1.35)),
            const Spacer(),
            Text('ISBN ${book.isbn}', style: TextStyle(color: Colors.white70, fontSize: w * 0.045)),
            Text('Bhakti Vikas Trust', style: TextStyle(color: BvtColors.gold, fontSize: w * 0.055, fontWeight: FontWeight.w700)),
          ]),
        );
      default:
        return Container(
          width: w,
          height: book.isPoster ? w * 1.3 : w * 1.5,
          padding: EdgeInsets.all(w * 0.09),
          decoration: BoxDecoration(color: const Color(0xFFFFFBF2), borderRadius: BorderRadius.circular(6), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(2, 4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Sample page', style: TextStyle(color: BvtColors.maroon, fontWeight: FontWeight.w800, fontSize: w * 0.07)),
            SizedBox(height: w * 0.05),
            for (var k = 0; k < 11; k++) Padding(padding: EdgeInsets.only(bottom: w * 0.035), child: Container(height: w * 0.022, width: k % 4 == 3 ? w * 0.4 : double.infinity, color: Colors.black12)),
          ]),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    const n = 3;
    return Column(children: [
      Container(
        height: 330 + MediaQuery.of(context).padding.top + 40,
        width: double.infinity,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [shade(book.color, 0.42), BvtColors.cream])),
        child: PageView.builder(
          itemCount: n,
          onPageChanged: onChanged,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => Dialog.fullscreen(
                backgroundColor: Colors.black87,
                child: Stack(children: [
                  Center(child: InteractiveViewer(minScale: 0.8, maxScale: 4, child: _slide(i, 300))),
                  Positioned(top: 30, right: 10, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
                  const Positioned(bottom: 40, left: 0, right: 0, child: Text('Pinch to zoom', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70))),
                ]),
              ),
            ),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: _slide(i, 190))),
          ),
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < n; i++)
          Container(margin: const EdgeInsets.all(4), width: i == index ? 18 : 7, height: 7, decoration: BoxDecoration(color: i == index ? BvtColors.saffron : const Color(0xFFE2CFAE), borderRadius: BorderRadius.circular(4))),
      ]),
    ]);
  }
}

class _SubscribeBox extends StatelessWidget {
  final Book book;
  const _SubscribeBox({required this.book});
  @override
  Widget build(BuildContext context) {
    if (!book.subEligible) {
      return const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 0), child: Text('This title is not available with reading subscriptions.', style: TextStyle(color: BvtColors.muted, fontSize: 12.5)));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: BvtColors.sand, borderRadius: BorderRadius.circular(14), border: Border.all(color: BvtColors.gold.withValues(alpha: 0.5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.auto_stories, color: BvtColors.deepSaffron), SizedBox(width: 8), Text('Read in the BVT Reader', style: TextStyle(fontWeight: FontWeight.w900))]),
          const SizedBox(height: 6),
          Text('This book from ₹49/mo, or all ${langOf(book.language).name} books from ₹149/mo. 3–7 day free trial.', style: const TextStyle(fontSize: 13, color: BvtColors.muted)),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => push(context, PlansScreen(forBook: book)), icon: const Icon(Icons.lock_open), label: Text(app.t('subscribe_to_read')))),
        ]),
      ),
    );
  }
}

class _Reviews extends StatelessWidget {
  final Book book;
  final List<Review> mine;
  final ValueChanged<Review> onAdd;
  const _Reviews({required this.book, required this.mine, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final all = [...mine, ...reviewSamples];
    final dist = [0.62, 0.24, 0.08, 0.04, 0.02];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader('Ratings & reviews', icon: Icons.star_outline),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Column(children: [
            Text(book.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: BvtColors.maroon)),
            Stars(book.rating, size: 16),
            Text('${book.ratingCount + mine.length} ratings', style: const TextStyle(fontSize: 12, color: BvtColors.muted)),
          ]),
          const SizedBox(width: 20),
          Expanded(
            child: Column(children: [
              for (var i = 0; i < 5; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Text('${5 - i}★', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(child: LinearProgressIndicator(value: dist[i], minHeight: 7, borderRadius: BorderRadius.circular(4), color: BvtColors.gold, backgroundColor: BvtColors.sand)),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: OutlinedButton.icon(
          onPressed: () async {
            if (!app.loggedIn) {
              final ok = await requireLogin(context, 'Sign in to write a review');
              if (!ok || !context.mounted) return;
            }
            _write(context);
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Write a review'),
        ),
      ),
      for (final r in all)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(radius: 14, backgroundColor: BvtColors.sand, child: Text(r.name[0], style: const TextStyle(fontWeight: FontWeight.w800, color: BvtColors.maroon))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text(r.date, style: const TextStyle(fontSize: 11.5, color: BvtColors.muted)),
                ]),
                const SizedBox(height: 6),
                Row(children: [Stars(r.stars.toDouble(), size: 14), if (r.verified) const Padding(padding: EdgeInsets.only(left: 8), child: Pill('Verified purchase', color: BvtColors.green, icon: Icons.verified))]),
                const SizedBox(height: 6),
                Text(r.text, style: const TextStyle(height: 1.4)),
              ]),
            ),
          ),
        ),
    ]);
  }

  void _write(BuildContext context) {
    var stars = 5;
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Write a review'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 1; i <= 5; i++) IconButton(onPressed: () => set(() => stars = i), icon: Icon(i <= stars ? Icons.star : Icons.star_border, color: BvtColors.gold, size: 32)),
            ]),
            TextField(controller: c, maxLines: 4, decoration: const InputDecoration(hintText: 'Share your thoughts…')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                onAdd(Review(app.name, stars, c.text.isEmpty ? 'Great book!' : c.text, dateFmt(DateTime.now())));
                Navigator.pop(ctx);
                toast(context, 'Thanks for your review!', icon: Icons.favorite);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
