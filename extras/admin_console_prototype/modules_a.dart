import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart' show dateFmt;
import 'admin_state.dart';
import 'admin_widgets.dart';

// ============================================================ Dashboard
class AdminDashboard extends StatelessWidget {
  final void Function(String) onGo;
  const AdminDashboard({super.key, required this.onGo});

  @override
  Widget build(BuildContext context) {
    final series = adm.sales(14);
    final low = catalog.where((b) => app.stockOf(b) <= 10).toList();
    final failed = app.zohoEvents.where((e) => !e.ok).length;
    final activeSubs = adm.subs.where((s) => s.status == 'active' || s.status == 'trial').length + app.subscriptions.where((s) => s.status == 'active').length;
    final orders = adm.allOrders;
    return ListenableBuilder(
      listenable: Listenable.merge([adm, app]),
      builder: (context, _) => AdminPage(module: 'dashboard', title: 'Dashboard', subtitle: 'Welcome back, ${adm.userName} · ${dateFmt(DateTime.now())}', children: [
        Wrap(spacing: 12, runSpacing: 12, children: [
          StatTile('Revenue (14 days)', inr(series.reduce((a, b) => a + b)), Icons.currency_rupee, delta: '+12.4%', color: BvtColors.green, onTap: () => onGo('finance')),
          StatTile('Orders (all)', '${orders.length}', Icons.receipt_long, delta: '+8.1%', onTap: () => onGo('orders')),
          StatTile('Active subscriptions', '$activeSubs', Icons.workspace_premium, delta: '+5', color: BvtColors.maroon, onTap: () => onGo('subscriptions')),
          StatTile('MRR', inr(activeSubs * 189), Icons.autorenew, delta: '+3.2%', color: const Color(0xFF3B6EA5), onTap: () => onGo('reports')),
          StatTile('Low-stock SKUs', '${low.length}', Icons.warning_amber, color: low.isEmpty ? BvtColors.green : const Color(0xFFE65100), onTap: () => onGo('inventory')),
          StatTile('Zoho sync issues', '$failed', Icons.sync_problem, color: failed == 0 ? BvtColors.green : BvtColors.red, onTap: () => onGo('zoho')),
        ]),
        const SizedBox(height: 16),
        Panel(title: 'Sales · last 14 days', child: BarChart(series, [for (var i = 13; i >= 0; i--) shortDate(DateTime.now().subtract(Duration(days: i)))])),
        LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth > 800;
          final alerts = Panel(
            title: 'Needs attention',
            child: Column(children: [
              _alert(Icons.inventory_2, '${low.length} titles at or below 10 units', const Color(0xFFE65100), () => onGo('inventory')),
              _alert(Icons.sync_problem, '$failed Zoho sync events failed — retry queue', BvtColors.red, () => onGo('zoho')),
              _alert(Icons.local_shipping, '${orders.where((o) => o.stage == 1).length} orders awaiting packing', BvtColors.deepSaffron, () => onGo('orders')),
              _alert(Icons.credit_card_off, '${adm.subs.where((s) => s.status == 'grace').length} subscriptions in grace period', BvtColors.maroon, () => onGo('subscriptions')),
              _alert(Icons.search_off, '${app.zeroResults.length} zero-result searches to review', BvtColors.muted, () => onGo('search')),
            ]),
          );
          final top = Panel(
            title: 'Top products (revenue)',
            child: Column(children: [for (var i = 0; i < 5; i++) HBar(allBooks[(i * 5) % allBooks.length].title, 90000.0 - i * 14000, 90000, inr(90000 - i * 14000))]),
          );
          return wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: alerts), const SizedBox(width: 16), Expanded(child: top)]) : Column(children: [alerts, top]);
        }),
        Panel(
          title: 'Recent orders',
          actions: [TextButton(onPressed: () => onGo('orders'), child: const Text('View all'))],
          child: DataGrid(['Order', 'Customer', 'Total', 'Status'], [for (final o in orders.take(6)) [Text(o.id), Text(o.address.name), Text(inr(o.total)), Pill(o.statusLabel, color: _stageColor(o))]]),
        ),
      ]),
    );
  }

  Widget _alert(IconData i, String t, Color c, VoidCallback onTap) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: CircleAvatar(radius: 16, backgroundColor: c.withValues(alpha: 0.15), child: Icon(i, size: 17, color: c)), title: Text(t), trailing: const Icon(Icons.chevron_right, size: 18), onTap: onTap);
}

