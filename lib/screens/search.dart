import 'dart:async';

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/recs.dart';
import '../data/search.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home.dart';
import 'listing.dart';

class SearchScreen extends StatefulWidget {
  final String initial;
  const SearchScreen({super.key, this.initial = ''});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);
  Timer? _deb;
  String q = '';
  String submitted = '';
  FilterState filters = FilterState();
  SortBy sort = SortBy.relevance;
  bool searching = false;

  @override
  void initState() {
    super.initState();
    q = widget.initial;
    if (q.isNotEmpty) submitted = q;
  }

  void _onChanged(String v) {
    _deb?.cancel();
    searching = true;
    _deb = Timer(const Duration(milliseconds: 280), () {
      if (mounted) setState(() { q = v; searching = false; });
    });
    setState(() {});
  }

  void _submit(String v) {
    _deb?.cancel();
    final s = v.trim();
    if (s.isEmpty) return;
    _c.text = s;
    _c.selection = TextSelection.collapsed(offset: s.length);
    final n = searchBooks(s).length;
    app.logSearch(s, n);
    setState(() { q = s; submitted = s; searching = false; });
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _deb?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showResults = submitted.isNotEmpty && submitted == q;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _c,
          autofocus: widget.initial.isEmpty,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _submit,
          decoration: InputDecoration(
            hintText: app.t('search_hint'),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            suffixIcon: _c.text.isEmpty
                ? IconButton(icon: const Icon(Icons.mic_none), onPressed: () { _c.text = 'krishna'; _submit('krishna'); toast(context, 'Voice search demo: “krishna”', icon: Icons.mic); })
                : IconButton(icon: const Icon(Icons.close), onPressed: () { _c.clear(); setState(() { q = ''; submitted = ''; }); }),
          ),
        ),
      ),
      body: q.trim().length < 2
          ? _Idle(onPick: _submit)
          : showResults
              ? _Results(
                  query: submitted,
                  filters: filters,
                  sort: sort,
                  onFilters: (f) => setState(() => filters = f),
                  onSort: (s) => setState(() => sort = s),
                  onQuery: _submit,
                )
              : _Suggestions(q: q, searching: searching, onPick: _submit),
    );
  }
}

class _Idle extends StatelessWidget {
  final void Function(String) onPick;
  const _Idle({required this.onPick});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        if (app.searchHistory.isNotEmpty) ...[
          Row(children: [
            const Text('Recent searches', style: TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            TextButton(onPressed: () => app.update(() => app.searchHistory.clear()), child: const Text('Clear')),
          ]),
          Wrap(spacing: 8, children: [for (final s in app.searchHistory) ActionChip(avatar: const Icon(Icons.history, size: 16), label: Text(s), onPressed: () => onPick(s))]),
          const SizedBox(height: 18),
        ],
        const Text('Popular searches', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [for (final s in ['Bhagavad-gita', 'Krsna stories', 'Ramayana', 'Prabhupada', 'Ekadasi', 'Navadvipa', 'sadhana']) ActionChip(label: Text(s), onPressed: () => onPick(s))]),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Row(children: [Icon(Icons.lightbulb_outline, color: BvtColors.saffron), SizedBox(width: 8), Text('Smart search tips', style: TextStyle(fontWeight: FontWeight.w800))]),
              SizedBox(height: 8),
              Text('• Spelling variants work: “krishna” = “Krsna” = “Kṛṣṇa”\n• Typos are forgiven: “ramyana”, “prabhupda”\n• Search in any script: कृष्ण, રામાયણ\n• Autocomplete starts after 2 characters', style: TextStyle(height: 1.5, color: BvtColors.muted)),
            ]),
          ),
        ),
      ]);
}

