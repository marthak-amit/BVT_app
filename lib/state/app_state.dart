import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../l10n/strings.dart';

/// Home-page promo banner, editable from the admin banner manager.
class PromoBanner {
  String title, subtitle, cta, target;
  Color color;
  bool active, appExclusive;
  String schedule;
  PromoBanner(this.title, this.subtitle, this.cta, this.target, this.color,
      {this.active = true, this.appExclusive = false, this.schedule = 'Always on'});
}

class KbEntry {
  String q, a;
  KbEntry(this.q, this.a);
}

class WaMessage {
  final String text;
  final bool fromBot, human;
  final DateTime at;
  final List<String> books;
  WaMessage(this.text, {this.fromBot = true, this.human = false, this.books = const [], DateTime? at}) : at = at ?? DateTime.now();
}

class LineCalc {
  final CartLine line;
  final Book book;
  final int unit, gross, net;
  final double discountPct;
  final String? discountReason;
  LineCalc(this.line, this.book, this.unit, this.gross, this.net, this.discountPct, this.discountReason);
}

class CartSummary {
  final List<LineCalc> lines;
  final int gross, lineDiscount, promoDiscount, shipping, tax, total, itemCount;
  final bool memberApplied, bmmBelowMin;
  final String taxLabel;
  CartSummary(this.lines, this.gross, this.lineDiscount, this.promoDiscount, this.shipping, this.tax,
      this.total, this.itemCount, this.memberApplied, this.bmmBelowMin, this.taxLabel);
  int get afterLine => gross - lineDiscount;
}

const bmmThreshold = 5000;
const bmmMinOrder = 2000;
const bmmDiscount = 0.30;

class AppState extends ChangeNotifier {
  // ---- settings ----------------------------------------------------------
  String locale = 'en';
  bool dark = false, haptics = true, biometric = false, offlineMode = false;
  bool onboarded = false, appExclusive = true, cookieConsentShown = false;
  double textScale = 1;
  String preferredBookLang = 'en';

  String t(String key) => tr(locale, key);

  void update(VoidCallback f) {
    f();
    notifyListeners();
  }

  void haptic([bool heavy = false]) {
    if (!haptics) return;
    heavy ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
  }

  // ---- user ---------------------------------------------------------------
  bool loggedIn = false;
  String name = 'Guest', email = '', phone = '';
  bool waOptIn = true, emailOptIn = true, waPromo = true, waBackInStock = true;
  bool bmm = false, credit45 = false, emailVerified = true;
  int lifetimeSpend = 4200, points = 320;
  DateTime bmmExpiry = DateTime(2027, 10, 27);
  bool blocked = false;

  void login({String? n, String? e, String? p}) {
    loggedIn = true;
    name = n ?? 'Radhika Sharma';
    email = e ?? 'radhika@example.com';
    phone = p ?? '+91 98250 12345';
    if (orders.isEmpty) _seedOrders();
    if (subscriptions.isEmpty) _seedSubs();
    if (addresses.isEmpty) _seedAddresses();
    notify('Welcome back, ${name.split(' ').first}', 'Your cart and wishlist have been merged with your account.', 'App');
    notifyListeners();
  }

  void register(String n, String e, String p, {bool wa = true}) {
    loggedIn = true;
    name = n;
    email = e;
    phone = p;
    waOptIn = wa;
    emailVerified = false;
    lifetimeSpend = 0;
    points = 50;
    orders.clear();
    subscriptions.clear();
    addresses.clear();
    notify('Verify your email', 'We sent a verification link to $e.', 'Email');
    notify('Welcome to BVT Books!', 'Your 50 welcome points are ready.', 'WhatsApp');
    notifyListeners();
  }

  void logout() {
    loggedIn = false;
    name = 'Guest';
    email = '';
    bmm = false;
    credit45 = false;
    notifyListeners();
  }

  // ---- catalog state ------------------------------------------------------
  final Map<String, int> stockAdj = {}; // admin / order driven deltas
  int stockOf(Book b) => (b.stock + (stockAdj[b.id] ?? 0)).clamp(0, 100000);
  bool inStock(Book b) => stockOf(b) > 0;

