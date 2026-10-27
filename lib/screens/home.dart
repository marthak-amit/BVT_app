import 'dart:async';

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/recs.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'article.dart';
import 'bulk.dart';
import 'donate.dart';
import 'ebooks.dart';
import 'listing.dart';
import 'notifications.dart';
import 'posters.dart';
import 'product.dart';
import 'reader.dart';
import 'search.dart';
import 'subscriptions.dart';

void openBook(BuildContext c, Book b) => push(c, ProductScreen(b));

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: const Row(children: [
            Icon(Icons.spa, color: BvtColors.saffron),
            SizedBox(width: 8),
            Text('BVT Books'),
          ]),
          actions: [
            IconButton(
              tooltip: 'Notifications',
              icon: Badge(isLabelVisible: app.unreadCount > 0, label: Text('${app.unreadCount}'), child: const Icon(Icons.notifications_none)),
              onPressed: () => push(context, const NotificationsScreen()),
            ),
            IconButton(
              tooltip: 'Wishlist',
              icon: Badge(isLabelVisible: app.wishlist.isNotEmpty, label: Text('${app.wishlist.length}'), child: const Icon(Icons.favorite_border)),
              onPressed: () => push(context, const WishlistScreen()),
            ),
          ],
        ),
        body: LoadGate(
          skeleton: const _HomeSkeleton(),
          child: RefreshIndicator(
            onRefresh: () async => await Future.delayed(const Duration(milliseconds: 600)),
            child: ListView(padding: const EdgeInsets.only(bottom: 90), children: [
              if (app.offlineMode)
                Container(
                  color: const Color(0xFFFFE0B2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(children: [Icon(Icons.cloud_off, size: 18), SizedBox(width: 8), Expanded(child: Text('Offline mode — showing your last 50 viewed products and downloaded chapters.', style: TextStyle(fontSize: 12.5)))]),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: GestureDetector(
                  onTap: () => push(context, const SearchScreen()),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2CFAE))),
                    child: Row(children: [
                      const Icon(Icons.search, color: BvtColors.muted),
                      const SizedBox(width: 10),
                      Expanded(child: Text(app.t('search_hint'), style: const TextStyle(color: BvtColors.muted))),
                      const Icon(Icons.mic_none, color: BvtColors.muted),
                    ]),
                  ),
                ),
              ),
              const HeroCarousel(),
              const _QuickActions(),
              if (app.loggedIn && app.library.isNotEmpty) const _ContinueReading(),
              const _SubscribeCta(),
              SectionHeader(app.t('featured'), action: 'See all', onAction: () => push(context, const ListingScreen(title: 'Featured books', featuredOnly: true))),
              Shelf(allBooks.where((b) => b.featured && b.language == app.preferredBookLang).followedBy(allBooks.where((b) => b.featured && b.language != app.preferredBookLang)).take(10).toList(), onTap: (b) => openBook(context, b)),
              SectionHeader(app.t('new_arrivals'), action: 'See all', onAction: () => push(context, const ListingScreen(title: 'New arrivals', newOnly: true))),
              Shelf(allBooks.where((b) => b.isNew).toList(), onTap: (b) => openBook(context, b)),
              SectionHeader(app.t('shop_by_language'), icon: Icons.translate),
              const _LanguageGrid(),
              if (app.recent.isNotEmpty) ...[
                SectionHeader(app.t('recently_viewed'), icon: Icons.history),
                Shelf(app.recent.map(bookById).take(12).toList(), onTap: (b) => openBook(context, b)),
              ],
              _Recommended(),
              for (final cat in ["Acharya's Glorification", 'Vedic Culture', 'Youth']) ...[
                SectionHeader(cat, action: 'See all', onAction: () => push(context, ListingScreen(title: cat, category: cat))),
                Shelf(allBooks.where((b) => b.category == cat && b.language == app.preferredBookLang).toList(), onTap: (b) => openBook(context, b)),
              ],
              const _Testimonials(),
              const _WhatsAppCard(),
              const _Footer(),
            ]),
          ),
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();
  @override
  Widget build(BuildContext context) => ListView(physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
        const Skeleton(h: 48, radius: 14),
        const SizedBox(height: 14),
        const Skeleton(h: 170, radius: 18),
        const SizedBox(height: 22),
        Row(children: List.generate(4, (_) => const Expanded(child: Padding(padding: EdgeInsets.all(6), child: Skeleton(h: 64, radius: 14))))),
        const SizedBox(height: 22),
        const Skeleton(w: 140, h: 18),
        const SizedBox(height: 12),
        Row(children: List.generate(3, (_) => const Expanded(child: Padding(padding: EdgeInsets.all(6), child: Skeleton(h: 190, radius: 10))))),
      ]);
}