Color _stageColor(Order o) => o.stage == -1 ? BvtColors.red : o.stage == -2 ? const Color(0xFFE65100) : o.stage >= 5 ? BvtColors.green : BvtColors.deepSaffron;

// ============================================================ Products
class ProductsModule extends StatefulWidget {
  const ProductsModule({super.key});
  @override
  State<ProductsModule> createState() => _ProductsModuleState();
}

class _ProductsModuleState extends State<ProductsModule> {
  String q = '', cat = 'All', lang = 'All';
  int shown = 20;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([adm, app]),
      builder: (context, _) {
        var list = catalog.where((b) => (cat == 'All' || b.category == cat) && (lang == 'All' || b.language == lang) && (q.isEmpty || b.title.toLowerCase().contains(q.toLowerCase()) || b.id.contains(q.toLowerCase()))).toList();
        final total = list.length;
        list = list.take(shown).toList();
        return AdminPage(
          module: 'products',
          title: 'Products',
          subtitle: '${catalog.length} SKUs · books, posters, subscriptions',
          actions: [
            FilledButton.icon(onPressed: () => _edit(context, null), icon: const Icon(Icons.add), label: const Text('Add product')),
            OutlinedButton.icon(onPressed: () => _import(context), icon: const Icon(Icons.upload_file), label: const Text('Import CSV/Excel')),
            OutlinedButton.icon(onPressed: () => showExport(context, 'products_export.csv', 'sku,title,language,category,price,stock\n${catalog.take(5).map((b) => '${b.id},"${b.title}",${b.language},${b.category},${b.basePrice},${app.stockOf(b)}').join('\n')}\n… ${catalog.length} rows'), icon: const Icon(Icons.download), label: const Text('Export')),
          ],
          children: [
            Wrap(spacing: 12, runSpacing: 8, children: [
              SizedBox(width: 280, child: TextField(decoration: const InputDecoration(hintText: 'Search title or SKU', prefixIcon: Icon(Icons.search), isDense: true), onChanged: (v) => setState(() { q = v; shown = 20; }))),
              SizedBox(width: 200, child: DropdownButtonFormField<String>(initialValue: cat, isDense: true, decoration: const InputDecoration(labelText: 'Category', isDense: true), items: ['All', ...categories].map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) => setState(() { cat = v!; shown = 20; }))),
              SizedBox(width: 160, child: DropdownButtonFormField<String>(initialValue: lang, isDense: true, decoration: const InputDecoration(labelText: 'Language', isDense: true), items: [const DropdownMenuItem(value: 'All', child: Text('All')), ...languages.map((l) => DropdownMenuItem(value: l.code, child: Text(l.name)))], onChanged: (v) => setState(() { lang = v!; shown = 20; }))),
            ]),
            const SizedBox(height: 12),
            Panel(
              child: Column(children: [
                DataGrid(['SKU', 'Title', 'Lang', 'Category', 'Price', 'Stock', 'Flags', ''], [
                  for (final b in list)
                    [
                      Text(b.id, style: const TextStyle(fontSize: 12)),
                      SizedBox(width: 220, child: Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text(b.language.toUpperCase()),
                      SizedBox(width: 130, child: Text(b.category, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text(inr(b.basePrice)),
                      Text('${app.stockOf(b)}', style: TextStyle(color: app.stockOf(b) <= 10 ? BvtColors.red : null, fontWeight: FontWeight.w700)),
                      Wrap(spacing: 4, children: [if (b.featured) const Pill('Featured', color: BvtColors.gold), if (b.isNew) const Pill('New', color: BvtColors.green), if (app.pinned.contains(b.id)) const Pill('Sponsored', color: BvtColors.maroon)]),
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _edit(context, b)),
                    ],
                ]),
                if (shown < total) Padding(padding: const EdgeInsets.only(top: 10), child: TextButton(onPressed: () => setState(() => shown += 20), child: Text('Show more (${total - shown} remaining)'))),
              ]),
            ),
          ],
        );
      },
    );
  }

  void _import(BuildContext context) {
    if (!adm.act(context, 'products', 'Bulk import from CSV (3 rows)', after: '+3 products')) return;
    for (var i = 1; i <= 3; i++) {
      adm.addBook(Book(id: 'import-$i-${DateTime.now().millisecondsSinceEpoch % 1000}', group: 'import-$i', title: 'Imported Title $i', language: 'en', author: 'HH Bhakti Vikasa Swami', category: 'Philosophy', description: 'Imported via CSV bulk upload.', isbn: 'IMP-$i', pages: 100, prices: {BookFormat.paperback: 100 + i * 20}, stock: 50, rating: 4.2, ratingCount: 0, color: BvtColors.maroon, isNew: true));
    }
    showExport(context, 'import_result.csv', '3 rows imported · 0 errors · 0 duplicates\nSKUs created: import-1, import-2, import-3\nZoho Inventory item sync queued.');
  }

  void _edit(BuildContext context, Book? b) {
    final title = TextEditingController(text: b?.title ?? '');
    final price = TextEditingController(text: '${b?.basePrice ?? 150}');
    final stock = TextEditingController(text: '${b == null ? 100 : app.stockOf(b)}');
    var feat = b?.featured ?? false, isNew = b?.isNew ?? true, sub = b?.subEligible ?? true, pin = b != null && app.pinned.contains(b.id);
    var cat = b?.category ?? categories.first, lang = b?.language ?? 'en';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(b == null ? 'Add product' : 'Edit product'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)'))), const SizedBox(width: 10), Expanded(child: TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock')))]),
                if (b == null) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(initialValue: cat, decoration: const InputDecoration(labelText: 'Category'), items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => set(() => cat = v!)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(initialValue: lang, decoration: const InputDecoration(labelText: 'Language'), items: languages.map((l) => DropdownMenuItem(value: l.code, child: Text(l.name))).toList(), onChanged: (v) => set(() => lang = v!)),
                ],
                SwitchListTile(dense: true, title: const Text('Featured on homepage'), value: feat, onChanged: (v) => set(() => feat = v)),
                SwitchListTile(dense: true, title: const Text('New arrival'), value: isNew, onChanged: (v) => set(() => isNew = v)),
                SwitchListTile(dense: true, title: const Text('Subscription eligible'), value: sub, onChanged: (v) => set(() => sub = v)),
                SwitchListTile(dense: true, title: const Text('Sponsored / pinned in search'), value: pin, onChanged: (v) => set(() => pin = v)),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final p = int.tryParse(price.text) ?? 100;
                final s = int.tryParse(stock.text) ?? 0;
                if (b == null) {
                  if (!adm.act(context, 'products', 'Created product · ${title.text}', after: '${inr(p)} · stock $s')) return;
                  final id = 'new-${DateTime.now().millisecondsSinceEpoch % 100000}-$lang';
                  adm.addBook(Book(id: id, group: id, title: title.text.isEmpty ? 'New product' : title.text, language: lang, author: 'HH Bhakti Vikasa Swami', category: cat, description: 'Newly created product.', isbn: 'NEW-$id', pages: 120, prices: {BookFormat.paperback: p}, stock: s, rating: 0, ratingCount: 0, color: BvtColors.deepSaffron, isNew: isNew, featured: feat, subEligible: sub));
                  if (pin) app.pinned.add(id);
                } else {
                  if (!adm.act(context, 'products', 'Updated product · ${b.title}', before: '${inr(b.basePrice)} · stock ${app.stockOf(b)}', after: '${inr(p)} · stock $s')) return;
                  final prices = {...b.prices, b.purchasable.first: p};
                  adm.replaceBook(b, b.copyWith(title: title.text, prices: prices, featured: feat, isNew: isNew, subEligible: sub));
                  app.stockAdj[b.id] = s - b.stock;
                  pin ? app.pinned.add(b.id) : app.pinned.remove(b.id);
                  app.zohoEvents.insert(0, ZohoEvent('Item', b.id, 'Catalog change pushed to Zoho Inventory', true, DateTime.now()));
                }
                Navigator.pop(ctx);
                adm.changed();
                app.update(() {});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================ Inventory
