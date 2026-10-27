import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'article.dart';
import 'bulk.dart';
import 'donate.dart';
import 'ebooks.dart';
import 'listing.dart';
import 'posters.dart';
import 'search.dart';
import 'subscriptions.dart';

class BrowseTab extends StatelessWidget {
  const BrowseTab({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) => Scaffold(
          appBar: AppBar(
            title: Text(app.t('browse')),
            actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => push(context, const SearchScreen()))],
          ),
          body: ListView(padding: const EdgeInsets.only(bottom: 90), children: [
            const SectionHeader('Categories'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.6,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final c in categories)
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => c == 'Posters' ? push(context, const PostersScreen()) : push(context, ListingScreen(title: c, category: c)),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEBD9BC))),
                      child: Row(children: [
                        Icon(categoryIcons[c], color: BvtColors.deepSaffron),
                        const SizedBox(width: 10),
                        Expanded(child: Text(c, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                      ]),
                    ),
                  ),
              ],
            ),
            const SectionHeader('Shop by language'),
            for (final l in languages)
              ListTile(
                dense: true,
                leading: CircleAvatar(radius: 16, backgroundColor: BvtColors.sand, child: Text(l.native.characters.first, style: const TextStyle(color: BvtColors.maroon, fontWeight: FontWeight.w800))),
                title: Text('${l.name}  ·  ${l.native}'),
                subtitle: Text('${l.script} script · ${allBooks.where((b) => b.language == l.code).length} titles'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => push(context, ListingScreen(title: '${l.name} books', language: l.code)),
              ),
            const SectionHeader('More'),
            ListTile(leading: const Icon(Icons.workspace_premium), title: const Text('Reading subscriptions'), onTap: () => push(context, const PlansScreen())),
            ListTile(leading: const Icon(Icons.tablet_mac), title: Text(app.t('ebooks')), onTap: () => push(context, const EbooksScreen())),
            ListTile(leading: const Icon(Icons.image_outlined), title: Text(app.t('posters')), onTap: () => push(context, const PostersScreen())),
            ListTile(leading: const Icon(Icons.article_outlined), title: Text(app.t('blog')), onTap: () => push(context, const BlogScreen())),
            ListTile(leading: const Icon(Icons.inventory_2_outlined), title: Text(app.t('bulk_order')), onTap: () => push(context, const BulkOrderScreen())),
            ListTile(leading: const Icon(Icons.volunteer_activism), title: Text(app.t('donate')), onTap: () => push(context, const DonateScreen())),
            for (final p in app.cmsPages.where((p) => p.$3 == 'Published'))
              ListTile(leading: const Icon(Icons.description_outlined), title: Text(p.$1), subtitle: Text('${p.$2} · CMS page'), onTap: () => push(context, CmsPageScreen(p.$1, p.$2))),
          ]),
        ),
      );
}

class CmsPageScreen extends StatelessWidget {
  final String title, template;
  const CmsPageScreen(this.title, this.template, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Pill(template),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Text('This page was created by BVT staff using the admin CMS page builder — no code required. Content blocks, images and related-book widgets are assembled from pre-built templates.', style: TextStyle(height: 1.5)),
        ]),
      );
}
