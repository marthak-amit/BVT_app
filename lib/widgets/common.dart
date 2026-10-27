import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';

Future<T?> push<T>(BuildContext c, Widget page) =>
    Navigator.of(c).push<T>(MaterialPageRoute(builder: (_) => page));

void toast(BuildContext c, String msg, {String? action, VoidCallback? onAction, IconData? icon}) {
  final m = ScaffoldMessenger.of(c);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Row(children: [
      if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 10)],
      Expanded(child: Text(msg)),
    ]),
    duration: const Duration(seconds: 3),
    action: action != null ? SnackBarAction(label: action, onPressed: onAction ?? () {}) : null,
  ));
}

Color shade(Color c, double amount) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness + amount).clamp(0.0, 1.0)).toColor();
}

class BookCover extends StatelessWidget {
  final Book book;
  final double width;
  final bool showLang;
  const BookCover(this.book, {super.key, this.width = 110, this.showLang = true});

  @override
  Widget build(BuildContext context) {
    final h = book.isPoster ? width * 1.3 : width * 1.5;
    final fs = (width * 0.11).clamp(9.0, 22.0);
    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.05 + 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [shade(book.color, 0.08), shade(book.color, -0.14)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(2, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned(
          right: -width * 0.25,
          top: -width * 0.25,
          child: Container(
            width: width * 0.9,
            height: width * 0.9,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.10)),
          ),
        ),
        if (!book.isPoster)
          Positioned(left: 0, top: 0, bottom: 0, child: Container(width: width * 0.05, color: Colors.black.withValues(alpha: 0.18))),
        Padding(
          padding: EdgeInsets.fromLTRB(width * 0.12, width * 0.1, width * 0.08, width * 0.08),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (showLang)
              Container(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 1),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(4)),
                child: Text(langOf(book.language).native, style: TextStyle(color: Colors.white, fontSize: fs * 0.8)),
              ),
            const Spacer(),
            Center(child: Icon(book.isPoster ? Icons.wb_sunny_outlined : Icons.spa, color: BvtColors.gold, size: width * 0.28)),
            SizedBox(height: width * 0.04),
            Text(
              book.title,
              maxLines: book.isPoster ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: fs, height: 1.15, fontWeight: FontWeight.w700, fontFamily: 'serif'),
            ),
            const Spacer(),
            Center(
              child: Text('BHAKTI VIKAS TRUST',
                  style: TextStyle(color: Colors.white70, fontSize: fs * 0.62, letterSpacing: 0.8)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class Stars extends StatelessWidget {
  final double rating;
  final double size;
  const Stars(this.rating, {super.key, this.size = 14});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final v = rating - i;
          return Icon(v >= 0.75 ? Icons.star : (v >= 0.25 ? Icons.star_half : Icons.star_border),
              size: size, color: BvtColors.gold);
        }),
      );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final IconData? icon;
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.icon});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 8, 10),
        child: Row(children: [
          if (icon != null) ...[Icon(icon, size: 20, color: BvtColors.saffron), const SizedBox(width: 8)],
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ]),
      );
}

class Skeleton extends StatefulWidget {
  final double? w, h;
  final double radius;
  const Skeleton({super.key, this.w, this.h = 14, this.radius = 8});
  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Container(
          width: widget.w,
          height: widget.h,
          decoration: BoxDecoration(
            color: Color.lerp(const Color(0xFFEBDCC2), const Color(0xFFF7EDD9), _c.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      );
}

/// Shows [skeleton] briefly before [child] — mimics real network latency.
class LoadGate extends StatefulWidget {
  final Widget child, skeleton;
  final int ms;
  const LoadGate({super.key, required this.child, required this.skeleton, this.ms = 450});
  @override
  State<LoadGate> createState() => _LoadGateState();
}

class _LoadGateState extends State<LoadGate> {
  bool ready = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.ms), () {
      if (mounted) setState(() => ready = true);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: ready ? KeyedSubtree(key: const ValueKey('c'), child: widget.child) : KeyedSubtree(key: const ValueKey('s'), child: widget.skeleton),
      );
}

class GridSkeleton extends StatelessWidget {
  const GridSkeleton({super.key});
  @override
  Widget build(BuildContext context) => GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: List.generate(
            6,
            (_) => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Skeleton(w: double.infinity, h: null, radius: 12)),
                  SizedBox(height: 8),
                  Skeleton(w: 120),
                  SizedBox(height: 6),
                  Skeleton(w: 70),
                ])),
      );
}

class PriceText extends StatelessWidget {
  final num price;
  final num? mrp;
  final double size;
  const PriceText(this.price, {super.key, this.mrp, this.size = 16});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(inr(price), style: TextStyle(fontWeight: FontWeight.w800, fontSize: size, color: BvtColors.maroon)),
        if (mrp != null && mrp! > price) ...[
          const SizedBox(width: 6),
          Text(inr(mrp!), style: TextStyle(fontSize: size * 0.8, color: BvtColors.muted, decoration: TextDecoration.lineThrough)),
        ],
      ]);
}