class InventoryModule extends StatefulWidget {
  const InventoryModule({super.key});
  @override
  State<InventoryModule> createState() => _InventoryModuleState();
}

class _InventoryModuleState extends State<InventoryModule> {
  double threshold = 10;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([adm, app]),
        builder: (context, _) {
          final low = catalog.where((b) => app.stockOf(b) <= threshold).toList()..sort((a, b) => app.stockOf(a).compareTo(app.stockOf(b)));
          final out = catalog.where((b) => app.stockOf(b) == 0).length;
          return AdminPage(
            module: 'inventory',
            title: 'Inventory',
            subtitle: 'Zoho Inventory is the authoritative source · website reads live stock with a 5-minute cache',
            actions: [OutlinedButton.icon(onPressed: () { app.zohoEvents.insert(0, ZohoEvent('Stock', 'all-sku', 'Full stock pull from Zoho Inventory completed', true, DateTime.now())); app.update(() {}); adminToast(context, 'Stock refreshed from Zoho (cache invalidated)'); }, icon: const Icon(Icons.sync), label: const Text('Pull from Zoho'))],
            children: [
              Wrap(spacing: 12, runSpacing: 12, children: [
                StatTile('Total SKUs', '${catalog.length}', Icons.inventory_2),
                StatTile('Low stock (≤${threshold.round()})', '${low.length}', Icons.warning_amber, color: const Color(0xFFE65100)),
                StatTile('Out of stock', '$out', Icons.block, color: BvtColors.red),
                StatTile('Units on hand', '${catalog.fold<int>(0, (a, b) => a + app.stockOf(b))}', Icons.stacked_bar_chart, color: BvtColors.green),
              ]),
              const SizedBox(height: 16),
              Panel(
                title: 'Low-stock alert threshold',
                child: Row(children: [Expanded(child: Slider(value: threshold, min: 0, max: 50, divisions: 50, label: '${threshold.round()}', onChanged: (v) => setState(() => threshold = v))), Text('${threshold.round()} units', style: const TextStyle(fontWeight: FontWeight.w800))]),
              ),
              Panel(
                title: 'Restock workflow',
                child: DataGrid(['SKU', 'Title', 'On hand', 'Status', ''], [
                  for (final b in low.take(25))
                    [
                      Text(b.id, style: const TextStyle(fontSize: 12)),
                      SizedBox(width: 240, child: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text('${app.stockOf(b)}', style: TextStyle(fontWeight: FontWeight.w800, color: app.stockOf(b) == 0 ? BvtColors.red : const Color(0xFFE65100))),
                      Pill(app.stockOf(b) == 0 ? 'Out of stock' : 'Low', color: app.stockOf(b) == 0 ? BvtColors.red : const Color(0xFFE65100)),
                      FilledButton.tonal(onPressed: () => _restock(context, b), child: const Text('Restock')),
                    ],
                ]),
              ),
            ],
          );
        },
      );

