import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bvt_app/main.dart';
import 'package:bvt_app/state/app_state.dart';
import 'package:bvt_app/data/catalog.dart';
import 'package:bvt_app/data/search.dart';

void main() {
  test('search handles transliteration and typos', () {
    expect(searchBooks('krishna').isNotEmpty, true);
    expect(searchBooks('Krsna').length, searchBooks('krishna').length);
    expect(searchBooks('ramyana').isNotEmpty, true);
    expect(searchBooks('कृष्ण').isNotEmpty, true);
    expect(searchBooks('zzzzqq').isEmpty, true);
    expect(allBooks.length > 80, true);
  });

  testWidgets('onboarding → home → product → cart → checkout → order', (t) async {
    t.view.physicalSize = const Size(420 * 2, 900 * 2);
    t.view.devicePixelRatio = 2;
    await t.pumpWidget(const BvtApp());
    await t.pump(const Duration(seconds: 2));
    await t.pump(const Duration(seconds: 1));
    await t.drag(find.byType(ListView).first, const Offset(0, -700));
    await t.pump();
    await t.tap(find.text('Start exploring'));
    await t.pump(const Duration(seconds: 2));
    expect(find.text('BVT Books'), findsWidgets);

    app.login();
    final b = bookById('ramayana-en');
    app.addToCart(b, b.purchasable.first, qty: 2);
    expect(app.cartCount, 2);
    final s = app.summary(ship: app.shippingOptions(app.addresses.first, 700).first, addr: app.addresses.first);
    final o = app.placeOrder(address: app.addresses.first, ship: app.shippingOptions(app.addresses.first, 700).first, payment: 'UPI', s: s);
    expect(app.cart.isEmpty, true);
    expect(o.total, s.total);

    final p = planById('lang');
    final sub = app.subscribe(p, yearly: false, langCode: 'hi');
    expect(sub.status, 'trial');
    expect(app.hasAccess(bookById('ramayana-hi')), true);
    await t.pump(const Duration(seconds: 1));
  });
}
