import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'bulk.dart';
import 'checkout.dart';
import 'home.dart';

class CartTab extends StatefulWidget {
  const CartTab({super.key});
  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  final _promo = TextEditingController();
  final _pin = TextEditingController();
  String eta = '';

  @override
  void dispose() {
    _promo.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        if (app.cart.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(app.t('cart'))),
            body: EmptyState(Icons.shopping_cart_outlined, 'Your cart is empty', 'Browse our books and posters — or pick up where you left off.', action: 'Start shopping', onAction: () => tabIndex.value = 1),
          );
        }
        final ship = app.shippingOptions(null, 0).first;
        final s = app.summary(ship: ship);
        final shipFee = s.afterLine - s.promoDiscount >= 999 ? 0 : 60;
        final sFinal = app.summary(ship: ShippingOption(ship.id, ship.name, ship.courier, ship.eta, shipFee));
        return Scaffold(
          appBar: AppBar(
            title: Text('${app.t('cart')} (${app.cartCount})'),
            actions: [TextButton(onPressed: () => app.update(app.cart.clear), child: const Text('Clear'))],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEBD9BC)))),
              child: Row(children: [
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(app.t('total'), style: const TextStyle(fontSize: 12, color: BvtColors.muted)),
                  Text(inr(sFinal.total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 21, color: BvtColors.maroon)),
                ]),
                const SizedBox(width: 20),
                Expanded(child: FilledButton(onPressed: () => push(context, const CheckoutScreen()), child: Text('${app.t('checkout')} →'))),
              ]),
            ),
          ),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
            if (shipFee == 0)
              _banner(Icons.local_shipping, 'You get FREE standard delivery on this order!', BvtColors.green)
            else
              _banner(Icons.local_shipping_outlined, 'Add ${inr(999 - (s.afterLine - s.promoDiscount))} more for free delivery', BvtColors.deepSaffron),
            if (app.loggedIn && s.memberApplied) _banner(Icons.workspace_premium, 'BMM wholesale pricing applied (${(bmmDiscount * 100).round()}% off books)', BvtColors.maroon),
            if (app.loggedIn && s.bmmBelowMin) _banner(Icons.info_outline, 'BMM minimum order is ${inr(bmmMinOrder)} to unlock wholesale pricing', const Color(0xFFE65100)),
            if (!app.loggedIn) _banner(Icons.login, 'Sign in to save your cart across devices (guest checkout also available)', BvtColors.muted),
            for (final lc in s.lines) _LineCard(lc),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Promo code', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (app.promo != null)
                    Row(children: [
                      const Icon(Icons.sell, color: BvtColors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${app.promo} · ${promoCodes[app.promo]!.$1}', style: const TextStyle(color: BvtColors.green, fontWeight: FontWeight.w700))),
                      TextButton(onPressed: app.clearPromo, child: const Text('Remove')),
                    ])
                  else
                    Row(children: [
                      Expanded(child: TextField(controller: _promo, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(hintText: 'Enter code (try BVT10)', isDense: true))),
                      const SizedBox(width: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(80, 46)),
                        onPressed: () {
                          final err = app.applyPromo(_promo.text);
                          toast(context, err ?? 'Promo applied!', icon: err == null ? Icons.check_circle : Icons.error_outline);
                        },
                        child: const Text('Apply'),
                      ),
                    ]),
                  const Divider(height: 28),
                  const Text('Shipping estimate', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: _pin, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(hintText: 'PIN code', counterText: '', isDense: true, prefixIcon: Icon(Icons.location_on_outlined)), onChanged: (v) => setState(() => eta = app.estimateEta(v)))),
                  ]),
                  if (eta.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('🚚 $eta · Standard ${shipFee == 0 ? 'FREE' : inr(shipFee)} · Express ₹140', style: const TextStyle(color: BvtColors.green, fontWeight: FontWeight.w600, fontSize: 13))),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  KeyVal('Subtotal (${sFinal.itemCount} items)', inr(sFinal.gross)),
                  if (sFinal.lineDiscount > 0) KeyVal('Bulk / member savings', '-${inr(sFinal.lineDiscount)}', color: BvtColors.green),
                  if (sFinal.promoDiscount > 0) KeyVal('Promo ${app.promo}', '-${inr(sFinal.promoDiscount)}', color: BvtColors.green),
                  KeyVal('Shipping (est.)', sFinal.shipping == 0 ? 'FREE' : inr(sFinal.shipping)),
                  if (sFinal.tax > 0) KeyVal('GST included', inr(sFinal.tax)),
                  const Divider(height: 22),
                  KeyVal(app.t('total'), inr(sFinal.total), bold: true),
                  if (app.loggedIn) Padding(padding: const EdgeInsets.only(top: 6), child: Align(alignment: Alignment.centerLeft, child: Text('You will earn ${(sFinal.total / 10).round()} loyalty points', style: const TextStyle(fontSize: 12, color: BvtColors.deepSaffron, fontWeight: FontWeight.w600)))),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: () => push(context, const BulkOrderScreen()), icon: const Icon(Icons.inventory_2_outlined), label: const Text('Ordering 50+ copies? Request a bulk quote')),
          ]),
        );
      },
    );
  }

  Widget _banner(IconData i, String t, Color c) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [Icon(i, color: c, size: 20), const SizedBox(width: 10), Expanded(child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 13)))]),
      );
}

class _LineCard extends StatelessWidget {
  final LineCalc lc;
  const _LineCard(this.lc);
  @override
  Widget build(BuildContext context) {
    final b = lc.book;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('${b.id}-${lc.line.format}'),
        direction: DismissDirection.endToStart,
        background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(color: BvtColors.red, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.delete, color: Colors.white)),
        onDismissed: (_) {
          app.removeLine(lc.line);
          toast(context, 'Removed from cart', action: 'UNDO', onAction: () => app.addToCart(b, lc.line.format, qty: lc.line.qty));
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              InkWell(onTap: () => openBook(context, b), child: BookCover(b, width: 62, showLang: false)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('${lc.line.format.label} · ${langOf(b.language).name}', style: const TextStyle(fontSize: 12, color: BvtColors.muted)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(inr(lc.net), style: const TextStyle(fontWeight: FontWeight.w900, color: BvtColors.maroon, fontSize: 16)),
                  if (lc.discountPct > 0) ...[const SizedBox(width: 6), Text(inr(lc.gross), style: const TextStyle(decoration: TextDecoration.lineThrough, color: BvtColors.muted, fontSize: 12))],
                ]),
                if (lc.discountReason != null) Padding(padding: const EdgeInsets.only(top: 3), child: Pill('${lc.discountReason} −${(lc.discountPct * 100).round()}%', color: BvtColors.green, icon: Icons.local_offer)),
                const SizedBox(height: 6),
                Row(children: [
                  QtyStepper(lc.line.qty, (v) => app.setQty(lc.line, v)),
                  const Spacer(),
                  TextButton(onPressed: () { app.wishlist.add(b.id); app.removeLine(lc.line); toast(context, 'Moved to wishlist', icon: Icons.favorite); }, child: const Text('Save for later', style: TextStyle(fontSize: 12))),
                ]),
              ])),
            ]),
          ),
        ),
      ),
    );
  }
}