  void _restock(BuildContext context, Book b) {
    final c = TextEditingController(text: '100');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restock · ${b.title}'),
        content: TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Units received')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(c.text) ?? 0;
              if (!adm.act(context, 'inventory', 'Restocked ${b.id}', before: '${app.stockOf(b)}', after: '${app.stockOf(b) + n}')) return;
              app.stockAdj[b.id] = (app.stockAdj[b.id] ?? 0) + n;
              app.zohoEvents.insert(0, ZohoEvent('Stock', b.id, 'Inventory adjustment +$n pushed to Zoho', true, DateTime.now()));
              if (app.stockAlerts.contains(b.id)) app.notify('Back in stock', '${b.title} is available again.', 'WhatsApp');
              app.update(() {});
              Navigator.pop(ctx);
              adminToast(context, 'Stock updated · back-in-stock alerts triggered for subscribed wishlists');
            },
            child: const Text('Add stock'),
          ),
        ],
      ),
    );
  }
}

// ============================================================ Orders
class OrdersModule extends StatefulWidget {
  const OrdersModule({super.key});
  @override
  State<OrdersModule> createState() => _OrdersModuleState();
}

class _OrdersModuleState extends State<OrdersModule> {
  String filter = 'All', q = '';
  static const filters = ['All', 'Confirmed', 'Packed', 'Dispatched', 'Delivered', 'Cancelled'];

