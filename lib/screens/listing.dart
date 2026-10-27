import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home.dart';

enum SortBy { relevance, priceLow, priceHigh, rating, newest }

extension on SortBy {
  String get label => switch (this) {
        SortBy.relevance => 'Relevance',
        SortBy.priceLow => 'Price: Low to High',
        SortBy.priceHigh => 'Price: High to Low',
        SortBy.rating => 'Customer rating',
        SortBy.newest => 'Newest first',
      };
}

class FilterState {
  Set<String> languages = {};
  Set<BookFormat> formats = {};
  Set<String> categories = {};
  RangeValues price = const RangeValues(0, 1000);
  bool inStockOnly = false, subscriptionOnly = false;
  double minRating = 0;

  bool get active =>
      languages.isNotEmpty || formats.isNotEmpty || categories.isNotEmpty || price.start > 0 || price.end < 1000 || inStockOnly || subscriptionOnly || minRating > 0;
  int get count =>
      (languages.isNotEmpty ? 1 : 0) + (formats.isNotEmpty ? 1 : 0) + (categories.isNotEmpty ? 1 : 0) + ((price.start > 0 || price.end < 1000) ? 1 : 0) + (inStockOnly ? 1 : 0) + (subscriptionOnly ? 1 : 0) + (minRating > 0 ? 1 : 0);

  FilterState copy() => FilterState()
    ..languages = {...languages}
    ..formats = {...formats}
    ..categories = {...categories}
    ..price = price
    ..inStockOnly = inStockOnly
    ..subscriptionOnly = subscriptionOnly
    ..minRating = minRating;

  bool matches(Book b) {
    if (languages.isNotEmpty && !languages.contains(b.language)) return false;
    if (formats.isNotEmpty && !b.prices.keys.any(formats.contains)) return false;
    if (categories.isNotEmpty && !categories.contains(b.category)) return false;
    final p = b.basePrice;
    if (p < price.start || (price.end < 1000 && p > price.end)) return false;
    if (inStockOnly && !app.inStock(b)) return false;
    if (subscriptionOnly && !b.subEligible) return false;
    if (b.rating < minRating) return false;
    return true;
  }
}

List<Book> sortBooks(List<Book> l, SortBy s) {
  final r = [...l];
  switch (s) {
    case SortBy.relevance:
      // admin-pinned (sponsored) first, others keep given order
      r.sort((a, b) => (app.pinned.contains(b.id) ? 1 : 0).compareTo(app.pinned.contains(a.id) ? 1 : 0));
    case SortBy.priceLow:
      r.sort((a, b) => a.basePrice.compareTo(b.basePrice));
    case SortBy.priceHigh:
      r.sort((a, b) => b.basePrice.compareTo(a.basePrice));
    case SortBy.rating:
      r.sort((a, b) => b.rating.compareTo(a.rating));
    case SortBy.newest:
      r.sort((a, b) => (b.isNew ? 1 : 0).compareTo(a.isNew ? 1 : 0));
  }
  return r;
}

Future<FilterState?> showFilterSheet(BuildContext context, FilterState current, List<Book> base) {
  return showModalBottomSheet<FilterState>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _FilterSheet(current.copy(), base),
  );
}

class _FilterSheet extends StatefulWidget {
  final FilterState f;
  final List<Book> base;
  const _FilterSheet(this.f, this.base);
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late FilterState f = widget.f;
  int count(bool Function(Book) t) => widget.base.where(t).length;