  final Set<String> wishlist = {};
  final Set<String> stockAlerts = {};
  final List<String> recent = [];
  final List<String> searchHistory = ['krishna', 'ramayana', 'गीता'];
  final List<(String, DateTime)> zeroResults = [
    ('srimad bhagavatam 12 canto', DateTime(2026, 10, 24)),
    ('kannada kids stories', DateTime(2026, 10, 25)),
  ];
  final Set<String> pinned = {'beginners-guide-en'};

  void toggleWish(String id) {
    wishlist.contains(id) ? wishlist.remove(id) : wishlist.add(id);
    haptic();
    notifyListeners();
  }

  void viewed(String id) {
    recent.remove(id);
    recent.insert(0, id);
    if (recent.length > 50) recent.removeLast();
    // no notify: called during build of detail page
  }

  void logSearch(String q, int results) {
    final s = q.trim();
    if (s.isEmpty) return;
    searchHistory.remove(s);
    searchHistory.insert(0, s);
    if (searchHistory.length > 8) searchHistory.removeLast();
    if (results == 0) zeroResults.insert(0, (s, DateTime.now()));
  }

  // ---- cart ---------------------------------------------------------------
  final List<CartLine> cart = [];
  String? promo;
  bool useCredit = false;

  int get cartCount => cart.fold(0, (a, b) => a + b.qty);

  void addToCart(Book b, BookFormat f, {int qty = 1}) {
    final i = cart.indexWhere((l) => l.bookId == b.id && l.format == f);
    if (i >= 0) {
      cart[i].qty += qty;
    } else {
      cart.add(CartLine(b.id, f, qty));
    }
    haptic();
    notifyListeners();
  }

  void setQty(CartLine l, int q) {
    if (q <= 0) {
      cart.remove(l);
    } else {
      l.qty = q;
    }
    notifyListeners();
  }

  void removeLine(CartLine l) {
    cart.remove(l);
    notifyListeners();
  }

  String? applyPromo(String code) {
    final c = code.trim().toUpperCase();
    if (!promoCodes.containsKey(c)) return 'Invalid or expired code';
    promo = c;
    notifyListeners();
    return null;
  }

  void clearPromo() {
    promo = null;
    notifyListeners();
  }

  double bulkPct(int qty) => qty >= 100 ? 0.25 : qty >= 50 ? 0.20 : qty >= 10 ? 0.10 : 0;

  CartSummary summary({ShippingOption? ship, Address? addr}) {
    final lines = <LineCalc>[];
    var gross = 0, disc = 0, count = 0;
    final rawSubtotal = cart.fold<int>(0, (a, l) => a + (bookById(l.bookId).prices[l.format] ?? 0) * l.qty);
    final memberEligible = bmm && rawSubtotal >= bmmMinOrder;
    for (final l in cart) {
      final b = bookById(l.bookId);
      final unit = b.prices[l.format] ?? 0;
      final g = unit * l.qty;
      final bulk = bulkPct(l.qty);
      final member = memberEligible && !b.isPoster ? bmmDiscount : 0.0;
      final pct = member > bulk ? member : bulk;
      final net = (g * (1 - pct)).round();
      lines.add(LineCalc(l, b, unit, g, net, pct, pct == 0 ? null : (member > bulk ? 'BMM wholesale' : 'Bulk price')));
      gross += g;
      disc += g - net;
      count += l.qty;
    }
    final after = gross - disc;
    final promoPct = promo != null ? promoCodes[promo]!.$2 : 0.0;
    final promoDisc = (after * promoPct).round();
    final shipFee = cart.isEmpty ? 0 : (ship?.fee ?? 0);
    // Prices are GST-inclusive; show the embedded tax split.
    var tax = 0;
    for (final lc in lines) {
      final rate = lc.book.isPoster ? 0.12 : 0.0;
      tax += (lc.net * rate / (1 + rate)).round();
    }
    final intl = addr != null && !addr.isIndia;
    final label = intl
        ? 'Export — no GST'
        : (addr == null || addr.state == 'Gujarat' ? 'CGST + SGST (incl.)' : 'IGST (incl.)');
    final total = after - promoDisc + shipFee;
    return CartSummary(lines, gross, disc, promoDisc, shipFee, intl ? 0 : tax, total, count,
        memberEligible, bmm && rawSubtotal < bmmMinOrder && cart.isNotEmpty, label);
  }

