import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'admin_state.dart';
import 'admin_widgets.dart';

// ============================================================ Reports
class ReportsModule extends StatefulWidget {
  const ReportsModule({super.key});
  @override
  State<ReportsModule> createState() => _ReportsModuleState();
}

class _ReportsModuleState extends State<ReportsModule> {
  int period = 30;
  @override
  Widget build(BuildContext context) {
    final s = adm.sales(period);
    return AdminPage(module: 'reports', title: 'Reports & analytics', subtitle: 'Sales, subscription MRR/ARR, WhatsApp campaign performance, search analytics', children: [
      SegmentedButton<int>(segments: const [ButtonSegment(value: 7, label: Text('7 days')), ButtonSegment(value: 14, label: Text('14 days')), ButtonSegment(value: 30, label: Text('30 days'))], selected: {period}, onSelectionChanged: (v) => setState(() => period = v.first)),
      const SizedBox(height: 16),
      Panel(title: 'Sales by period', child: BarChart(s, [for (var i = period - 1; i >= 0; i--) shortDate(DateTime.now().subtract(Duration(days: i)))])),
      LayoutBuilder(builder: (c, box) {
        final a = Panel(title: 'Sales by language', child: Column(children: [for (final e in [('English', 38.0), ('Hindi', 27.0), ('Gujarati', 16.0), ('Marathi', 7.0), ('Bengali', 5.0), ('Other', 7.0)]) HBar(e.$1, e.$2, 40, '${e.$2.round()}%')]));
        final b = Panel(title: 'Sales by region', child: Column(children: [for (final e in [('Gujarat', 31.0), ('Maharashtra', 18.0), ('Delhi NCR', 11.0), ('Karnataka', 8.0), ('International', 17.0), ('Other India', 15.0)]) HBar(e.$1, e.$2, 40, '${e.$2.round()}%', color: BvtColors.maroon)]));
        return box.maxWidth > 800 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 16), Expanded(child: b)]) : Column(children: [a, b]);
      }),
      Panel(title: 'Sales by product (top 6)', child: Column(children: [for (var i = 0; i < 6; i++) HBar(allBooks[(i * 6) % allBooks.length].title, 120 - i * 15.0, 120, inr((120 - i * 15) * 800), color: const Color(0xFF3B6EA5))])),
      Panel(title: 'Subscription metrics', child: Wrap(spacing: 12, runSpacing: 12, children: const [
        StatTile('MRR', '₹4.82 L', Icons.autorenew, delta: '+3.2%', color: BvtColors.green),
        StatTile('ARR', '₹57.8 L', Icons.trending_up, delta: '+11%', color: BvtColors.green),
        StatTile('Monthly churn', '2.9%', Icons.person_off, delta: '-0.4%', color: BvtColors.red),
        StatTile('Trial → paid', '41%', Icons.swap_vert, color: Color(0xFF3B6EA5)),
      ])),
      Panel(title: 'Tier-wise breakdown', child: Column(children: const [HBar('Per-Book', 420, 1500, '420 subs'), HBar('Language All-Access', 1380, 1500, '1,380 subs', color: BvtColors.maroon), HBar('Global All-Access', 360, 1500, '360 subs', color: BvtColors.gold)])),
      Panel(title: 'WhatsApp campaign performance', child: DataGrid(['Campaign', 'Sent', 'Delivered', 'Read'], [for (final c in adm.campaigns) [Text(c.name), Text('${c.sent}'), Text(c.sent == 0 ? '—' : '${(c.delivered * 100 / c.sent).round()}%'), Text(c.sent == 0 ? '—' : '${(c.read * 100 / c.sent).round()}%')]])),
      Panel(title: 'Search zero-results report', child: Column(children: [for (final z in app.zeroResults.take(6)) ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.search_off), title: Text(z.$1), subtitle: Text(dayTime(z.$2)))])),
    ]);
  }
}