  @override
  Widget build(BuildContext context) {
    final matches = widget.base.where(f.matches).length;
    Widget title(String t) => Padding(padding: const EdgeInsets.only(top: 18, bottom: 8), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)));
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, sc) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
          child: Row(children: [
            Text(app.t('filters'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const Spacer(),
            TextButton(onPressed: () => setState(() => f = FilterState()), child: Text(app.t('reset'))),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ]),
        ),
        Expanded(
          child: ListView(controller: sc, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            title('Language'),
            Wrap(spacing: 8, runSpacing: 2, children: [
              for (final l in languages)
                if (count((b) => b.language == l.code) > 0)
                  FilterChip(
                    label: Text('${l.name} (${count((b) => b.language == l.code)})'),
                    selected: f.languages.contains(l.code),
                    onSelected: (v) => setState(() => v ? f.languages.add(l.code) : f.languages.remove(l.code)),
                  ),
            ]),
            title('Format'),
            Wrap(spacing: 8, children: [
              for (final fm in BookFormat.values)
                FilterChip(
                  avatar: Icon(fm.icon, size: 16),
                  label: Text('${fm.label} (${count((b) => b.prices.containsKey(fm))})'),
                  selected: f.formats.contains(fm),
                  onSelected: (v) => setState(() => v ? f.formats.add(fm) : f.formats.remove(fm)),
                ),
            ]),
            title('Category'),
            Wrap(spacing: 8, runSpacing: 2, children: [
              for (final c in categories)
                if (count((b) => b.category == c) > 0)
                  FilterChip(label: Text(c), selected: f.categories.contains(c), onSelected: (v) => setState(() => v ? f.categories.add(c) : f.categories.remove(c))),
            ]),
            title('Price range  (${inr(f.price.start)} – ${f.price.end >= 1000 ? '₹1,000+' : inr(f.price.end)})'),
            RangeSlider(values: f.price, min: 0, max: 1000, divisions: 20, labels: RangeLabels(inr(f.price.start), inr(f.price.end)), onChanged: (v) => setState(() => f.price = v)),
            title('Customer rating'),
            Wrap(spacing: 8, children: [
              for (final r in [0.0, 4.0, 4.5])
                ChoiceChip(label: Text(r == 0 ? 'Any' : '$r★ & up'), selected: f.minRating == r, onSelected: (_) => setState(() => f.minRating = r)),
            ]),
            title('Availability & access'),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('In stock only'), value: f.inStockOnly, onChanged: (v) => setState(() => f.inStockOnly = v)),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Available with reading subscription'), subtitle: const Text('Subscription eligibility'), value: f.subscriptionOnly, onChanged: (v) => setState(() => f.subscriptionOnly = v)),
            const SizedBox(height: 20),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context, f), child: Text('Show $matches results'))),
        ),
      ]),
    );
  }
}

class ListingScreen extends StatefulWidget {
  final String title;
  final String? language, category;
  final bool featuredOnly, newOnly;
  final List<Book>? books;
  const ListingScreen({super.key, required this.title, this.language, this.category, this.featuredOnly = false, this.newOnly = false, this.books});
  @override
  State<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen> {
  FilterState filters = FilterState();
  SortBy sort = SortBy.relevance;
  bool grid = true;
  int shown = 12;
  bool loadingMore = false;
  final _sc = ScrollController();

  @override
  void initState() {
    super.initState();
    _sc.addListener(() {
      if (_sc.position.pixels > _sc.position.maxScrollExtent - 300 && !loadingMore) _more();
    });
  }

  Future<void> _more() async {
    if (shown >= _all.length) return;
    setState(() => loadingMore = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() { shown += 12; loadingMore = false; });
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  List<Book> get _base {
    var l = widget.books ?? catalog;
    if (widget.language != null) l = l.where((b) => b.language == widget.language).toList();
    if (widget.category != null) l = l.where((b) => b.category == widget.category).toList();
    if (widget.featuredOnly) l = l.where((b) => b.featured).toList();
    if (widget.newOnly) l = l.where((b) => b.isNew).toList();
    return l;
  }

  List<Book> get _all => sortBooks(_base.where(filters.matches).toList(), sort);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final all = _all;
        final items = all.take(shown).toList();
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              IconButton(tooltip: grid ? 'List view' : 'Grid view', icon: Icon(grid ? Icons.view_list : Icons.grid_view), onPressed: () => setState(() => grid = !grid)),
            ],
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: () async {
                    final r = await showFilterSheet(context, filters, _base);
                    if (r != null) setState(() { filters = r; shown = 12; });
                  },
                  icon: Badge(isLabelVisible: filters.count > 0, label: Text('${filters.count}'), child: const Icon(Icons.tune, size: 18)),
                  label: Text(app.t('filters')),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<SortBy>(
                  initialValue: sort,
                  onSelected: (v) => setState(() => sort = v),
                  itemBuilder: (_) => [for (final s in SortBy.values) PopupMenuItem(value: s, child: Text(s.label))],
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: BvtColors.deepSaffron), borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.sort, size: 18, color: BvtColors.deepSaffron), const SizedBox(width: 6), Text(sort.label, style: const TextStyle(color: BvtColors.deepSaffron, fontWeight: FontWeight.w600, fontSize: 13))]),
                  ),
                ),
                const Spacer(),
                Text('${all.length} titles', style: const TextStyle(color: BvtColors.muted, fontSize: 12.5)),
              ]),
            ),
            if (filters.active)
              SizedBox(
                height: 38,
                child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                  for (final l in filters.languages) _chip(langOf(l).name, () => setState(() => filters.languages.remove(l))),
                  for (final f in filters.formats) _chip(f.label, () => setState(() => filters.formats.remove(f))),
                  for (final c in filters.categories) _chip(c, () => setState(() => filters.categories.remove(c))),
                  if (filters.inStockOnly) _chip('In stock', () => setState(() => filters.inStockOnly = false)),
                  if (filters.subscriptionOnly) _chip('Subscription', () => setState(() => filters.subscriptionOnly = false)),
                  if (filters.minRating > 0) _chip('${filters.minRating}★+', () => setState(() => filters.minRating = 0)),
                  if (filters.price.start > 0 || filters.price.end < 1000) _chip('${inr(filters.price.start)}–${inr(filters.price.end)}', () => setState(() => filters.price = const RangeValues(0, 1000))),
                ]),
              ),
            Expanded(
              child: LoadGate(
                ms: 350,
                skeleton: const GridSkeleton(),
                child: all.isEmpty
                    ? EmptyState(Icons.search_off, 'No titles match', 'Try removing some filters.', action: 'Clear filters', onAction: () => setState(() => filters = FilterState()))
                    : grid
                        ? GridView.builder(
                            controller: _sc,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, childAspectRatio: 0.56, mainAxisSpacing: 16, crossAxisSpacing: 16),
                            itemCount: items.length + (loadingMore ? 2 : 0),
                            itemBuilder: (_, i) => i >= items.length ? const Skeleton(h: null, radius: 12) : BookGridTile(items[i]),
                          )
                        : ListView.separated(
                            controller: _sc,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: items.length + (loadingMore ? 1 : 0),
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => i >= items.length ? const Skeleton(h: 80, radius: 12) : BookListTile(items[i]),
                          ),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _chip(String t, VoidCallback onDel) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: InputChip(label: Text(t, style: const TextStyle(fontSize: 12)), onDeleted: onDel, visualDensity: VisualDensity.compact),
      );
}