class StockBadge extends StatelessWidget {
  final Book book;
  const StockBadge(this.book, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = app.stockOf(book);
    final (txt, col) = s <= 0
        ? ('Out of stock', BvtColors.red)
        : s <= 10
            ? ('Only $s left', const Color(0xFFE65100))
            : ('In stock', BvtColors.green);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.circle, size: 9, color: col),
      const SizedBox(width: 5),
      Text(txt, style: TextStyle(color: col, fontWeight: FontWeight.w600, fontSize: 12.5)),
    ]);
  }
}

/// Add-to-cart button with a small success animation.
class AddButton extends StatefulWidget {
  final Book book;
  final BookFormat format;
  final bool compact;
  final int qty;
  const AddButton(this.book, this.format, {super.key, this.compact = false, this.qty = 1});
  @override
  State<AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<AddButton> {
  bool done = false;
  Future<void> _tap() async {
    if (!app.inStock(widget.book)) {
      app.toggleWish(widget.book.id);
      app.stockAlerts.add(widget.book.id);
      toast(context, 'We will alert you (WhatsApp + push) when it is back in stock', icon: Icons.notifications_active);
      return;
    }
    app.addToCart(widget.book, widget.format, qty: widget.qty);
    setState(() => done = true);
    toast(context, 'Added to cart', icon: Icons.check_circle, action: 'VIEW CART', onAction: () => app.update(() => tabIndex.value = 3));
    await Future.delayed(const Duration(milliseconds: 1100));
    if (mounted) setState(() => done = false);
  }

  @override
  Widget build(BuildContext context) {
    final out = !app.inStock(widget.book);
    final icon = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
      child: Icon(done ? Icons.check : (out ? Icons.notifications_none : Icons.add_shopping_cart),
          key: ValueKey(done), size: 20),
    );
    if (widget.compact) {
      return SizedBox(
        width: 40,
        height: 40,
        child: IconButton.filledTonal(onPressed: _tap, icon: icon, tooltip: out ? 'Notify me' : 'Add to cart'),
      );
    }
    return FilledButton.icon(
      onPressed: _tap,
      icon: icon,
      label: Text(done ? 'Added' : (out ? 'Notify me' : app.t('add_to_cart'))),
    );
  }
}

/// Global bottom-tab index so any screen can jump to a tab.
final ValueNotifier<int> tabIndex = ValueNotifier(0);

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, message;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState(this.icon, this.title, this.message, {super.key, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 64, color: BvtColors.saffron.withValues(alpha: 0.6)),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: BvtColors.muted)),
            if (action != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(action!)),
            ],
          ]),
        ),
      );
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Pill(this.text, {super.key, this.color = BvtColors.saffron, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ]),
      );
}

class QtyStepper extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;
  const QtyStepper(this.qty, this.onChanged, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2CFAE)), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(visualDensity: VisualDensity.compact, icon: Icon(qty <= 1 ? Icons.delete_outline : Icons.remove, size: 18), onPressed: () => onChanged(qty - 1)),
          SizedBox(width: 28, child: Center(child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700)))),
          IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.add, size: 18), onPressed: () => onChanged(qty + 1)),
        ]),
      );
}

class KeyVal extends StatelessWidget {
  final String k, v;
  final bool bold;
  final Color? color;
  const KeyVal(this.k, this.v, {super.key, this.bold = false, this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(k, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400, fontSize: bold ? 16 : 14, color: color))),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 16 : 14, color: color)),
        ]),
      );
}

class BookCard extends StatelessWidget {
  final Book book;
  final double width;
  final VoidCallback onTap;
  const BookCard(this.book, {super.key, this.width = 130, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              Hero(tag: 'cover-${book.id}', child: BookCover(book, width: width)),
              if (book.isNew) const Positioned(right: 4, top: 4, child: Pill('NEW', color: BvtColors.green)),
              if (!app.inStock(book))
                Positioned(left: 0, right: 0, bottom: 0, child: Container(color: Colors.black54, padding: const EdgeInsets.all(3), child: const Text('OUT OF STOCK', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))),
            ]),
            const SizedBox(height: 8),
            Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.25)),
            const SizedBox(height: 3),
            Row(children: [Stars(book.rating, size: 12), const SizedBox(width: 4), Text('(${book.ratingCount})', style: const TextStyle(fontSize: 11, color: BvtColors.muted))]),
            const SizedBox(height: 3),
            PriceText(book.basePrice, size: 14),
          ]),
        ),
      );
}

class Shelf extends StatelessWidget {
  final List<Book> books;
  final void Function(Book) onTap;
  final double cardWidth;
  const Shelf(this.books, {super.key, required this.onTap, this.cardWidth = 118});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: cardWidth * 1.5 + 88,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: books.length,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, i) => BookCard(books[i], width: cardWidth, onTap: () => onTap(books[i])),
        ),
      );
}

String dateFmt(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

String timeFmt(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
}
