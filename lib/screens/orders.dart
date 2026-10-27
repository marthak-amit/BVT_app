import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

Color stageColor(Order o) => o.stage == -1 ? BvtColors.red : o.stage == -2 ? const Color(0xFFE65100) : o.stage >= 5 ? BvtColors.green : BvtColors.deepSaffron;

class OrderConfirmationScreen extends StatelessWidget {
  final Order order;
  final bool accountCreated;
  const OrderConfirmationScreen(this.order, {super.key, this.accountCreated = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Order confirmed')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const SizedBox(height: 8),
        Center(child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 700), curve: Curves.elasticOut, builder: (_, v, c) => Transform.scale(scale: v, child: c), child: const Icon(Icons.check_circle, size: 92, color: BvtColors.green))),
        const SizedBox(height: 12),
        Text('Thank you! Hare Kṛṣṇa 🙏', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('Order ${order.id} · ${dateFmt(order.date)}', textAlign: TextAlign.center, style: const TextStyle(color: BvtColors.muted)),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final l in order.lines) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Expanded(child: Text('${l.title} × ${l.qty}', maxLines: 1, overflow: TextOverflow.ellipsis)), Text(inr(l.unitPrice * l.qty), style: const TextStyle(fontWeight: FontWeight.w700))])),
              const Divider(height: 22),
              if (order.discount > 0) KeyVal('Savings', '-${inr(order.discount)}', color: BvtColors.green),
              KeyVal('Shipping', order.shipping == 0 ? 'FREE' : inr(order.shipping)),
              KeyVal('Total paid', inr(order.total), bold: true),
              const SizedBox(height: 4),
              Text('Paid via ${order.payment}', style: const TextStyle(fontSize: 12.5, color: BvtColors.muted)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.local_shipping, color: BvtColors.deepSaffron),
            title: Text('${order.courier} · ${order.awb}'),
            subtitle: Text('Delivering to ${order.address.city}, ${order.address.pin}\nEstimated delivery: ${dateFmt(order.date.add(const Duration(days: 6)))}'),
            isThreeLine: true,
          ),
        ),
        const SizedBox(height: 12),
        if (app.waOptIn) _WaBubble('Hare Kṛṣṇa ${app.name.split(' ').first}! ✅ Your BVT order ${order.id} is confirmed.\nTotal ${inr(order.total)}. Invoice PDF attached. Track: bvks.in/t/${order.id.split('-').last}')
        else Card(child: ListTile(leading: const Icon(Icons.mail_outline), title: const Text('Confirmation sent by email'), subtitle: const Text('Turn on WhatsApp updates in Account → WhatsApp preferences'))),
        if (accountCreated) const Padding(padding: EdgeInsets.only(top: 12), child: Text('✅ Your account was created — check your email to verify.', textAlign: TextAlign.center, style: TextStyle(color: BvtColors.green, fontWeight: FontWeight.w600))),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: () => push(context, OrderTrackingScreen(order)), icon: const Icon(Icons.timeline), label: Text(app.t('track_order'))),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => showInvoice(context, order), icon: const Icon(Icons.receipt_long), label: const Text('View GST invoice')),
        TextButton(onPressed: () { tabIndex.value = 0; Navigator.of(context).popUntil((r) => r.isFirst); }, child: const Text('Continue shopping')),
      ]),
    );
  }
}

class _WaBubble extends StatelessWidget {
  final String text;
  const _WaBubble(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFE7F8EE), borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.chat, color: BvtColors.whatsapp, size: 18), SizedBox(width: 6), Text('WhatsApp notification sent', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF128C7E)))]),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFDCF8C6), borderRadius: BorderRadius.circular(10)), child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
        ]),
      );
}