  bool _match(Order o) {
    if (q.isNotEmpty && !o.id.toLowerCase().contains(q.toLowerCase()) && !o.address.name.toLowerCase().contains(q.toLowerCase())) return false;
    return switch (filter) { 'Confirmed' => o.stage == 0 || o.stage == 1, 'Packed' => o.stage == 2, 'Dispatched' => o.stage == 3 || o.stage == 4, 'Delivered' => o.stage == 5, 'Cancelled' => o.stage < 0, _ => true };
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([adm, app]),
        builder: (context, _) {
          final list = adm.allOrders.where(_match).toList();
          return AdminPage(
            module: 'orders',
            title: 'Orders',
            subtitle: 'Synced with Zoho Inventory sales orders · status changes notify customers on WhatsApp',
            actions: [OutlinedButton.icon(onPressed: () => showExport(context, 'orders.csv', 'order_id,customer,total,status\n${list.take(5).map((o) => '${o.id},${o.address.name},${o.total},${o.statusLabel}').join('\n')}'), icon: const Icon(Icons.download), label: const Text('Export'))],
            children: [
              Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SizedBox(width: 260, child: TextField(decoration: const InputDecoration(hintText: 'Search order or customer', prefixIcon: Icon(Icons.search), isDense: true), onChanged: (v) => setState(() => q = v))),
                for (final f in filters) ChoiceChip(label: Text(f), selected: filter == f, onSelected: (_) => setState(() => filter = f)),
              ]),
              const SizedBox(height: 12),
              Panel(
                child: DataGrid(['Order', 'Customer', 'Date', 'Total', 'Payment', 'Status', 'Actions'], [
                  for (final o in list.take(30))
                    [
                      Text(o.id, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(o.address.name),
                      Text(shortDate(o.date)),
                      Text(inr(o.total)),
                      Text(o.payment, style: const TextStyle(fontSize: 12)),
                      Pill(o.statusLabel, color: _stageColor(o)),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        PopupMenuButton<int>(
                          tooltip: 'Update fulfilment status',
                          icon: const Icon(Icons.edit_note),
                          onSelected: (v) => _setStatus(context, o, v),
                          itemBuilder: (_) => [for (var i = 0; i < Order.stages.length; i++) PopupMenuItem(value: i, child: Text(Order.stages[i]))],
                        ),
                        IconButton(tooltip: 'Generate invoice', icon: const Icon(Icons.receipt_long, size: 20), onPressed: () { if (adm.act(context, 'orders', 'Generated invoice ${o.id}')) { app.zohoEvents.insert(0, ZohoEvent('Invoice', o.id, 'Zoho Books invoice regenerated', true, DateTime.now())); showExport(context, 'INV-${o.id.split('-').last}.pdf', 'Zoho Books GST invoice\nCustomer: ${o.address.name}\nTotal: ${inr(o.total)}\nSent to customer by email${app.waOptIn ? ' + WhatsApp' : ''}.'); } }),
                        IconButton(tooltip: 'Initiate refund', icon: const Icon(Icons.undo, size: 20), onPressed: o.stage < 0 ? null : () => _refund(context, o)),
                      ]),
                    ],
                ]),
              ),
            ],
          );
        },
      );

  void _setStatus(BuildContext context, Order o, int v) {
    if (!adm.act(context, 'orders', 'Order ${o.id} status', before: o.statusLabel, after: Order.stages[v])) return;
    o.stage = v;
    app.zohoEvents.insert(0, ZohoEvent('Sales Order', o.id, 'Status “${Order.stages[v]}” synced to Zoho', true, DateTime.now()));
    if (app.orders.contains(o)) {
      app.waLog.insert(0, (o.id, '${Order.stages[v]} — ${o.id}', DateTime.now()));
      app.notify(Order.stages[v], 'Order ${o.id}: ${Order.stages[v]}', 'WhatsApp');
    }
    app.update(() {});
    adminToast(context, 'Status updated · customer notified on WhatsApp');
  }

  void _refund(BuildContext context, Order o) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Refund ${o.id}?'),
        content: Text('Refund ${inr(o.total)} to ${o.payment}. A credit note will be created in Zoho Books and linked to the original invoice.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!adm.act(context, 'orders', 'Refund initiated ${o.id}', before: o.statusLabel, after: 'Cancelled · refund ${inr(o.total)}')) return;
              o.stage = -1;
              app.zohoEvents.insert(0, ZohoEvent('Credit Note', o.id, 'Credit note created & linked to invoice', true, DateTime.now()));
              app.update(() {});
              Navigator.pop(ctx);
              adminToast(context, 'Refund initiated · customer notified');
            },
            child: const Text('Confirm refund'),
          ),
        ],
      ),
    );
  }
}