// ============================================================ Finance
class FinanceModule extends StatelessWidget {
  const FinanceModule({super.key});
  @override
  Widget build(BuildContext context) {
    final rev = adm.sales(30).reduce((a, b) => a + b);
    return AdminPage(module: 'finance', title: 'Finance', subtitle: 'Revenue, GST and payout summaries — Zoho Books is the financial system of record', actions: [
      OutlinedButton.icon(onPressed: () => showExport(context, 'finance_summary_oct2026.xlsx', 'Sheet: Revenue\nGross,${rev.round()}\nRefunds,18400\nNet,${rev.round() - 18400}\n\nSheet: GST\nCGST,12480\nSGST,12480\nIGST,18930'), icon: const Icon(Icons.table_chart), label: const Text('Export Excel')),
      OutlinedButton.icon(onPressed: () => showExport(context, 'gst_report_oct2026.csv', 'type,taxable,tax\nCGST+SGST,208000,24960\nIGST,157750,18930\nExport (nil),64200,0'), icon: const Icon(Icons.download), label: const Text('Export CSV')),
    ], children: [
      Wrap(spacing: 12, runSpacing: 12, children: [
        StatTile('Gross revenue (30d)', inr(rev), Icons.currency_rupee, color: BvtColors.green, delta: '+12%'),
        const StatTile('Refunds / credit notes', '₹18,400', Icons.undo, color: BvtColors.red),
        StatTile('Net revenue', inr(rev - 18400), Icons.account_balance_wallet),
        const StatTile('GST collected', '₹56,370', Icons.receipt, color: BvtColors.maroon),
      ]),
      const SizedBox(height: 16),
      Panel(title: 'GST report', child: DataGrid(['Tax type', 'Taxable value', 'Tax', 'Basis'], [
        [const Text('CGST + SGST'), Text(inr(208000)), Text(inr(24960)), const Text('Intra-state (Gujarat)')],
        [const Text('IGST'), Text(inr(157750)), Text(inr(18930)), const Text('Inter-state')],
        [const Text('Export'), Text(inr(64200)), Text(inr(0)), const Text('International · nil-rated')],
      ])),
      Panel(title: 'Payout summaries', child: DataGrid(['Gateway', 'Gross', 'Fees', 'Net payout', 'Settled to'], [
        [const Text('Razorpay'), Text(inr(312000)), Text(inr(6240)), Text(inr(305760)), const Text('HDFC · Domestic')],
        [const Text('Stripe'), Text(inr(96400)), Text(inr(3180)), Text(inr(93220)), const Text('ICICI · International')],
        [const Text('Cash on Delivery'), Text(inr(41200)), Text(inr(1650)), Text(inr(39550)), const Text('Courier remittance')],
      ])),
    ]);
  }
}

// ============================================================ Zoho
class ZohoModule extends StatefulWidget {
  const ZohoModule({super.key});
  @override
  State<ZohoModule> createState() => _ZohoModuleState();
}

