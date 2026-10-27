import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';

class AdminModule {
  final String key, label;
  final IconData icon;
  const AdminModule(this.key, this.label, this.icon);
}

const adminModules = <AdminModule>[
  AdminModule('dashboard', 'Dashboard', Icons.dashboard_outlined),
  AdminModule('products', 'Products', Icons.menu_book_outlined),
  AdminModule('inventory', 'Inventory', Icons.inventory_2_outlined),
  AdminModule('orders', 'Orders', Icons.receipt_long_outlined),
  AdminModule('subscriptions', 'Subscriptions', Icons.workspace_premium_outlined),
  AdminModule('customers', 'Customers', Icons.people_outline),
  AdminModule('shipping', 'Shipping', Icons.local_shipping_outlined),
  AdminModule('whatsapp', 'WhatsApp campaigns', Icons.chat_outlined),
  AdminModule('chatbot', 'Chatbot knowledge base', Icons.smart_toy_outlined),
  AdminModule('cms', 'CMS page builder', Icons.web_outlined),
  AdminModule('banners', 'Banners', Icons.view_carousel_outlined),
  AdminModule('navigation', 'Navigation', Icons.menu_open),
  AdminModule('search', 'Search & merchandising', Icons.manage_search),
  AdminModule('reports', 'Reports & analytics', Icons.insights_outlined),
  AdminModule('finance', 'Finance', Icons.account_balance_outlined),
  AdminModule('zoho', 'Zoho sync', Icons.sync_alt),
  AdminModule('audit', 'Audit log', Icons.fact_check_outlined),
  AdminModule('roles', 'Roles & security', Icons.admin_panel_settings_outlined),
  AdminModule('settings', 'Settings', Icons.settings_outlined),
];

/// 0 = no access, 1 = read, 2 = read/write
class AdminRole {
  String name;
  final Map<String, int> perms;
  final bool system;
  AdminRole(this.name, this.perms, {this.system = true});
}

Map<String, int> _p(Map<String, int> m, {int base = 0}) => {for (final mod in adminModules) mod.key: m[mod.key] ?? base};

class AuditEntry {
  final DateTime at;
  final String user, role, module, action, before, after;
  const AuditEntry(this.at, this.user, this.role, this.module, this.action, this.before, this.after);
}

class AdminUser {
  String name, email, role;
  bool twoFa, active;
  String last;
  AdminUser(this.name, this.email, this.role, {this.twoFa = true, this.active = true, this.last = 'Today'});
}

class Campaign {
  String name, template, segment, status;
  DateTime when;
  int sent, delivered, read;
  Campaign(this.name, this.template, this.segment, this.status, this.when, this.sent, this.delivered, this.read);
}

class WaTemplate {
  String name, category, status, body;
  WaTemplate(this.name, this.category, this.status, this.body);
}

class Customer {
  final String id, name, email, phone, city;
  final int orders, spend;
  bool bmm, blocked;
  Customer(this.id, this.name, this.email, this.phone, this.city, this.orders, this.spend, {this.bmm = false, this.blocked = false});
}

class Courier {
  String name, key;
  bool enabled;
  String status;
  int limit;
  Courier(this.name, this.key, this.enabled, this.status, this.limit);
}

class AdminSub {
  final String id, customer, plan;
  String status, tier;
  DateTime renews;
  AdminSub(this.id, this.customer, this.plan, this.status, this.tier, this.renews);
}

class AdminState extends ChangeNotifier {
  void changed() => notifyListeners();

  // ---- session / RBAC -----------------------------------------------------
  bool authed = false;
  String userName = 'Avantika Parwe';
  late AdminRole role = roles.first;
  bool twoFaEnforced = true, ipWhitelist = true;
  final List<String> ips = ['103.21.58.0/24 (Bharuch office)', '49.36.12.18 (Support desk)'];

  late final List<AdminRole> roles = [
    AdminRole('Super Admin', _p({}, base: 2)),
    AdminRole('Catalog Manager', _p({'dashboard': 1, 'products': 2, 'inventory': 2, 'banners': 1, 'search': 2, 'reports': 1})),
    AdminRole('Order Manager', _p({'dashboard': 1, 'orders': 2, 'customers': 1, 'shipping': 1, 'subscriptions': 1, 'inventory': 1})),
    AdminRole('Content Editor', _p({'dashboard': 1, 'cms': 2, 'banners': 2, 'navigation': 2, 'chatbot': 2, 'search': 1})),
    AdminRole('Finance Viewer', _p({'dashboard': 1, 'finance': 1, 'reports': 1, 'orders': 1, 'subscriptions': 1, 'zoho': 1, 'audit': 1})),
    AdminRole('Support Agent', _p({'dashboard': 1, 'orders': 1, 'customers': 2, 'subscriptions': 1, 'whatsapp': 1, 'chatbot': 1})),
    AdminRole('Shipping Manager', _p({'dashboard': 1, 'orders': 1, 'shipping': 2, 'inventory': 1})),
  ];