// ============================================================ Subscriptions
class SubscriptionsModule extends StatelessWidget {
  const SubscriptionsModule({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([adm, app]),
        builder: (context, _) => AdminPage(
          module: 'subscriptions',
          title: 'Subscriptions',
          subtitle: 'Razorpay Subscriptions (India) · Stripe Billing (international) · states: trial, active, grace, suspended, cancelled',
          children: [
            Wrap(spacing: 12, runSpacing: 12, children: [
              StatTile('Active', '${adm.subs.where((s) => s.status == 'active').length}', Icons.check_circle, color: BvtColors.green),
              StatTile('On trial', '${adm.subs.where((s) => s.status == 'trial').length}', Icons.hourglass_top),
              StatTile('Grace period', '${adm.subs.where((s) => s.status == 'grace').length}', Icons.warning_amber, color: const Color(0xFFE65100)),
              StatTile('Cancelled', '${adm.subs.where((s) => s.status == 'cancelled').length}', Icons.cancel, color: BvtColors.red),
            ]),
            const SizedBox(height: 16),
            Panel(
              title: 'All subscriptions',
              child: DataGrid(['ID', 'Customer', 'Plan', 'Status', 'Renews', 'Actions'], [
                for (final s in adm.subs)
                  [
                    Text(s.id),
                    Text(s.customer),
                    Text(s.plan),
                    Pill(s.status, color: switch (s.status) { 'active' => BvtColors.green, 'trial' => BvtColors.deepSaffron, 'grace' => const Color(0xFFE65100), 'paused' => BvtColors.muted, _ => BvtColors.red }),
                    Text(shortDate(s.renews)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      TextButton(onPressed: s.status == 'cancelled' ? null : () { if (adm.act(context, 'subscriptions', 'Force-cancelled ${s.id}', before: s.status, after: 'cancelled')) { s.status = 'cancelled'; adm.changed(); } }, child: const Text('Force-cancel')),
                      TextButton(onPressed: () { if (adm.act(context, 'subscriptions', 'Extended ${s.id} by 30 days')) { s.renews = s.renews.add(const Duration(days: 30)); if (s.status == 'grace' || s.status == 'cancelled') s.status = 'active'; adm.changed(); } }, child: const Text('Extend 30d')),
                      PopupMenuButton<String>(
                        tooltip: 'Override tier',
                        child: const Padding(padding: EdgeInsets.all(8), child: Text('Override tier', style: TextStyle(color: BvtColors.deepSaffron, fontWeight: FontWeight.w700))),
                        onSelected: (t) { if (adm.act(context, 'subscriptions', 'Tier override ${s.id}', before: s.tier, after: t)) { s.tier = t; adm.changed(); adminToast(context, '${s.id} moved to $t tier'); } },
                        itemBuilder: (_) => const [PopupMenuItem(value: 'book', child: Text('Per-book')), PopupMenuItem(value: 'lang', child: Text('Language All-Access')), PopupMenuItem(value: 'global', child: Text('Global All-Access'))],
                      ),
                    ]),
                  ],
              ]),
            ),
            if (app.subscriptions.isNotEmpty)
              Panel(
                title: 'Storefront demo user · ${app.name}',
                child: DataGrid(['ID', 'Title', 'Status', 'Renews', ''], [
                  for (final s in app.subscriptions)
                    [Text(s.id), Text(s.title), Pill(s.status, color: s.status == 'cancelled' ? BvtColors.red : BvtColors.green), Text(shortDate(s.renews)), TextButton(onPressed: () { if (adm.act(context, 'subscriptions', 'Force-cancelled ${s.id}')) app.setSubStatus(s, 'cancelled'); }, child: const Text('Force-cancel'))],
                ]),
              ),
          ],
        ),
      );
}