class _ZohoModuleState extends State<ZohoModule> {
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([adm, app]),
        builder: (context, _) {
          final failed = app.zohoEvents.where((e) => !e.ok).toList();
          final orders = adm.allOrders.length;
          return AdminPage(
            module: 'zoho',
            title: 'Zoho sync dashboard',
            subtitle: 'Standalone integration service · OAuth 2.0 · idempotent writes · dead-letter queue with exponential backoff · Zoho API v1/v3',
            actions: [OutlinedButton.icon(onPressed: _webhook, icon: const Icon(Icons.webhook), label: const Text('Simulate Zoho webhook'))],
            children: [
              Wrap(spacing: 12, runSpacing: 12, children: [
                for (final e in [('Inventory', Icons.inventory_2, 'Sales orders · stock · AWB', 0), ('Books', Icons.menu_book, 'Invoices · payments · credit notes', 0), ('CRM', Icons.contacts, 'Contacts · BMM tag', failed.where((f) => f.entity == 'Contact').length)])
                  SizedBox(width: 280, child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Icon(e.$2, color: BvtColors.deepSaffron), const SizedBox(width: 8), Text('Zoho ${e.$1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), const Spacer(), Pill(e.$4 == 0 ? 'Healthy' : 'Degraded', color: e.$4 == 0 ? BvtColors.green : const Color(0xFFE65100))]),
                    const SizedBox(height: 6),
                    Text(e.$3, style: const TextStyle(color: BvtColors.muted, fontSize: 12.5)),
                    const SizedBox(height: 8),
                    Text('Last successful sync: ${dayTime(DateTime.now().subtract(Duration(minutes: 3 + e.$4 * 120)))}', style: const TextStyle(fontSize: 12.5)),
                    Text('Pending queue depth: ${e.$4}', style: const TextStyle(fontSize: 12.5)),
                  ])))),
              ]),
              const SizedBox(height: 16),
              Panel(title: 'Daily reconciliation report', actions: [TextButton(onPressed: () => showExport(context, 'recon_${DateTime.now().day}.csv', 'orders_created,$orders\nzoho_orders,$orders\npayments_received,${orders - 2}\ninvoices_paid,${orders - 2}\nmismatches,2 flagged'), child: const Text('Send to finance'))], child: Wrap(spacing: 12, runSpacing: 12, children: [
                StatTile('Orders (site vs Zoho)', '$orders / $orders', Icons.compare_arrows, color: BvtColors.green),
                StatTile('Payments vs invoices paid', '${orders - 2} / ${orders - 2}', Icons.payments, color: BvtColors.green),
                const StatTile('Pending invoices', '2', Icons.pending_actions, color: Color(0xFFE65100)),
                StatTile('Failed payments', '${failed.length}', Icons.error_outline, color: BvtColors.red),
              ])),
              Panel(title: 'Event log & dead-letter queue', child: DataGrid(['Entity', 'Reference', 'Message', 'Time', 'Status', ''], [
                for (final e in app.zohoEvents.take(25))
                  [
                    Text(e.entity),
                    Text(e.ref, style: const TextStyle(fontSize: 12)),
                    SizedBox(width: 260, child: Text(e.message, maxLines: 2, overflow: TextOverflow.ellipsis)),
                    Text(dayTime(e.at)),
                    e.ok ? const Pill('OK', color: BvtColors.green) : Pill('Failed · ${e.retries}/3 retries', color: BvtColors.red),
                    e.ok ? const SizedBox() : TextButton(onPressed: () { if (adm.act(context, 'zoho', 'Manual retry · ${e.entity} ${e.ref}')) { setState(() { e.ok = true; e.retries++; }); adminToast(context, 'Retry succeeded (idempotency key matched — no duplicate created)'); } }, child: const Text('Retry')),
                  ],
              ])),
              LayoutBuilder(builder: (c, box) {
                final rules = Panel(title: 'Conflict resolution rules', child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('• Financial records (invoices, payments, credit notes): Zoho wins'), SizedBox(height: 4), Text('• Order fulfilment status: website wins'), SizedBox(height: 4), Text('• Stock levels: Zoho Inventory is authoritative; 5-minute cache, invalidated on fulfilment'), SizedBox(height: 4), Text('• Retry policy: exponential backoff, max 3 retries, then admin alert'), SizedBox(height: 4), Text('• Rate limits: request throttling + queueing in middleware'),
                ]));
                final auth = Panel(title: 'Connection', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  KV('OAuth 2.0 (server flow)', 'Token valid · auto-refresh in 41 min'), KV('Webhook receiver', 'Signed endpoint · active'), KV('API rate usage', '1,240 / 5,000 per day'), KV('Zoho API version', 'Inventory v1 · Books v3 · CRM v6'), KV('Upgrade path', 'Documented in Integration Guide'),
                ]));
                return box.maxWidth > 800 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: rules), const SizedBox(width: 16), Expanded(child: auth)]) : Column(children: [rules, auth]);
              }),
            ],
          );
        },
      );

  void _webhook() {
    if (!adm.act(context, 'zoho', 'Simulated Zoho webhook · stock adjusted')) return;
    final b = catalog.firstWhere((b) => app.stockOf(b) > 0);
    app.stockAdj[b.id] = (app.stockAdj[b.id] ?? 0) - 3;
    app.zohoEvents.insert(0, ZohoEvent('Stock', b.id, 'Webhook: stock manually adjusted in Zoho (-3) → website updated', true, DateTime.now()));
    app.update(() {});
    adminToast(context, 'Webhook received & signature verified — ${b.title} stock now ${app.stockOf(b)}');
  }
}

class KV extends StatelessWidget {
  final String k, v;
  const KV(this.k, this.v, {super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text(k, style: const TextStyle(color: BvtColors.muted))), Text(v, style: const TextStyle(fontWeight: FontWeight.w700))]));
}