  int level(String m) => role.perms[m] ?? 0;
  bool canRead(String m) => level(m) >= 1;
  bool canWrite(String m) => level(m) >= 2;

  // ---- audit ------------------------------------------------------------------
  final List<AuditEntry> audit = [
    AuditEntry(DateTime.now().subtract(const Duration(hours: 3)), 'Rohan K.', 'Catalog Manager', 'Products', 'Updated price · Lekha-mālā (EN)', '₹190', '₹200'),
    AuditEntry(DateTime.now().subtract(const Duration(hours: 6)), 'Meera S.', 'Support Agent', 'Customers', 'Blocked customer', 'active', 'blocked'),
    AuditEntry(DateTime.now().subtract(const Duration(days: 1)), 'Avantika Parwe', 'Super Admin', 'Roles', 'Created role “Temple Coordinator”', '—', '3 permissions'),
    AuditEntry(DateTime.now().subtract(const Duration(days: 1, hours: 4)), 'Priya D.', 'Content Editor', 'Banners', 'Scheduled banner', 'draft', 'scheduled 1 Nov'),
  ];

  /// Returns false (and tells the user) when the current role lacks write access.
  bool act(BuildContext c, String module, String action, {String before = '—', String after = '—'}) {
    if (!canWrite(module)) {
      ScaffoldMessenger.of(c)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Access denied — ${role.name} has read-only access to ${moduleLabel(module)}. Enforced server-side.'), backgroundColor: BvtColors.red));
      return false;
    }
    audit.insert(0, AuditEntry(DateTime.now(), userName, role.name, moduleLabel(module), action, before, after));
    notifyListeners();
    return true;
  }

  String moduleLabel(String k) => adminModules.firstWhere((m) => m.key == k).label;

  // ---- sample data ---------------------------------------------------------------
  late final List<Customer> customers = [
    Customer('C-1001', 'Radhika Sharma', 'radhika@example.com', '+91 98250 12345', 'Bharuch', 8, 4200),
    Customer('C-1002', 'Kishore Prabhu', 'kishore@temple.org', '+91 98980 22110', 'Surat', 31, 48200, bmm: true),
    Customer('C-1003', 'Anita Rao', 'anita.rao@example.com', '+91 99001 88221', 'Bengaluru', 5, 2100),
    Customer('C-1004', 'Govind Patel', 'govind@example.com', '+91 97120 55410', 'Ahmedabad', 12, 9650, bmm: true),
    Customer('C-1005', 'Michael Adams', 'm.adams@example.com', '+1 415 555 0134', 'San Francisco', 3, 12900),
    Customer('C-1006', 'Sofia Petrova', 'sofia@example.ru', '+7 916 555 0199', 'Moscow', 2, 5400),
    Customer('C-1007', 'Lakshmi N.', 'lakshmi@example.com', '+91 98450 13300', 'Chennai', 7, 3560),
    Customer('C-1008', 'Arjun S.', 'arjun.s@example.com', '+91 90040 11223', 'Mumbai', 1, 350, blocked: true),
  ];

  late final List<Order> orders = _mkOrders();
  List<Order> _mkOrders() {
    final names = customers.map((c) => c.name).toList();
    final out = <Order>[];
    for (var i = 0; i < 14; i++) {
      final b = allBooks[(i * 7) % allBooks.length];
      final q = 1 + i % 4;
      final unit = b.basePrice;
      final c = customers[i % customers.length];
      final sub = unit * q;
      final intl = c.city == 'San Francisco' || c.city == 'Moscow';
      final ship = intl ? 1450 : (sub >= 999 ? 0 : 60);
      out.add(Order(
        id: 'BVT-${100470 - i}',
        date: DateTime.now().subtract(Duration(days: i ~/ 2, hours: i * 3)),
        lines: [OrderLine(b.id, b.title, b.purchasable.first, q, unit)],
        address: Address(id: 'x$i', name: names[i % names.length], phone: c.phone, line1: '—', city: c.city, state: intl ? '-' : 'Gujarat', pin: '380001', country: intl ? 'United States' : 'India'),
        subtotal: sub,
        discount: 0,
        shipping: ship,
        tax: 0,
        total: sub + ship,
        payment: intl ? 'Card · Stripe' : (i % 5 == 0 ? 'Cash on Delivery' : 'UPI · Razorpay'),
        courier: i % 3 == 0 ? 'Shiprocket' : 'Delhivery',
        awb: 'AWB${70000000 + i * 913}',
        stage: i < 2 ? 1 : (i < 5 ? 2 : (i < 8 ? 3 : (i == 9 ? -1 : 5))),
      ));
    }
    return out;
  }