// ============================================================ Customers
class CustomersModule extends StatefulWidget {
  const CustomersModule({super.key});
  @override
  State<CustomersModule> createState() => _CustomersModuleState();
}

class _CustomersModuleState extends State<CustomersModule> {
  String q = '';
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([adm, app]),
        builder: (context, _) {
          final list = adm.customers.where((c) => q.isEmpty || c.name.toLowerCase().contains(q.toLowerCase()) || c.email.toLowerCase().contains(q.toLowerCase())).toList();
          return AdminPage(
            module: 'customers',
            title: 'Customers',
            subtitle: 'Contacts are synced to Zoho CRM / Books with BMM tier as a custom field',
            children: [
              SizedBox(width: 320, child: TextField(decoration: const InputDecoration(hintText: 'Search name or email', prefixIcon: Icon(Icons.search), isDense: true), onChanged: (v) => setState(() => q = v))),
              const SizedBox(height: 12),
              Panel(
                child: DataGrid(['Customer', 'Contact', 'City', 'Orders', 'Lifetime', 'BMM tier', 'Blocked', ''], [
                  for (final c in list)
                    [
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('${c.email}\n${c.phone}', style: const TextStyle(fontSize: 12)),
                      Text(c.city),
                      Text('${c.orders}'),
                      Text(inr(c.spend)),
                      Switch(value: c.id == 'C-1001' ? app.bmm : c.bmm, onChanged: (v) { if (adm.act(context, 'customers', 'BMM tier override · ${c.name}', before: c.bmm ? 'member' : 'none', after: v ? 'member' : 'none')) { c.bmm = v; if (c.id == 'C-1001') app.update(() => app.bmm = v); adm.changed(); app.zohoEvents.insert(0, ZohoEvent('Contact', c.email, 'BMM tier tag updated in Zoho CRM', true, DateTime.now())); } }),
                      Switch(value: c.blocked, activeThumbColor: BvtColors.red, onChanged: (v) { if (adm.act(context, 'customers', '${v ? 'Blocked' : 'Unblocked'} ${c.name}', before: c.blocked ? 'blocked' : 'active', after: v ? 'blocked' : 'active')) { c.blocked = v; if (c.id == 'C-1001') app.update(() => app.blocked = v); adm.changed(); } }),
                      TextButton(onPressed: () => _history(context, c), child: const Text('History')),
                    ],
                ]),
              ),
            ],
          );
        },
      );

  void _history(BuildContext context, Customer c) {
    final os = adm.allOrders.where((o) => o.address.name == c.name).toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(c.name),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${c.email} · ${c.phone}'),
            const SizedBox(height: 10),
            const Text('Order & subscription history', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            if (os.isEmpty) const Text('No recent orders in this sample.', style: TextStyle(color: BvtColors.muted)),
            for (final o in os) ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text('${o.id} · ${inr(o.total)}'), subtitle: Text('${dateFmt(o.date)} · ${o.statusLabel}')),
            for (final s in adm.subs.where((s) => s.customer == c.name)) ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.workspace_premium, size: 18), title: Text(s.plan), subtitle: Text(s.status)),
          ]),
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}