  List<ShippingOption> shippingOptions(Address? a, int net) {
    if (a != null && !a.isIndia) {
      return const [
        ShippingOption('intl-eco', 'International Economy', 'Shiprocket X', '10–14 business days', 1450),
        ShippingOption('intl-exp', 'International Express', 'Delhivery Global', '5–7 business days', 2400),
      ];
    }
    return [
      ShippingOption('std', 'Standard Delivery', 'Delhivery', '5–7 business days', net >= 999 ? 0 : 60),
      const ShippingOption('exp', 'Express Delivery', 'Shiprocket Air', '2–3 business days', 140),
    ];
  }

  String estimateEta(String pin) {
    if (pin.length != 6 || int.tryParse(pin) == null) return '';
    final d = pin[0];
    if (d == '3') return 'Delivery in 2–3 days (Gujarat region)';
    if (['1', '2', '4', '5', '6'].contains(d)) return 'Delivery in 4–6 days';
    return 'Delivery in 5–8 days';
  }

  // ---- addresses ----------------------------------------------------------
  final List<Address> addresses = [];
  void addAddress(Address a) {
    addresses.add(a);
    notifyListeners();
  }

  void removeAddress(Address a) {
    addresses.remove(a);
    notifyListeners();
  }

  void _seedAddresses() {
    addresses.addAll([
      Address(id: 'ad1', name: 'Radhika Sharma', phone: '+91 98250 12345', line1: '12, Bhakti Nagar, Station Road', city: 'Bharuch', state: 'Gujarat', pin: '392001'),
      Address(id: 'ad2', name: 'Radhika Sharma (Office)', phone: '+91 98250 12345', line1: '4th Floor, Lotus Tower, Andheri East', city: 'Mumbai', state: 'Maharashtra', pin: '400069', gstin: '27ABCDE1234F1Z5'),
    ]);
  }

  // ---- orders -------------------------------------------------------------
  final List<Order> orders = [];
  final List<AppNotification> notifications = [];
  final List<(String, String, DateTime)> waLog = []; // orderId, text, at

  void notify(String title, String body, String channel) {
    notifications.insert(0, AppNotification(title, body, channel, DateTime.now()));
  }

  int get unreadCount => notifications.where((n) => !n.read).length;

  void _seedOrders() {
    final a = addresses.isNotEmpty ? addresses.first : Address(id: 'ad1', name: 'Radhika Sharma', phone: '+91 98250 12345', line1: '12, Bhakti Nagar, Station Road', city: 'Bharuch', state: 'Gujarat', pin: '392001');
    Order mk(String id, int daysAgo, List<(String, BookFormat, int)> ls, int stage, String pay, {String courier = 'Delhivery'}) {
      final lines = ls.map((e) {
        final b = bookById(e.$1);
        return OrderLine(b.id, b.title, e.$2, e.$3, b.prices[e.$2] ?? 0);
      }).toList();
      final sub = lines.fold<int>(0, (s, l) => s + l.unitPrice * l.qty);
      final ship = sub >= 999 ? 0 : 60;
      return Order(
        id: id,
        date: DateTime.now().subtract(Duration(days: daysAgo)),
        lines: lines,
        address: a,
        subtotal: sub,
        discount: 0,
        shipping: ship,
        tax: 0,
        total: sub + ship,
        payment: pay,
        courier: courier,
        awb: 'DLV${id.hashCode.abs() % 90000000 + 10000000}',
        stage: stage,
      );
    }

    orders.addAll([
      mk('BVT-100482', 2, [('beginners-guide-en', BookFormat.paperback, 2), ('poster-radha-krishna', BookFormat.poster, 1)], 3, 'UPI · Razorpay'),
      mk('BVT-100377', 11, [('ramayana-en', BookFormat.hardcover, 1)], 5, 'Credit card · Razorpay'),
      mk('BVT-100201', 34, [('sri-caitanya-mahaprabhu-en', BookFormat.paperback, 1), ('lekha-mala-en', BookFormat.paperback, 1)], 5, 'Net banking · Razorpay'),
    ]);
    notify('Order Dispatched', 'BVT-100482 is on its way via Delhivery. Track: bvks.in/t/482', 'WhatsApp');
    notify('Back in stock', 'Ramayana (Hindi) is available again.', 'Push');
    notify('App-exclusive early access', 'Get early access to The Mood and Mission of Śrīla Prabhupāda.', 'Push');
  }

