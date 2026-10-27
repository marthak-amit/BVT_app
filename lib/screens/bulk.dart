import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth.dart';

class BulkOrderScreen extends StatefulWidget {
  const BulkOrderScreen({super.key});
  @override
  State<BulkOrderScreen> createState() => _BulkOrderScreenState();
}

class _BulkOrderScreenState extends State<BulkOrderScreen> {
  Book book = bookById('beginners-guide-en');
  int qty = 50;
  final _org = TextEditingController(), _contact = TextEditingController(), _notes = TextEditingController();
  List<(String, int)>? csv;

  @override
  void dispose() {
    for (final c in [_org, _contact, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = book.basePrice;
    final pct = app.bulkPct(qty);
    final total = (unit * qty * (1 - pct)).round();
    return Scaffold(
      appBar: AppBar(title: Text(app.t('bulk_order'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Temples, schools, book tables and distributors — order in quantity and save. Bulk pricing is integrated into the main cart.', style: TextStyle(color: BvtColors.muted, height: 1.4)),
        const SectionHeader('Quantity pricing'),
        Card(
          child: Table(
            border: const TableBorder(horizontalInside: BorderSide(color: Color(0xFFEBD9BC))),
            children: [
              _row(['Quantity', 'Discount', 'Example (${inr(unit)} book)'], head: true),
              for (final t in [(1, 9, 0.0), (10, 49, 0.10), (50, 99, 0.20), (100, 0, 0.25)]) _row([t.$3 == 0.25 ? '100+' : t.$2 == 9 ? '1–9' : '${t.$1}–${t.$2}', t.$3 == 0 ? '—' : '${(t.$3 * 100).round()}% off', inr((unit * (1 - t.$3)).round())], hl: app.bulkPct(qty) == t.$3),
            ],
          ),
        ),
        const SectionHeader('Calculate your order'),
        Card(
          child: ListTile(
            leading: BookCover(book, width: 36, showLang: false),
            title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(langOf(book.language).name),
            trailing: const Icon(Icons.swap_horiz),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => ListView(children: [for (final b in allBooks.where((b) => app.preferredBookLang == b.language || b.language == 'en')) ListTile(leading: BookCover(b, width: 30, showLang: false), title: Text(b.title), subtitle: Text(langOf(b.language).name), onTap: () { setState(() => book = b); Navigator.pop(context); })]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w700)),
          Expanded(child: Slider(value: qty.clamp(1, 500).toDouble(), min: 1, max: 500, divisions: 499, label: '$qty', onChanged: (v) => setState(() => qty = v.round()))),
          SizedBox(width: 44, child: Text('$qty', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w900))),
        ]),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              KeyVal('List price', inr(unit * qty)),
              KeyVal('Bulk discount (${(pct * 100).round()}%)', '-${inr(unit * qty - total)}', color: BvtColors.green),
              const Divider(height: 18),
              KeyVal('Estimated total', inr(total), bold: true),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () { app.addToCart(book, book.purchasable.first, qty: qty); toast(context, '$qty copies added to cart at bulk price', icon: Icons.check_circle); }, icon: const Icon(Icons.add_shopping_cart), label: const Text('Add to cart at bulk price'))),
            ]),
          ),
        ),
        const SectionHeader('Upload a CSV'),
        OutlinedButton.icon(
          onPressed: () => setState(() => csv = [('beginners-guide-en', 100), ('gita-youth-hi', 60), ('ramayana-gu', 25), ('krishna-stories-en', 40), ('poster-pancha-tattva', 30)].map((e) => (e.$1, e.$2)).toList()),
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload SKU,Qty file (demo sample)'),
        ),
        if (csv != null)
          Card(
            margin: const EdgeInsets.only(top: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Icon(Icons.check_circle, color: BvtColors.green, size: 18), const SizedBox(width: 6), Text('${csv!.length} rows parsed', style: const TextStyle(fontWeight: FontWeight.w800))]),
                for (final r in csv!) Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [Expanded(child: Text(bookById(r.$1).title, maxLines: 1, overflow: TextOverflow.ellipsis)), Text('× ${r.$2}', style: const TextStyle(fontWeight: FontWeight.w700))])),
                const SizedBox(height: 10),
                FilledButton(onPressed: () { for (final r in csv!) { final b = bookById(r.$1); app.addToCart(b, b.purchasable.first, qty: r.$2); } setState(() => csv = null); toast(context, 'CSV items added to cart', icon: Icons.check_circle); }, child: const Text('Add all to cart')),
              ]),
            ),
          ),
        const SectionHeader('Request a quote'),
        TextField(controller: _org, decoration: const InputDecoration(labelText: 'Organisation')),
        const SizedBox(height: 10),
        TextField(controller: _contact, decoration: const InputDecoration(labelText: 'Contact (email / WhatsApp)')),
        const SizedBox(height: 10),
        TextField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Requirements (titles, quantities, delivery city)')),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () async {
            if (_org.text.isEmpty || _contact.text.isEmpty) { toast(context, 'Please fill organisation and contact', icon: Icons.info_outline); return; }
            await showDialog(context: context, builder: (ctx) => AlertDialog(icon: const Icon(Icons.mark_email_read, size: 44, color: BvtColors.green), title: const Text('Quote requested'), content: Text('Reference QT-${DateTime.now().millisecondsSinceEpoch % 100000}. Our team will reply within 1 business day on WhatsApp or email.'), actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Submit quote request'),
        ),
        const SizedBox(height: 24),
        if (!app.loggedIn) TextButton(onPressed: () => push(context, const LoginScreen(reason: 'Sign in to track your quotes')), child: const Text('Sign in to track quotes')),
      ]),
    );
  }

  TableRow _row(List<String> c, {bool head = false, bool hl = false}) => TableRow(
        decoration: BoxDecoration(color: head ? BvtColors.sand : (hl ? BvtColors.saffron.withValues(alpha: 0.15) : null)),
        children: [for (final t in c) Padding(padding: const EdgeInsets.all(10), child: Text(t, style: TextStyle(fontWeight: head || hl ? FontWeight.w800 : FontWeight.w500, fontSize: 13)))],
      );
}