void handleTarget(BuildContext c, String t) {
  if (t == 'plans') {
    push(c, const PlansScreen());
  } else if (t == 'bulk') {
    push(c, const BulkOrderScreen());
  } else if (t.startsWith('book:')) {
    final b = maybeBook(t.substring(5));
    if (b != null) openBook(c, b);
  }
}

class HeroCarousel extends StatefulWidget {
  const HeroCarousel({super.key});
  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final _pc = PageController(viewportFraction: 0.93);
  int _i = 0;
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 5), (_) {
      final n = _items.length;
      if (!_pc.hasClients || n < 2) return;
      _pc.animateToPage((_i + 1) % n, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  List<PromoBanner> get _items => app.banners.where((b) => b.active && (!b.appExclusive || app.appExclusive)).toList();

  @override
  void dispose() {
    _t?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Column(children: [
      SizedBox(
        height: 176,
        child: PageView.builder(
          controller: _pc,
          itemCount: items.length,
          onPageChanged: (v) => setState(() => _i = v),
          itemBuilder: (_, i) {
            final b = items[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => handleTarget(context, b.target),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [b.color, shade(b.color, -0.15)]),
                  ),
                  child: Stack(children: [
                    Positioned(right: -30, bottom: -30, child: Icon(Icons.spa, size: 170, color: Colors.white.withValues(alpha: 0.1))),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (b.appExclusive) const Pill('APP EXCLUSIVE', color: BvtColors.gold),
                        const Spacer(),
                        Text(b.title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900, height: 1.15)),
                        const SizedBox(height: 4),
                        Text(b.subtitle, maxLines: 2, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: Text(b.cta, style: TextStyle(color: b.color, fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var k = 0; k < items.length; k++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: k == _i ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(color: k == _i ? BvtColors.saffron : const Color(0xFFE2CFAE), borderRadius: BorderRadius.circular(4)),
          ),
      ]),
    ]);
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, Widget)>[
      (Icons.workspace_premium, 'Plans', const PlansScreen()),
      (Icons.tablet_mac, app.t('ebooks'), const EbooksScreen()),
      (Icons.image_outlined, app.t('posters'), const PostersScreen()),
      (Icons.volunteer_activism, app.t('donate'), const DonateScreen()),
      (Icons.inventory_2_outlined, app.t('bulk_order'), const BulkOrderScreen()),
      (Icons.article_outlined, app.t('blog'), const BlogScreen()),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
      child: Row(children: [
        for (final it in items)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => push(context, it.$3),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: BvtColors.sand, borderRadius: BorderRadius.circular(14)),
                    child: Icon(it.$1, color: BvtColors.deepSaffron),
                  ),
                  const SizedBox(height: 5),
                  Text(it.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _ContinueReading extends StatelessWidget {
  const _ContinueReading();
  @override
  Widget build(BuildContext context) {
    final lib = app.library;
    final b = lib.firstWhere((x) => app.progress.containsKey(x.id), orElse: () => lib.first);
    final p = app.progress[b.id] ?? 0.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => push(context, ReaderScreen(b)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              BookCover(b, width: 54, showLang: false),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.t('continue_reading'), style: const TextStyle(color: BvtColors.saffron, fontWeight: FontWeight.w800, fontSize: 12)),
                Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: p, minHeight: 6, borderRadius: BorderRadius.circular(4), color: BvtColors.saffron, backgroundColor: BvtColors.sand),
                const SizedBox(height: 4),
                Text('${(p * 100).round()}% read', style: const TextStyle(fontSize: 12, color: BvtColors.muted)),
              ])),
              const Icon(Icons.play_circle_fill, color: BvtColors.saffron, size: 36),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SubscribeCta extends StatelessWidget {
  const _SubscribeCta();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => push(context, const PlansScreen()),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: BvtColors.sand, borderRadius: BorderRadius.circular(16), border: Border.all(color: BvtColors.gold.withValues(alpha: 0.5))),
            child: Row(children: [
              const Icon(Icons.auto_stories, size: 40, color: BvtColors.deepSaffron),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Read unlimited with a subscription', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: BvtColors.maroon)),
                SizedBox(height: 2),
                Text('Per-book from ₹49 · Language All-Access ₹149/mo · 7-day free trial', style: TextStyle(fontSize: 12.5, color: BvtColors.muted)),
              ])),
              const Icon(Icons.chevron_right),
            ]),
          ),
        ),
      );
}