  List<Order> get allOrders => [...app.orders.where((o) => !o.isDonation), ...orders];

  late final List<AdminSub> subs = [
    AdminSub('SUB-2901', 'Kishore Prabhu', 'Global All-Access', 'active', 'global', DateTime.now().add(const Duration(days: 12))),
    AdminSub('SUB-2902', 'Govind Patel', 'Gujarati All-Access', 'active', 'lang', DateTime.now().add(const Duration(days: 5))),
    AdminSub('SUB-2903', 'Anita Rao', 'Per-book · Rāmāyaṇa', 'trial', 'book', DateTime.now().add(const Duration(days: 2))),
    AdminSub('SUB-2904', 'Michael Adams', 'English All-Access', 'active', 'lang', DateTime.now().add(const Duration(days: 20))),
    AdminSub('SUB-2905', 'Lakshmi N.', 'Tamil All-Access', 'grace', 'lang', DateTime.now().subtract(const Duration(days: 2))),
    AdminSub('SUB-2906', 'Sofia Petrova', 'Russian All-Access', 'cancelled', 'lang', DateTime.now().subtract(const Duration(days: 9))),
    AdminSub('SUB-2907', 'Arjun S.', 'Per-book · Gītā for Youth', 'paused', 'book', DateTime.now().add(const Duration(days: 30))),
  ];

  final List<Courier> couriers = [
    Courier('Delhivery', 'dlv_live_••••••••9f2a', true, 'Connected · 142ms', 5000),
    Courier('Shiprocket', 'sr_live_••••••••71bc', true, 'Connected · 188ms', 3000),
    Courier('Shiprocket X (International)', 'srx_••••••••0d44', true, 'Connected · 301ms', 800),
  ];

  final List<Campaign> campaigns = [
    Campaign('Janmāṣṭamī book fair', 'promo_festival_v2', 'All opted-in · India', 'Sent', DateTime.now().subtract(const Duration(days: 40)), 8420, 8211, 5930),
    Campaign('Gītā for Youth launch', 'new_launch_v1', 'Youth readers', 'Sent', DateTime.now().subtract(const Duration(days: 9)), 3100, 3052, 2310),
    Campaign('Back in stock: Caitanya Mahāprabhu (Hindi)', 'back_in_stock_v1', 'Wishlist alerts', 'Sent', DateTime.now().subtract(const Duration(days: 2)), 212, 210, 188),
  ];

  final List<WaTemplate> templates = [
    WaTemplate('order_confirmed_v2', 'UTILITY', 'APPROVED', 'Hare Kṛṣṇa {{1}}! Your order {{2}} is confirmed. Total {{3}}.'),
    WaTemplate('order_dispatched_v2', 'UTILITY', 'APPROVED', 'Your order {{1}} has been dispatched via {{2}}. Track: {{3}}'),
    WaTemplate('renewal_reminder_v1', 'UTILITY', 'APPROVED', 'Your {{1}} subscription renews in 3 days for {{2}}.'),
    WaTemplate('promo_festival_v2', 'MARKETING', 'APPROVED', 'Special festival offer: {{1}} off on {{2}}. Reply STOP to opt out.'),
    WaTemplate('new_launch_v1', 'MARKETING', 'APPROVED', 'New release: {{1}} is now available in {{2}}.'),
    WaTemplate('back_in_stock_v1', 'UTILITY', 'PENDING', '{{1}} is back in stock! Order now: {{2}}'),
  ];

  List<double> sales(int days) => List.generate(days, (i) => 18000 + ((i * 7919) % 14000) + (i % 7 == 5 ? 9000 : 0) + i * 260.0);

  // ---- catalog edits ---------------------------------------------------------------
  void replaceBook(Book old, Book neu) {
    final i = allBooks.indexOf(old);
    if (i >= 0) allBooks[i] = neu;
    final j = catalog.indexOf(old);
    if (j >= 0) catalog[j] = neu;
    final k = posters.indexOf(old);
    if (k >= 0) posters[k] = neu;
    notifyListeners();
    app.update(() {});
  }

  void addBook(Book b) {
    allBooks.add(b);
    catalog.add(b);
    notifyListeners();
    app.update(() {});
  }
}

final adm = AdminState();