void showInvoice(BuildContext context, Order o) {
  final intra = o.address.state == 'Gujarat';
  showDialog(
    context: context,
    builder: (_) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [const Icon(Icons.receipt_long, color: BvtColors.deepSaffron), const SizedBox(width: 8), const Expanded(child: Text('TAX INVOICE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
            const Text('Generated by Zoho Books', style: TextStyle(fontSize: 11.5, color: BvtColors.muted)),
            const Divider(height: 20),
            const Text('Bhakti Vikas Trust', style: TextStyle(fontWeight: FontWeight.w800)),
            const Text('Bharuch, Gujarat · GSTIN 24AAAAA0000A1Z5 (sample)', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            Text('Invoice: INV-${o.id.split('-').last}   Date: ${dateFmt(o.date)}', style: const TextStyle(fontSize: 12.5)),
            Text('Bill to: ${o.address.name}${o.address.gstin != null ? '  GSTIN ${o.address.gstin}' : ''}', style: const TextStyle(fontSize: 12.5)),
            Text(o.address.oneLine, style: const TextStyle(fontSize: 12.5)),
            const Divider(height: 20),
            for (final l in o.lines) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Expanded(child: Text('${l.title}\nHSN ${l.title.contains('Poster') || l.bookId.startsWith('poster') ? '4911' : '4901'} · ${l.qty} × ${inr(l.unitPrice)}', style: const TextStyle(fontSize: 12.5))), Text(inr(l.qty * l.unitPrice))])),
            const Divider(height: 20),
            KeyVal('Shipping', inr(o.shipping)),
            if (o.address.isIndia) KeyVal(intra ? 'CGST + SGST (incl.)' : 'IGST (incl.)', inr(o.tax)) else const KeyVal('GST', 'Export — nil'),
            KeyVal('Total', inr(o.total), bold: true),
            const SizedBox(height: 10),
            FilledButton.icon(onPressed: () { Navigator.pop(context); toast(context, 'Invoice PDF sent by email${app.waOptIn ? ' and WhatsApp' : ''}', icon: Icons.send); }, icon: const Icon(Icons.picture_as_pdf), label: const Text('Send PDF to me')),
          ]),
        ),
      ),
    ),
  );
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: Text(app.t('my_orders'))),
          body: app.orders.isEmpty
              ? EmptyState(Icons.receipt_long_outlined, 'No orders yet', 'Your orders and donation receipts will appear here.', action: 'Start shopping', onAction: () { tabIndex.value = 1; Navigator.of(context).popUntil((r) => r.isFirst); })
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: app.orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final o = app.orders[i];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => push(context, OrderDetailScreen(o)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [Expanded(child: Text(o.id, style: const TextStyle(fontWeight: FontWeight.w900))), Pill(o.isDonation ? 'Receipt' : o.statusLabel, color: stageColor(o))]),
                            Text('${dateFmt(o.date)} · ${inr(o.total)}', style: const TextStyle(color: BvtColors.muted, fontSize: 12.5)),
                            const SizedBox(height: 10),
                            if (!o.isDonation)
                              SizedBox(
                                height: 64,
                                child: ListView(scrollDirection: Axis.horizontal, children: [
                                  for (final l in o.lines) if (maybeBook(l.bookId) != null) Padding(padding: const EdgeInsets.only(right: 8), child: BookCover(bookById(l.bookId), width: 44, showLang: false)),
                                ]),
                              )
                            else
                              Text(o.lines.first.title),
                            const SizedBox(height: 8),
                            Row(children: [
                              if (!o.isDonation) OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)), onPressed: () => push(context, OrderTrackingScreen(o)), child: const Text('Track')),
                              const SizedBox(width: 8),
                              if (!o.isDonation) OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)), onPressed: () { app.reorder(o); toast(context, 'Items added to cart — one-click reorder', icon: Icons.replay, action: 'VIEW', onAction: () { tabIndex.value = 3; Navigator.of(context).popUntil((r) => r.isFirst); }); }, child: const Text('Reorder')),
                            ]),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
        ),
      );
}

class OrderDetailScreen extends StatelessWidget {
  final Order order;
  const OrderDetailScreen(this.order, {super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) {
          final o = order;
          return Scaffold(
            appBar: AppBar(title: Text(o.id)),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [Pill(o.isDonation ? 'Donation receipt' : o.statusLabel, color: stageColor(o)), const Spacer(), Text(dateFmt(o.date), style: const TextStyle(color: BvtColors.muted))]),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(children: [
                    for (final l in o.lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          if (maybeBook(l.bookId) != null) ...[BookCover(bookById(l.bookId), width: 40, showLang: false), const SizedBox(width: 10)],
                          Expanded(child: Text('${l.title}\n${l.format.label} × ${l.qty}', style: const TextStyle(fontSize: 13.5))),
                          Text(inr(l.unitPrice * l.qty), style: const TextStyle(fontWeight: FontWeight.w800)),
                        ]),
                      ),
                    const Divider(height: 22),
                    KeyVal('Subtotal', inr(o.subtotal)),
                    if (o.discount > 0) KeyVal('Discounts', '-${inr(o.discount)}', color: BvtColors.green),
                    if (!o.isDonation) KeyVal('Shipping', o.shipping == 0 ? 'FREE' : inr(o.shipping)),
                    KeyVal('Total', inr(o.total), bold: true),
                  ]),
                ),
              ),
              if (!o.isDonation) ...[
                const SizedBox(height: 12),
                Card(child: ListTile(leading: const Icon(Icons.location_on_outlined), title: Text(o.address.name), subtitle: Text(o.address.oneLine))),
                const SizedBox(height: 8),
                Card(child: ListTile(leading: const Icon(Icons.payment), title: Text(o.payment), subtitle: Text('${o.courier} · AWB ${o.awb}'))),
              ],
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (!o.isDonation) FilledButton.icon(onPressed: () => push(context, OrderTrackingScreen(o)), icon: const Icon(Icons.timeline), label: const Text('Track')),
                OutlinedButton.icon(onPressed: () => showInvoice(context, o), icon: const Icon(Icons.receipt_long), label: Text(o.isDonation ? '80G receipt' : 'Invoice')),
                if (!o.isDonation && o.stage >= 0 && o.stage < 3) OutlinedButton.icon(onPressed: () { app.cancelOrder(o); toast(context, 'Order cancelled · credit note issued', icon: Icons.cancel); }, icon: const Icon(Icons.cancel_outlined), label: const Text('Cancel order')),
                if (!o.isDonation && o.stage == 5) OutlinedButton.icon(onPressed: () { app.returnOrder(o); toast(context, 'Return initiated', icon: Icons.assignment_return); }, icon: const Icon(Icons.assignment_return_outlined), label: const Text('Return')),
              ]),
            ]),
          );
        },
      );
}