class _Suggestions extends StatelessWidget {
  final String q;
  final bool searching;
  final void Function(String) onPick;
  const _Suggestions({required this.q, required this.searching, required this.onPick});
  @override
  Widget build(BuildContext context) {
    final sug = suggestTitles(q);
    final quick = searchBooks(q).take(4).toList();
    return ListView(children: [
      if (searching) const LinearProgressIndicator(minHeight: 2),
      for (final s in sug)
        ListTile(leading: const Icon(Icons.search), title: Text(s), trailing: const Icon(Icons.north_west, size: 18), onTap: () => onPick(s)),
      ListTile(leading: const Icon(Icons.manage_search, color: BvtColors.saffron), title: Text('Search for “$q”', style: const TextStyle(fontWeight: FontWeight.w700)), onTap: () => onPick(q)),
      if (quick.isNotEmpty) ...[
        const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text('Top matches', style: TextStyle(fontWeight: FontWeight.w800))),
        for (final b in quick)
          ListTile(
            leading: BookCover(b, width: 34, showLang: false),
            title: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${langOf(b.language).name} · ${inr(b.basePrice)}'),
            onTap: () => openBook(context, b),
          ),
      ],
    ]);
  }
}

class _Results extends StatelessWidget {
  final String query;
  final FilterState filters;
  final SortBy sort;
  final ValueChanged<FilterState> onFilters;
  final ValueChanged<SortBy> onSort;
  final void Function(String) onQuery;
  const _Results({required this.query, required this.filters, required this.sort, required this.onFilters, required this.onSort, required this.onQuery});

  @override
  Widget build(BuildContext context) {
    final base = searchBooks(query);
    final res = sortBooks(base.where(filters.matches).toList(), sort == SortBy.relevance ? SortBy.relevance : sort);
    if (base.isEmpty) return _NoResults(query: query, onQuery: onQuery);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(children: [
          Expanded(child: Text('${res.length} results for “$query”', style: const TextStyle(fontWeight: FontWeight.w700))),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
            onPressed: () async {
              final r = await showFilterSheet(context, filters, base);
              if (r != null) onFilters(r);
            },
            icon: Badge(isLabelVisible: filters.count > 0, label: Text('${filters.count}'), child: const Icon(Icons.tune, size: 18)),
            label: Text(app.t('filters')),
          ),
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            onSelected: onSort,
            itemBuilder: (_) => const [
              PopupMenuItem(value: SortBy.relevance, child: Text('Relevance')),
              PopupMenuItem(value: SortBy.priceLow, child: Text('Price: Low to High')),
              PopupMenuItem(value: SortBy.priceHigh, child: Text('Price: High to Low')),
              PopupMenuItem(value: SortBy.rating, child: Text('Customer rating')),
              PopupMenuItem(value: SortBy.newest, child: Text('Newest first')),
            ],
          ),
        ]),
      ),
      // language facet quick-chips
      SizedBox(
        height: 38,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          for (final l in languages)
            if (base.any((b) => b.language == l.code))
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text('${l.native} ${base.where((b) => b.language == l.code).length}', style: const TextStyle(fontSize: 12)),
                  selected: filters.languages.contains(l.code),
                  onSelected: (v) {
                    final f = filters.copy();
                    v ? f.languages.add(l.code) : f.languages.remove(l.code);
                    onFilters(f);
                  },
                ),
              ),
        ]),
      ),
      Expanded(
        child: res.isEmpty
            ? EmptyState(Icons.filter_alt_off, 'No results with these filters', 'Remove some filters to see ${base.length} matches.', action: 'Clear filters', onAction: () => onFilters(FilterState()))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: res.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => BookListTile(res[i]),
              ),
      ),
    ]);
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  final void Function(String) onQuery;
  const _NoResults({required this.query, required this.onQuery});
  @override
  Widget build(BuildContext context) {
    final recs = catalog.where((b) => b.language == app.preferredBookLang && b.featured).toList();
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      EmptyState(Icons.search_off, 'No results for “$query”', 'Check the spelling, try a shorter word, or browse the recommendations below. We have logged this search to help us expand the catalog.'),
      Wrap(alignment: WrapAlignment.center, spacing: 8, children: [for (final s in ['krishna', 'gita', 'ramayana']) ActionChip(label: Text('Try “$s”'), onPressed: () => onQuery(s))]),
      const SectionHeader('You may like'),
      Shelf(recs.isEmpty ? recommendedForUser().books : recs, onTap: (b) => openBook(context, b)),
    ]);
  }
}