  List<OrderEvent> timeline(Order o) {
    final base = o.date;
    final ev = <OrderEvent>[];
    final msgs = [
      ('Order Confirmed', 'We have received your order ${o.id}.'),
      ('Payment Received', 'Payment of ₹${o.total} via ${o.payment} is confirmed.'),
      ('Order Packed', 'Your books have been packed at the Bharuch warehouse.'),
      ('Dispatched', '${o.courier} AWB ${o.awb} — live tracking link shared.'),
      ('Out for Delivery', 'Your parcel is out for delivery today.'),
      ('Delivered', 'Delivered. Hare Kṛṣṇa — we hope you enjoy reading!'),
    ];
    final upto = o.stage >= 0 ? o.stage : 1;
    for (var i = 0; i <= upto && i < msgs.length; i++) {
      ev.add(OrderEvent(msgs[i].$1, msgs[i].$2, base.add(Duration(hours: i * 14 + 1)), whatsapp: true));
    }
    if (o.stage == -1) ev.add(OrderEvent('Cancelled', 'Order cancelled. Credit note issued in Zoho Books; refund in 3–5 days.', base.add(const Duration(hours: 30)), whatsapp: true));
    if (o.stage == -2) ev.add(OrderEvent('Return Initiated', 'Return pickup scheduled. Refund processed after quality check.', base.add(const Duration(days: 7)), whatsapp: true));
    return ev;
  }

  int _orderSeq = 100500;
  Order placeOrder({
    required Address address,
    required ShippingOption ship,
    required String payment,
    required CartSummary s,
    String? note,
    int? paidNow,
  }) {
    final id = 'BVT-${++_orderSeq}';
    final lines = s.lines.map((lc) => OrderLine(lc.book.id, lc.book.title, lc.line.format, lc.line.qty, (lc.net / lc.line.qty).round())).toList();
    final o = Order(
      id: id,
      date: DateTime.now(),
      lines: lines,
      address: address,
      subtotal: s.gross,
      discount: s.lineDiscount + s.promoDiscount,
      shipping: s.shipping,
      tax: s.tax,
      total: s.total,
      payment: paidNow != null ? '$payment (partial ₹$paidNow paid)' : payment,
      courier: ship.courier,
      awb: 'AWB${DateTime.now().millisecondsSinceEpoch % 100000000}',
      stage: 1,
    );
    orders.insert(0, o);
    for (final lc in s.lines) {
      stockAdj[lc.book.id] = (stockAdj[lc.book.id] ?? 0) - lc.line.qty;
    }
    lifetimeSpend += s.total;
    points += (s.total / 10).round();
    cart.clear();
    promo = null;
    useCredit = false;
    waLog.insert(0, (id, 'Order Confirmed ✅ ${o.id} — ₹${o.total}. Invoice PDF attached.', DateTime.now()));
    notify('Order Confirmed', '$id placed successfully. Invoice sent by ${waOptIn ? 'WhatsApp and ' : ''}email.', waOptIn ? 'WhatsApp' : 'Email');
    zohoEvents.insert(0, ZohoEvent('Sales Order', id, 'Created in Zoho Inventory', true, DateTime.now()));
    zohoEvents.insert(0, ZohoEvent('Invoice', id, 'Zoho Books invoice generated (GST)', true, DateTime.now()));
    if (!bmm && lifetimeSpend >= bmmThreshold && loggedIn) {
      bmm = true;
      bmmExpiry = DateTime.now().add(const Duration(days: 365));
      notify('You are now a BMM member!', 'Wholesale pricing unlocked on your next order of ₹$bmmMinOrder+.', 'WhatsApp');
    }
    haptic(true);
    notifyListeners();
    return o;
  }

  void cancelOrder(Order o) {
    o.stage = -1;
    for (final l in o.lines) {
      stockAdj[l.bookId] = (stockAdj[l.bookId] ?? 0) + l.qty;
    }
    zohoEvents.insert(0, ZohoEvent('Credit Note', o.id, 'Credit note created in Zoho Books', true, DateTime.now()));
    notify('Order cancelled', '${o.id} cancelled. Refund initiated.', 'WhatsApp');
    notifyListeners();
  }