class BookGridTile extends StatelessWidget {
  final Book book;
  const BookGridTile(this.book, {super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (_, _) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => openBook(context, book),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              Center(child: LayoutBuilder(builder: (_, c) => Hero(tag: 'cover-${book.id}', child: BookCover(book, width: (c.maxWidth * 0.78).clamp(80, 170))))),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(app.wishlist.contains(book.id) ? Icons.favorite : Icons.favorite_border, color: BvtColors.red),
                  onPressed: () {
                    app.toggleWish(book.id);
                  },
                ),
              ),
              if (book.isNew) const Positioned(left: 0, top: 4, child: Pill('NEW', color: BvtColors.green)),
              if (app.pinned.contains(book.id)) const Positioned(left: 0, bottom: 4, child: Pill('Sponsored', color: BvtColors.gold)),
            ]),
          ),
          const SizedBox(height: 8),
          Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.25)),
          const SizedBox(height: 3),
          Row(children: [Stars(book.rating, size: 12), const SizedBox(width: 4), Text('(${book.ratingCount})', style: const TextStyle(fontSize: 11, color: BvtColors.muted))]),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [PriceText(book.basePrice, size: 15), StockBadge(book)])),
            AddButton(book, book.purchasable.first, compact: true),
          ]),
        ]),
      ),
    );
  }
}

class BookListTile extends StatelessWidget {
  final Book book;
  const BookListTile(this.book, {super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) => Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => openBook(context, book),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Hero(tag: 'cover-${book.id}', child: BookCover(book, width: 72)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('${book.author} · ${langOf(book.language).name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: BvtColors.muted)),
                    const SizedBox(height: 4),
                    Row(children: [Stars(book.rating, size: 13), const SizedBox(width: 4), Text('${book.ratingCount}', style: const TextStyle(fontSize: 12, color: BvtColors.muted))]),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, children: [for (final f in book.prices.keys) Pill(f.label, color: BvtColors.maroon)]),
                    const SizedBox(height: 6),
                    Row(children: [PriceText(book.basePrice), const SizedBox(width: 10), StockBadge(book)]),
                  ]),
                ),
                Column(children: [
                  IconButton(
                    icon: Icon(app.wishlist.contains(book.id) ? Icons.favorite : Icons.favorite_border, color: BvtColors.red),
                    onPressed: () => app.toggleWish(book.id),
                  ),
                  AddButton(book, book.purchasable.first, compact: true),
                ]),
              ]),
            ),
          ),
        ),
      );
}

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) {
          final items = app.wishlist.map(bookById).toList();
          return Scaffold(
            appBar: AppBar(title: Text('${app.t('wishlist')} (${items.length})')),
            body: items.isEmpty
                ? const EmptyState(Icons.favorite_border, 'Your reading list is empty', 'Tap the heart on any book to save it here. Out-of-stock saved titles can alert you when they return.')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final b = items[i];
                      return Column(children: [
                        BookListTile(b),
                        if (!app.inStock(b))
                          SwitchListTile(
                            dense: true,
                            title: const Text('Back-in-stock alert'),
                            subtitle: const Text('WhatsApp + push when available'),
                            value: app.stockAlerts.contains(b.id),
                            onChanged: (v) => app.update(() => v ? app.stockAlerts.add(b.id) : app.stockAlerts.remove(b.id)),
                          ),
                      ]);
                    },
                  ),
          );
        },
      );
}