// ============================================================ Audit
class AuditModule extends StatelessWidget {
  const AuditModule({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: adm,
        builder: (context, _) => AdminPage(
          module: 'audit',
          title: 'Audit log',
          subtitle: 'Every admin action is logged with timestamp, user and before/after state — immutable & exportable',
          actions: [OutlinedButton.icon(onPressed: () => showExport(context, 'audit_log.csv', 'timestamp,user,role,module,action,before,after\n${adm.audit.take(4).map((a) => '${dayTime(a.at)},${a.user},${a.role},${a.module},"${a.action}",${a.before},${a.after}').join('\n')}'), icon: const Icon(Icons.download), label: const Text('Export'))],
          children: [
            Panel(child: DataGrid(['When', 'User', 'Role', 'Module', 'Action', 'Before', 'After'], [for (final a in adm.audit.take(60)) [Text(dayTime(a.at)), Text(a.user), Text(a.role, style: const TextStyle(fontSize: 12)), Text(a.module), SizedBox(width: 240, child: Text(a.action, maxLines: 2, overflow: TextOverflow.ellipsis)), Text(a.before, style: const TextStyle(color: BvtColors.red)), Text(a.after, style: const TextStyle(color: BvtColors.green))]])),
            const Text('Entries cannot be edited or deleted.', style: TextStyle(color: BvtColors.muted, fontSize: 12.5)),
          ],
        ),
      );
}

// ============================================================ Roles
class RolesModule extends StatelessWidget {
  const RolesModule({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: adm,
        builder: (context, _) => AdminPage(
          module: 'roles',
          title: 'Roles & security',
          subtitle: 'Granular read/write permissions per module · enforced server-side',
          actions: [FilledButton.icon(onPressed: () => _create(context), icon: const Icon(Icons.add), label: const Text('Create custom role'))],
          children: [
            Panel(
              title: 'Permission matrix',
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 14,
                  headingRowHeight: 40,
                  dataRowMinHeight: 38,
                  dataRowMaxHeight: 44,
                  columns: [const DataColumn(label: Text('Module')), for (final r in adm.roles) DataColumn(label: Text(r.name, style: const TextStyle(fontSize: 11.5)))],
                  rows: [
                    for (final m in adminModules)
                      DataRow(cells: [
                        DataCell(Text(m.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                        for (final r in adm.roles)
                          DataCell(r.system && r.name == 'Super Admin'
                              ? const Icon(Icons.edit, size: 16, color: BvtColors.green)
                              : PopupMenuButton<int>(
                                  tooltip: 'Change',
                                  onSelected: (v) { if (adm.act(context, 'roles', 'Permission · ${r.name} / ${m.label}', before: _lv(r.perms[m.key] ?? 0), after: _lv(v))) { r.perms[m.key] = v; adm.changed(); } },
                                  itemBuilder: (_) => const [PopupMenuItem(value: 0, child: Text('No access')), PopupMenuItem(value: 1, child: Text('Read')), PopupMenuItem(value: 2, child: Text('Read / write'))],
                                  child: Icon((r.perms[m.key] ?? 0) == 2 ? Icons.edit : (r.perms[m.key] ?? 0) == 1 ? Icons.visibility : Icons.block, size: 18, color: (r.perms[m.key] ?? 0) == 2 ? BvtColors.green : (r.perms[m.key] ?? 0) == 1 ? BvtColors.deepSaffron : Colors.black26),
                                )),
                      ]),
                  ],
                ),
              ),
            ),
            const Text('Legend: ✏ read/write · 👁 read-only · ⊘ none. Tap a cell to change. Use “View as” in the top bar to test a role.', style: TextStyle(color: BvtColors.muted, fontSize: 12.5)),
            const SizedBox(height: 16),
            Panel(title: 'Staff users', child: DataGrid(['Name', 'Email', 'Role', '2FA', 'Active'], [
              for (final u in _users) [Text(u.name), Text(u.email), Text(u.role), Icon(u.twoFa ? Icons.verified_user : Icons.warning, color: u.twoFa ? BvtColors.green : BvtColors.red, size: 18), Switch(value: u.active, onChanged: (v) { if (adm.act(context, 'roles', '${v ? 'Activated' : 'Deactivated'} ${u.name}')) { u.active = v; adm.changed(); } })],
            ])),
          ],
        ),
      );

  static String _lv(int v) => v == 2 ? 'read/write' : v == 1 ? 'read' : 'none';

  static final _users = [AdminUser('Avantika Parwe', 'avantika@bvks.com', 'Super Admin'), AdminUser('Rohan K.', 'rohan@bvks.com', 'Catalog Manager'), AdminUser('Meera S.', 'meera@bvks.com', 'Support Agent'), AdminUser('Priya D.', 'priya@bvks.com', 'Content Editor'), AdminUser('Suresh T.', 'suresh@bvks.com', 'Finance Viewer'), AdminUser('Kiran B.', 'kiran@bvks.com', 'Shipping Manager')];

  void _create(BuildContext context) {
    final n = TextEditingController(text: 'Temple Coordinator');
    final sel = <String, int>{'dashboard': 1, 'orders': 1, 'products': 1};
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Create custom role'),
          content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: n, decoration: const InputDecoration(labelText: 'Role name')),
            const SizedBox(height: 8),
            for (final m in adminModules) Row(children: [Expanded(child: Text(m.label, style: const TextStyle(fontSize: 13))), SegmentedButton<int>(showSelectedIcon: false, style: const ButtonStyle(visualDensity: VisualDensity.compact), segments: const [ButtonSegment(value: 0, label: Text('–')), ButtonSegment(value: 1, label: Text('R')), ButtonSegment(value: 2, label: Text('RW'))], selected: {sel[m.key] ?? 0}, onSelectionChanged: (v) => set(() => sel[m.key] = v.first))]),
          ]))),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () {
            if (!adm.act(context, 'roles', 'Created role · ${n.text}', after: '${sel.values.where((v) => v > 0).length} modules')) return;
            adm.roles.add(AdminRole(n.text, {for (final m in adminModules) m.key: sel[m.key] ?? 0}, system: false));
            adm.changed();
            Navigator.pop(ctx);
          }, child: const Text('Create'))],
        ),
      ),
    );
  }
}