  void returnOrder(Order o) {
    o.stage = -2;
    notify('Return initiated', 'Pickup for ${o.id} will be scheduled within 24 hours.', 'WhatsApp');
    notifyListeners();
  }

  void reorder(Order o) {
    for (final l in o.lines) {
      final b = maybeBook(l.bookId);
      if (b != null && !l.format.name.contains('ebook')) addToCart(b, l.format, qty: l.qty);
    }
  }

  Order recordDonation(int amount, String donor, String method, String cause) {
    final id = 'DON-${++_orderSeq}';
    final o = Order(
      id: id,
      date: DateTime.now(),
      lines: [OrderLine('donation', 'Donation · $cause', BookFormat.ebook, 1, amount)],
      address: addresses.isNotEmpty ? addresses.first : Address(id: 'x', name: donor, phone: '', line1: '-', city: '-', state: '-', pin: '000000'),
      subtotal: amount,
      discount: 0,
      shipping: 0,
      tax: 0,
      total: amount,
      payment: method,
      courier: '-',
      awb: '-',
      stage: 5,
      isDonation: true,
    );
    orders.insert(0, o);
    points += (amount / 20).round();
    notify('Thank you for your donation', '₹$amount received. 80G receipt sent to your email.', 'WhatsApp');
    notifyListeners();
    return o;
  }

  // ---- subscriptions -------------------------------------------------------
  final List<Subscription> subscriptions = [];
  final Map<String, double> progress = {'ramayana-en': 0.34, 'beginners-guide-en': 0.72};
  final Map<String, Set<String>> bookmarks = {};
  final Map<String, Set<String>> highlights = {};
  final Set<String> downloaded = {};
  int trialOverride = 0; // admin controlled (0 = per-plan default)

  void _seedSubs() {
    subscriptions.add(Subscription(
      id: 'SUB-3001',
      planId: 'lang',
      title: 'Hindi All-Access',
      started: DateTime.now().subtract(const Duration(days: 41)),
      renews: DateTime.now().add(const Duration(days: 3)),
      status: 'active',
    ));
    subscriptions.add(Subscription(
      id: 'SUB-3002',
      planId: 'book',
      title: 'Rāmāyaṇa (English)',
      started: DateTime.now().subtract(const Duration(days: 10)),
      renews: DateTime.now().add(const Duration(days: 20)),
      status: 'active',
    ));
  }

  Subscription subscribe(Plan p,
      {required bool yearly, String? bookId, String? langCode, bool gift = false, String? giftTo, bool trial = true}) {
    final title = switch (p.kind) {
      'book' => bookById(bookId ?? 'ramayana-en').title,
      'language' => '${langOf(langCode ?? 'en').name} All-Access',
      _ => 'Global All-Access',
    };
    final days = trialOverride > 0 ? trialOverride : p.trialDays;
    final s = Subscription(
      id: 'SUB-${3100 + subscriptions.length}',
      planId: p.id,
      title: (bookId != null && p.kind == 'book') ? '$title (${langOf(bookById(bookId).language).name})' : title,
      started: DateTime.now(),
      renews: DateTime.now().add(Duration(days: trial && !gift ? days : (yearly ? 365 : 30))),
      status: trial && !gift ? 'trial' : 'active',
      yearly: yearly,
      gift: gift,
      giftTo: giftTo,
    );
    if (gift) {
      notify('Gift sent 🎁', '${p.name} gifted to $giftTo.', 'WhatsApp');
    } else {
      subscriptions.insert(0, s);
      notify('Subscription ${trial ? 'trial started' : 'active'}', '${s.title} — enjoy reading!', 'WhatsApp');
      zohoEvents.insert(0, ZohoEvent('Recurring Invoice', s.id, 'Subscription invoice created in Zoho Books', true, DateTime.now()));
    }
    haptic(true);
    notifyListeners();
    return s;
  }

  bool _live(Subscription s) => ['trial', 'active', 'grace'].contains(s.status);

  bool hasAccess(Book b) {
    if (!loggedIn || !b.subEligible) return false;
    for (final s in subscriptions.where(_live)) {
      if (s.planId == 'global') return true;
      if (s.planId == 'lang' && s.title.startsWith(langOf(b.language).name)) return true;
      if (s.planId == 'book' && s.title.startsWith(b.title)) return true;
    }
    return false;
  }