class OrderTrackingScreen extends StatelessWidget {
  final Order order;
  const OrderTrackingScreen(this.order, {super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) {
          final o = order;
          final events = app.timeline(o);
          return Scaffold(
            appBar: AppBar(title: Text('Track ${o.id}')),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Expanded(child: Text(o.statusLabel, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: stageColor(o)))), const Icon(Icons.local_shipping, color: BvtColors.deepSaffron)]),
                    const SizedBox(height: 4),
                    Text('${o.courier} · AWB ${o.awb}', style: const TextStyle(color: BvtColors.muted)),
                    if (o.stage >= 0 && o.stage < 5) Text('Expected by ${dateFmt(o.date.add(const Duration(days: 6)))}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (o.stage >= 0) ...[
                      const SizedBox(height: 14),
                      LinearProgressIndicator(value: (o.stage + 1) / 6, minHeight: 7, borderRadius: BorderRadius.circular(4), color: BvtColors.saffron, backgroundColor: BvtColors.sand),
                    ],
                    if (o.stage >= 3 && o.stage < 5)
                      Padding(padding: const EdgeInsets.only(top: 12), child: OutlinedButton.icon(onPressed: () => toast(context, 'Opening live courier map (demo)', icon: Icons.map), icon: const Icon(Icons.map_outlined), label: const Text('Live tracking link'))),
                  ]),
                ),
              ),
              const SectionHeader('Timeline'),
              for (var i = events.length - 1; i >= 0; i--) _EventTile(events[i], first: i == events.length - 1, last: i == 0),
              if (o.stage >= 0 && o.stage < 5) ...[
                const SizedBox(height: 6),
                for (var i = o.stage + 1; i < 6; i++) _PendingTile(Order.stages[i]),
              ],
              const SectionHeader('WhatsApp update log'),
              ...events.where((e) => e.whatsapp).toList().reversed.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.chat, size: 16, color: BvtColors.whatsapp),
                    const SizedBox(width: 8),
                    Expanded(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFDCF8C6), borderRadius: BorderRadius.circular(10)), child: Text('${e.title}: ${e.detail}\n${dateFmt(e.at)} · ${timeFmt(e.at)} · ✓✓ delivered', style: const TextStyle(fontSize: 12.5, height: 1.35)))),
                  ]))),
            ]),
          );
        },
      );
}

class _EventTile extends StatelessWidget {
  final OrderEvent e;
  final bool first, last;
  const _EventTile(this.e, {required this.first, required this.last});
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(width: 28, child: Column(children: [Container(width: 2, height: 6, color: last ? Colors.transparent : BvtColors.saffron), const CircleAvatar(radius: 8, backgroundColor: BvtColors.saffron, child: Icon(Icons.check, size: 11, color: Colors.white)), Expanded(child: Container(width: 2, color: first ? Colors.transparent : BvtColors.saffron))])),
          const SizedBox(width: 10),
          Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(e.detail, style: const TextStyle(fontSize: 12.5, color: BvtColors.muted)), Text('${dateFmt(e.at)} · ${timeFmt(e.at)}', style: const TextStyle(fontSize: 11.5, color: BvtColors.muted))]))),
        ]),
      );
}

class _PendingTile extends StatelessWidget {
  final String t;
  const _PendingTile(this.t);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(left: 6, bottom: 12), child: Row(children: [const CircleAvatar(radius: 5, backgroundColor: Color(0xFFE2CFAE)), const SizedBox(width: 18), Text(t, style: const TextStyle(color: BvtColors.muted))]));
}