// ============================================================ Settings
class SettingsModule extends StatelessWidget {
  const SettingsModule({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([adm, app]),
        builder: (context, _) => AdminPage(module: 'settings', title: 'Settings', subtitle: 'Security, subscriptions and platform configuration', children: [
          Panel(title: 'Security', child: Column(children: [
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Mandatory 2FA for all admin users'), value: adm.twoFaEnforced, onChanged: (v) { if (adm.act(context, 'settings', '2FA enforcement', before: '${adm.twoFaEnforced}', after: '$v')) { adm.twoFaEnforced = v; adm.changed(); } }),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('IP allow-list'), subtitle: Text(adm.ips.join('  ·  ')), value: adm.ipWhitelist, onChanged: (v) { if (adm.act(context, 'settings', 'IP allow-list', before: '${adm.ipWhitelist}', after: '$v')) { adm.ipWhitelist = v; adm.changed(); } }),
          ])),
          Panel(title: 'Subscription trial periods', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Override free-trial days for all tiers (0 = per-plan default: 3 / 7 / 7).', style: TextStyle(color: BvtColors.muted)),
            Row(children: [Expanded(child: Slider(value: app.trialOverride.toDouble(), min: 0, max: 30, divisions: 30, label: '${app.trialOverride}', onChanged: (v) { if (adm.act(context, 'settings', 'Trial days override', before: '${app.trialOverride}', after: '${v.round()}')) app.update(() => app.trialOverride = v.round()); })), Text(app.trialOverride == 0 ? 'Default' : '${app.trialOverride} days', style: const TextStyle(fontWeight: FontWeight.w800))]),
          ])),
          Panel(title: 'Commerce', child: Column(children: [
            const KV('BMM threshold / minimum order', '₹5,000 / ₹2,000'),
            const KV('BMM wholesale discount', '30%'),
            const KV('Grace period on failed payment', '7 days'),
            const KV('DRM signed-URL expiry', '60 minutes'),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('App-exclusive offers / early-access flag'), value: app.appExclusive, onChanged: (v) { if (adm.act(context, 'settings', 'App-exclusive flag', before: '${app.appExclusive}', after: '$v')) app.update(() => app.appExclusive = v); }),
          ])),
        ]),
      );
}