  List<Book> get library => allBooks.where(hasAccess).toList();

  void setSubStatus(Subscription s, String st) {
    s.status = st;
    notifyListeners();
  }

  void changePlan(Subscription s, bool toYearly) {
    s.yearly = toYearly;
    s.renews = DateTime.now().add(Duration(days: toYearly ? 365 : 30));
    notifyListeners();
  }

  // ---- reader helpers -------------------------------------------------------
  bool toggleMark(Map<String, Set<String>> m, String book, String key) {
    final s = m.putIfAbsent(book, () => {});
    final added = s.add(key);
    if (!added) s.remove(key);
    notifyListeners();
    return added;
  }

  // ---- admin-managed content (drives storefront) ----------------------------
  final List<PromoBanner> banners = [
    PromoBanner('Read anywhere with BVT Reader', 'Language All-Access from ₹149/mo · 7-day free trial', 'Explore plans', 'plans', const Color(0xFFB5541C)),
    PromoBanner('Śrī Caitanya Mahāprabhu', 'The life and teachings of Śrī Caitanya Mahāprabhu — English & Gujarati', 'Shop now', 'book:sri-caitanya-mahaprabhu-en', const Color(0xFF7A2E0E)),
    PromoBanner('The Mood and Mission of Śrīla Prabhupāda — App early access', 'New release — get early access in the app', 'Get early access', 'book:mood-and-mission-en', const Color(0xFF3B6EA5), appExclusive: true),
    PromoBanner('Bulk orders made easy', 'Quantity pricing for temples, schools & book tables', 'Request a quote', 'bulk', const Color(0xFF2E7D32)),
  ];
  late final List<Article> blog = List.of(articles);
  final List<(String, String, String)> cmsPages = [
    ('About BVT', 'Static Info Page', 'Published'),
    ('Shipping & Returns', 'FAQ Page', 'Published'),
    ('Janmāṣṭamī Landing', 'Landing Page', 'Draft'),
  ];
  final List<String> navItems = ['Books', 'Posters', 'eBooks', 'Subscriptions', 'Donate', 'Articles'];
  final List<KbEntry> kb = [
    KbEntry('return policy', 'You can return unused books within 7 days of delivery. Go to Account → Orders → Return, or reply “return” here.'),
    KbEntry('shipping', 'We ship worldwide. Standard delivery in India takes 5–7 business days; orders above ₹999 ship free.'),
    KbEntry('cod', 'Cash on Delivery is available in India for physical books up to ₹5,000.'),
    KbEntry('subscription', 'Reading subscriptions start from ₹49/month with a free trial. See plans in the app: Library → Plans.'),
    KbEntry('refund', 'Refunds are processed to the original payment method in 3–5 business days after approval.'),
  ];
  final List<WaMessage> chat = [];

  // ---- zoho -------------------------------------------------------------------
  final List<ZohoEvent> zohoEvents = [
    ZohoEvent('Sales Order', 'BVT-100482', 'Created in Zoho Inventory', true, DateTime.now().subtract(const Duration(hours: 5))),
    ZohoEvent('Payment', 'BVT-100482', 'Payment recorded against invoice (Razorpay)', true, DateTime.now().subtract(const Duration(hours: 5))),
    ZohoEvent('Stock', 'ramayana-en', 'Stock adjusted in Zoho — synced to website', true, DateTime.now().subtract(const Duration(hours: 9))),
    ZohoEvent('Contact', 'radhika@example.com', 'CRM contact update timed out (429 rate limit)', false, DateTime.now().subtract(const Duration(hours: 2)), retries: 2),
    ZohoEvent('Credit Note', 'BVT-100199', 'Credit note for refund — pending retry', false, DateTime.now().subtract(const Duration(minutes: 40)), retries: 1),
  ];
}

class ZohoEvent {
  final String entity, ref, message;
  bool ok;
  final DateTime at;
  int retries;
  ZohoEvent(this.entity, this.ref, this.message, this.ok, this.at, {this.retries = 0});
}

final app = AppState();

String inr(num v) {
  final n = v.round();
  final s = n.abs().toString();
  String out;
  if (s.length <= 3) {
    out = s;
  } else {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    out = '${parts.join(',')},$last3';
  }
  return '${n < 0 ? '-' : ''}₹$out';
}