class _LanguageGrid extends StatelessWidget {
  const _LanguageGrid();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final l in languages)
            ActionChip(
              avatar: CircleAvatar(
                backgroundColor: BvtColors.saffron.withValues(alpha: 0.18),
                radius: 11,
                child: Text('${allBooks.where((b) => b.language == l.code).length}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: BvtColors.maroon)),
              ),
              label: Text('${l.native} · ${l.name}'),
              onPressed: () => push(context, ListingScreen(title: '${l.name} books', language: l.code)),
            ),
        ]),
      );
}

class _Recommended extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = recommendedForUser();
    if (r.books.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(app.t('recommended'), icon: Icons.auto_awesome),
      Padding(padding: const EdgeInsets.only(left: 16, bottom: 10), child: Text(r.reason, style: const TextStyle(color: BvtColors.muted, fontSize: 12.5))),
      Shelf(r.books, onTap: (b) => openBook(context, b)),
    ]);
  }
}

class _Testimonials extends StatelessWidget {
  const _Testimonials();
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader('What readers say', icon: Icons.format_quote),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: testimonials.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 280,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Stars(5),
                    const SizedBox(height: 6),
                    Expanded(child: Text('“${testimonials[i].$1}”', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontStyle: FontStyle.italic, height: 1.35))),
                    Text('— ${testimonials[i].$2}, ${testimonials[i].$3}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]);
}

class _WhatsAppCard extends StatelessWidget {
  const _WhatsAppCard();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFE7F8EE), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.chat, color: BvtColors.whatsapp, size: 36),
            const SizedBox(width: 12),
            const Expanded(child: Text('Get order updates & AI support on WhatsApp — English and Hindi.', style: TextStyle(fontWeight: FontWeight.w600))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: BvtColors.whatsapp, minimumSize: const Size(70, 40)),
              onPressed: () => app.update(() => app.waOptIn = true) ,
              child: Text(app.waOptIn ? 'Opted in ✓' : 'Opt in'),
            ),
          ]),
        ),
      );
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(16, 28, 16, 16),
        child: Column(children: [
          Divider(),
          SizedBox(height: 12),
          Text('Bhakti Vikas Trust · Bharuch, Gujarat', style: TextStyle(fontWeight: FontWeight.w700)),
          Text('publishing@bvks.com · +91-70168 11202', style: TextStyle(color: BvtColors.muted, fontSize: 12.5)),
          SizedBox(height: 4),
          Text('Prototype — sample data only', style: TextStyle(color: BvtColors.muted, fontSize: 11)),
        ]),
      );
}