// ============================================================ Shipping
class ShippingModule extends StatelessWidget {
  const ShippingModule({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([adm, app]),
        builder: (context, _) {
          final os = adm.allOrders;
          int n(bool Function(Order) t) => os.where(t).length;
          return AdminPage(
            module: 'shipping',
            title: 'Shipping',
            subtitle: 'Courier partner APIs: live rates, order creation, tracking webhooks · AWB is written back to Zoho Inventory',
            children: [
              Wrap(spacing: 12, runSpacing: 12, children: [
                StatTile('To pack', '${n((o) => o.stage == 1)}', Icons.inventory, color: BvtColors.deepSaffron),
                StatTile('In transit', '${n((o) => o.stage == 3)}', Icons.local_shipping, color: const Color(0xFF3B6EA5)),
                StatTile('Out for delivery', '${n((o) => o.stage == 4)}', Icons.directions_bike, color: BvtColors.maroon),
                StatTile('Delivered', '${n((o) => o.stage == 5)}', Icons.check_circle, color: BvtColors.green),
                StatTile('Returns / RTO', '${n((o) => o.stage == -2)}', Icons.assignment_return, color: BvtColors.red),
              ]),
              const SizedBox(height: 16),
              Panel(
                title: 'Courier partner connections',
                child: Column(children: [
                  for (final c in adm.couriers)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(backgroundColor: BvtColors.sand, child: Icon(Icons.local_shipping, color: BvtColors.deepSaffron)),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('API key ${c.key} · ${c.status} · rate limit ${c.limit}/hr'),
                      trailing: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        OutlinedButton(onPressed: () { if (adm.act(context, 'shipping', 'Tested connection · ${c.name}')) adminToast(context, '${c.name}: connection OK (rates + webhook signature verified)'); }, child: const Text('Test')),
                        Switch(value: c.enabled, onChanged: (v) { if (adm.act(context, 'shipping', '${v ? 'Enabled' : 'Disabled'} ${c.name}', before: c.enabled ? 'enabled' : 'disabled', after: v ? 'enabled' : 'disabled')) { c.enabled = v; adm.changed(); } }),
                      ]),
                    ),
                ]),
              ),
              Panel(
                title: 'Aggregated tracking dashboard',
                child: DataGrid(['Order', 'Courier', 'AWB', 'Destination', 'Status', 'Last scan'], [
                  for (final o in os.where((o) => o.stage >= 2).take(12))
                    [Text(o.id), Text(o.courier), Text(o.awb, style: const TextStyle(fontSize: 12)), Text(o.address.city), Pill(o.statusLabel, color: _stageColor(o)), Text(dayTime(o.date.add(Duration(hours: o.stage * 12))))],
                ]),
              ),
            ],
          );
        },
      );
}
