import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth.dart';
import 'chatbot.dart';
import 'home.dart';
import 'listing.dart';
import 'notifications.dart';
import 'orders.dart';
import 'reader.dart';
import 'subscriptions.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(app.t('account'))),
        body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
          if (!app.loggedIn)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(children: [
                    const Icon(Icons.account_circle_outlined, size: 56, color: BvtColors.saffron),
                    const SizedBox(height: 8),
                    const Text('Sign in for the full experience', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                    const Text('Order history, saved addresses, wishlist, reading subscriptions and membership.', textAlign: TextAlign.center, style: TextStyle(color: BvtColors.muted)),
                    const SizedBox(height: 14),
                    SizedBox(width: double.infinity, child: FilledButton(onPressed: () => push(context, const LoginScreen()), child: Text('${app.t('sign_in')} / Register'))),
                  ]),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [BvtColors.deepSaffron, BvtColors.maroon])),
              child: Column(children: [
                Row(children: [
                  CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Text(app.name[0], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(app.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                    Text(app.email, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                    if (!app.emailVerified) GestureDetector(onTap: () { app.update(() => app.emailVerified = true); toast(context, 'Email verified', icon: Icons.verified); }, child: const Padding(padding: EdgeInsets.only(top: 4), child: Text('⚠ Email not verified — tap to verify (demo)', style: TextStyle(color: Color(0xFFFFE082), fontSize: 12, fontWeight: FontWeight.w700)))),
                  ])),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  _stat('${app.points}', 'Points'),
                  _stat('${app.orders.where((o) => !o.isDonation).length}', 'Orders'),
                  _stat('${app.subscriptions.where((s) => s.status != 'cancelled').length}', 'Plans'),
                  _stat(app.bmm ? 'BMM' : '—', 'Tier'),
                ]),
              ]),
            ),
          _tile(context, Icons.receipt_long_outlined, app.t('my_orders'), 'History, tracking, reorder', () => push(context, const OrdersScreen()), needLogin: true),
          _tile(context, Icons.favorite_border, app.t('wishlist'), '${app.wishlist.length} saved', () => push(context, const WishlistScreen())),
          _tile(context, Icons.workspace_premium_outlined, app.t('subscriptions'), 'Manage reading plans', () => push(context, const ManageSubscriptionsScreen()), needLogin: true),
          _tile(context, Icons.location_on_outlined, app.t('addresses'), '${app.addresses.length} saved', () => push(context, const AddressesScreen()), needLogin: true),
          _tile(context, Icons.card_membership, app.t('membership'), app.bmm ? 'Active · wholesale pricing' : 'Progress to wholesale tier', () => push(context, const MembershipScreen()), needLogin: true),
          _tile(context, Icons.stars_outlined, app.t('loyalty'), '${app.points} points', () => push(context, const LoyaltyScreen()), needLogin: true),
          _tile(context, Icons.chat_outlined, app.t('whatsapp_prefs'), app.waOptIn ? 'Opted in' : 'Opted out', () => push(context, const WhatsAppPrefsScreen()), needLogin: true),
          _tile(context, Icons.notifications_outlined, 'Notifications', '${app.unreadCount} unread', () => push(context, const NotificationsScreen())),
          const Divider(height: 24),
          _tile(context, Icons.support_agent, app.t('chat_support'), 'AI assistant on WhatsApp · human handoff', () => push(context, const ChatbotScreen())),
          _tile(context, Icons.tune, 'Settings & device features', 'Language, biometrics, widgets, Siri, deep links', () => push(context, const SettingsScreen())),
          if (app.loggedIn) ListTile(leading: const Icon(Icons.logout, color: BvtColors.red), title: Text(app.t('sign_out'), style: const TextStyle(color: BvtColors.red)), onTap: () { app.logout(); toast(context, 'Signed out'); }),
          const SizedBox(height: 10),
          const Center(child: Text('BVT Books prototype v1.0 · sample data', style: TextStyle(fontSize: 11.5, color: BvtColors.muted))),
        ]),
      ),
    );
  }

  Widget _stat(String v, String l) => Expanded(child: Column(children: [Text(v, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), Text(l, style: const TextStyle(color: Colors.white70, fontSize: 12))]));

  Widget _tile(BuildContext c, IconData i, String t, String s, VoidCallback onTap, {bool needLogin = false}) => ListTile(
        leading: CircleAvatar(backgroundColor: BvtColors.sand, child: Icon(i, color: BvtColors.deepSaffron)),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(s, style: const TextStyle(fontSize: 12.5)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          if (needLogin && !await requireLogin(c, 'Sign in to continue')) return;
          if (c.mounted) onTap();
        },
      );
}

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: Text(app.t('addresses'))),
          floatingActionButton: FloatingActionButton.extended(onPressed: () => _add(context), icon: const Icon(Icons.add), label: const Text('Add address')),
          body: app.addresses.isEmpty
              ? const EmptyState(Icons.location_off_outlined, 'No saved addresses', 'Add multiple addresses for faster checkout.')
              : ListView(padding: const EdgeInsets.all(16), children: [
                  for (final a in app.addresses)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.home_outlined, color: BvtColors.deepSaffron),
                        title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${a.oneLine}\n${a.phone}${a.gstin != null ? '\nGSTIN ${a.gstin}' : ''}'),
                        isThreeLine: true,
                        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => app.removeAddress(a)),
                      ),
                    ),
                ]),
        ),
      );

  void _add(BuildContext context) {
    final n = TextEditingController(text: app.name), p = TextEditingController(text: app.phone), l = TextEditingController(), c = TextEditingController(), z = TextEditingController();
    var st = 'Gujarat';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('New address', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 12),
              TextField(controller: n, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 10),
              TextField(controller: p, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 10),
              TextField(controller: l, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 10),
              Row(children: [Expanded(child: TextField(controller: c, decoration: const InputDecoration(labelText: 'City'))), const SizedBox(width: 10), Expanded(child: TextField(controller: z, decoration: const InputDecoration(labelText: 'PIN')))]),
              const SizedBox(height: 10),
              InputDecorator(decoration: const InputDecoration(labelText: 'State'), child: DropdownButtonHideUnderline(child: DropdownButton<String>(isDense: true, isExpanded: true, value: st, items: [for (final s in indianStates) DropdownMenuItem(value: s, child: Text(s))], onChanged: (v) => set(() => st = v!)))),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () { app.addAddress(Address(id: 'ad${DateTime.now().millisecondsSinceEpoch}', name: n.text, phone: p.text, line1: l.text.isEmpty ? '—' : l.text, city: c.text.isEmpty ? '—' : c.text, state: st, pin: z.text.isEmpty ? '000000' : z.text)); Navigator.pop(ctx); }, child: const Text('Save address'))),
            ]),
          ),
        ),
      ),
    );
  }
}

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) {
          final pct = (app.lifetimeSpend / bmmThreshold).clamp(0.0, 1.0);
          return Scaffold(
            appBar: AppBar(title: Text(app.t('membership'))),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: LinearGradient(colors: app.bmm ? const [Color(0xFFC9A227), BvtColors.maroon] : const [Color(0xFF8D6E63), Color(0xFF4E342E)])),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const Icon(Icons.workspace_premium, color: Colors.white, size: 30), const SizedBox(width: 10), Expanded(child: Text(app.bmm ? 'BMM Member' : 'Brhad Mrdanga Member tier', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)))]),
                  const SizedBox(height: 10),
                  Text(app.bmm ? 'Wholesale pricing unlocked · valid till ${dateFmt(app.bmmExpiry)}' : 'Spend ${inr(bmmThreshold)} in a year to unlock the wholesale tier automatically.', style: const TextStyle(color: Colors.white70)),
                  if (!app.bmm) ...[
                    const SizedBox(height: 14),
                    LinearProgressIndicator(value: pct, minHeight: 8, borderRadius: BorderRadius.circular(5), color: BvtColors.gold, backgroundColor: Colors.white24),
                    const SizedBox(height: 6),
                    Text('${inr(app.lifetimeSpend)} of ${inr(bmmThreshold)} · ${inr(bmmThreshold - app.lifetimeSpend)} to go', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ]),
              ),
              const SectionHeader('Benefits'),
              for (final b in [
                (Icons.percent, 'Wholesale pricing', '${(bmmDiscount * 100).round()}% off books on orders of ${inr(bmmMinOrder)}+ (minimum order enforced)'),
                (Icons.credit_score, '45-day credit', 'Pay later on eligible orders — toggle below'),
                (Icons.autorenew, 'Automatic tier management', 'Threshold detection, expiry reminders and one-tap renewal'),
                (Icons.support_agent, 'Priority support', 'Dedicated WhatsApp queue'),
              ])
                ListTile(leading: CircleAvatar(backgroundColor: BvtColors.sand, child: Icon(b.$1, color: BvtColors.deepSaffron)), title: Text(b.$2, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(b.$3)),
              if (app.bmm) ...[
                SwitchListTile(title: const Text('Use 45-day credit at checkout'), subtitle: const Text('Shows as a payment option'), value: app.credit45, onChanged: (v) => app.update(() => app.credit45 = v)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: OutlinedButton.icon(onPressed: () { app.update(() => app.bmmExpiry = app.bmmExpiry.add(const Duration(days: 365))); toast(context, 'Membership renewed for 12 months', icon: Icons.autorenew); }, icon: const Icon(Icons.autorenew), label: const Text('Renew membership')),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FilledButton.icon(
                    onPressed: () { app.update(() { app.lifetimeSpend += 900; }); if (app.lifetimeSpend >= bmmThreshold) { app.update(() { app.bmm = true; app.bmmExpiry = DateTime.now().add(const Duration(days: 365)); }); toast(context, 'Threshold reached — you are now a BMM member!', icon: Icons.celebration); } },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Demo: simulate ₹900 purchase'),
                  ),
                ),
            ]),
          );
        },
      );
}

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: Text(app.t('loyalty'))),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Icon(Icons.stars, size: 48, color: BvtColors.gold), Text('${app.points}', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: BvtColors.maroon)), Text('points · worth ≈ ₹${(app.points / 10).round()}')]))),
            const SectionHeader('How it works'),
            const ListTile(leading: Icon(Icons.shopping_bag_outlined), title: Text('Earn 1 point for every ₹10 spent'), subtitle: Text('Donations earn 1 point per ₹20')),
            const ListTile(leading: Icon(Icons.redeem), title: Text('Redeem 100 points = ₹10 off'), subtitle: Text('Applied at checkout on your next order')),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FilledButton(onPressed: app.points < 100 ? null : () { app.update(() { app.points -= 100; app.notify('Points redeemed', '₹10 credit added to your next order.', 'App'); }); toast(context, '100 points redeemed — ₹10 credit', icon: Icons.redeem); }, child: const Text('Redeem 100 points')),
            ),
            const Padding(padding: EdgeInsets.only(top: 10), child: Text('Loyalty programme — Phase 3 (prototype preview)', style: TextStyle(fontSize: 12, color: BvtColors.muted))),
          ]),
        ),
      );
}

class WhatsAppPrefsScreen extends StatelessWidget {
  const WhatsAppPrefsScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: Text(app.t('whatsapp_prefs'))),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFE7F8EE), borderRadius: BorderRadius.circular(14)), child: Row(children: [const Icon(Icons.chat, color: BvtColors.whatsapp, size: 32), const SizedBox(width: 12), Expanded(child: Text('Messages go to ${app.phone}. Opt-in recorded ${dateFmt(DateTime.now())}.', style: const TextStyle(height: 1.4)))])),
            const SizedBox(height: 8),
            SwitchListTile(title: const Text('WhatsApp notifications', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Order, shipping and subscription updates. Opt-out is honoured immediately.'), value: app.waOptIn, onChanged: (v) { app.update(() => app.waOptIn = v); toast(context, v ? 'Opted in to WhatsApp' : 'Opted out — no more WhatsApp messages', icon: Icons.chat); }),
            SwitchListTile(title: const Text('Promotional messages'), subtitle: const Text('New launches, offers'), value: app.waPromo && app.waOptIn, onChanged: app.waOptIn ? (v) => app.update(() => app.waPromo = v) : null),
            SwitchListTile(title: const Text('Back-in-stock alerts'), value: app.waBackInStock && app.waOptIn, onChanged: app.waOptIn ? (v) => app.update(() => app.waBackInStock = v) : null),
            SwitchListTile(title: const Text('Email notifications'), subtitle: const Text('Transactional emails (SendGrid/Mailgun)'), value: app.emailOptIn, onChanged: (v) => app.update(() => app.emailOptIn = v)),
            const SectionHeader('Message log'),
            if (app.waLog.isEmpty) const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Place an order to see WhatsApp messages here.', style: TextStyle(color: BvtColors.muted))),
            for (final m in app.waLog) Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFDCF8C6), borderRadius: BorderRadius.circular(10)), child: Text('${m.$2}\n${timeFmt(m.$3)}', style: const TextStyle(fontSize: 12.5)))),
          ]),
        ),
      );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('Settings & device features')),
          body: ListView(children: [
            const SectionHeader('Language & display'),
            ListTile(
              leading: const Icon(Icons.translate),
              title: Text(app.t('language')),
              trailing: SegmentedButton<String>(showSelectedIcon: false, segments: [for (final e in uiLanguages.entries) ButtonSegment(value: e.key, label: Text(e.value, style: const TextStyle(fontSize: 12)))], selected: {app.locale}, onSelectionChanged: (s) => app.update(() => app.locale = s.first)),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('Preferred book language'),
              subtitle: const Text('Detected from device · used for shelves & recommendations'),
              trailing: DropdownButton<String>(value: app.preferredBookLang, underline: const SizedBox(), items: [for (final l in languages) DropdownMenuItem(value: l.code, child: Text(l.native))], onChanged: (v) => app.update(() => app.preferredBookLang = v!)),
            ),
            SwitchListTile(secondary: const Icon(Icons.dark_mode_outlined), title: const Text('Dark mode'), value: app.dark, onChanged: (v) => app.update(() => app.dark = v)),
            ListTile(leading: const Icon(Icons.format_size), title: const Text('Text size (accessibility)'), subtitle: Slider(value: app.textScale, min: 0.85, max: 1.5, divisions: 13, label: '${(app.textScale * 100).round()}%', onChanged: (v) => app.update(() => app.textScale = v))),
            const SectionHeader('Security'),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Biometric login'),
              subtitle: const Text('Fingerprint (Android) · Face ID / Touch ID (iOS)'),
              value: app.biometric,
              onChanged: (v) async {
                if (v && !await biometricPrompt(context, reason: 'Enable biometric login')) return;
                app.update(() => app.biometric = v);
              },
            ),
            const ListTile(leading: Icon(Icons.shield_outlined), title: Text('Certificate pinning · DRM token never persisted'), subtitle: Text('No sensitive data in plaintext local storage')),
            const SectionHeader('Feel & offline'),
            SwitchListTile(secondary: const Icon(Icons.vibration), title: const Text('Haptic feedback'), subtitle: const Text('Add to cart, order confirmation'), value: app.haptics, onChanged: (v) => app.update(() => app.haptics = v)),
            SwitchListTile(secondary: const Icon(Icons.cloud_off), title: const Text('Simulate offline mode'), subtitle: const Text('Catalog cache for last 50 viewed products + downloaded chapters'), value: app.offlineMode, onChanged: (v) => app.update(() => app.offlineMode = v)),
            SwitchListTile(secondary: const Icon(Icons.local_offer_outlined), title: const Text('App-exclusive offers & early access'), value: app.appExclusive, onChanged: (v) => app.update(() => app.appExclusive = v)),
            const SectionHeader('Platform features (Android + iOS)'),
            ListTile(leading: const Icon(Icons.widgets_outlined), title: const Text('Home-screen widgets'), subtitle: const Text('Android widget · iOS widget — order tracking shortcut'), trailing: const Icon(Icons.chevron_right), onTap: () => push(context, const WidgetPreviewScreen())),
            ListTile(leading: const Icon(Icons.mic_none), title: const Text('Siri Shortcuts (iOS)'), subtitle: const Text('“Reorder last purchase”, “Continue reading”'), trailing: const Icon(Icons.chevron_right), onTap: () => push(context, const SiriScreen())),
            ListTile(leading: const Icon(Icons.link), title: const Text('Deep links tester'), subtitle: const Text('Universal Links / App Links to products & subscriptions'), trailing: const Icon(Icons.chevron_right), onTap: () => push(context, const DeepLinkScreen())),
            ListTile(leading: const Icon(Icons.notifications_active_outlined), title: const Text('Push notifications (FCM / APNs)'), subtitle: const Text('Secondary channel to WhatsApp'), trailing: const Icon(Icons.chevron_right), onTap: () => push(context, const NotificationsScreen())),
            const SizedBox(height: 30),
          ]),
        ),
      );
}

class WidgetPreviewScreen extends StatelessWidget {
  const WidgetPreviewScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final o = app.orders.where((o) => !o.isDonation).isEmpty ? null : app.orders.firstWhere((o) => !o.isDonation);
    Widget widget(String platform, double radius) => Container(
          width: 170,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.spa, size: 16, color: BvtColors.saffron), SizedBox(width: 4), Text('BVT Books', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))]),
            const SizedBox(height: 8),
            Text(o == null ? 'No active orders' : o.statusLabel, style: TextStyle(fontWeight: FontWeight.w900, color: o == null ? BvtColors.muted : stageColor(o))),
            Text(o?.id ?? 'Tap to shop', style: const TextStyle(fontSize: 11.5, color: BvtColors.muted)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: o == null ? 0 : (o.stage.clamp(0, 5) + 1) / 6, color: BvtColors.saffron, backgroundColor: BvtColors.sand, minHeight: 5),
            const SizedBox(height: 6),
            Text(platform, style: const TextStyle(fontSize: 10, color: BvtColors.muted)),
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Home-screen widgets')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Order-tracking shortcut. Tapping opens the tracking timeline directly.', style: TextStyle(color: BvtColors.muted)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF455A64), Color(0xFF263238)])),
          child: Wrap(spacing: 14, runSpacing: 14, alignment: WrapAlignment.center, children: [
            GestureDetector(onTap: o == null ? null : () => push(context, OrderTrackingScreen(o)), child: widget('Android widget', 16)),
            GestureDetector(onTap: o == null ? null : () => push(context, OrderTrackingScreen(o)), child: widget('iOS widget', 22)),
          ]),
        ),
        const SizedBox(height: 12),
        const Text('Tap a widget to open order tracking.', textAlign: TextAlign.center, style: TextStyle(color: BvtColors.muted, fontSize: 12)),
      ]),
    );
  }
}

class SiriScreen extends StatelessWidget {
  const SiriScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Siri Shortcuts')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          for (final s in [('Reorder last purchase', Icons.replay), ('Continue reading', Icons.auto_stories)])
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF7B3FA0), child: Icon(Icons.mic, color: Colors.white)),
                title: Text('“Hey Siri, ${s.$1}”', style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Tap to run'),
                trailing: Icon(s.$2),
                onTap: () async {
                  if (s.$1.startsWith('Reorder')) {
                    final o = app.orders.where((o) => !o.isDonation).toList();
                    if (o.isEmpty) { toast(context, 'No previous orders to reorder', icon: Icons.info_outline); return; }
                    app.reorder(o.first);
                    toast(context, 'Siri: added your last purchase to the cart', icon: Icons.mic, action: 'VIEW', onAction: () { tabIndex.value = 3; Navigator.of(context).popUntil((r) => r.isFirst); });
                  } else {
                    final lib = app.library;
                    if (lib.isEmpty) { toast(context, 'No unlocked books yet — subscribe first', icon: Icons.info_outline); return; }
                    push(context, ReaderScreen(lib.firstWhere((b) => app.progress.containsKey(b.id), orElse: () => lib.first)));
                  }
                },
              ),
            ),
        ]),
      );
}

class DeepLinkScreen extends StatelessWidget {
  const DeepLinkScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final links = <(String, String, VoidCallback)>[
      ('https://books.bvks.com/book/ramayana-en.html', 'Product page', () => openBook(context, bookById('ramayana-en'))),
      ('https://books.bvks.com/subscriptions', 'Subscription plans', () => push(context, const PlansScreen())),
      ('https://books.bvks.com/language/gu', 'Gujarati shelf', () => push(context, const ListingScreen(title: 'Gujarati books', language: 'gu'))),
      ('https://books.bvks.com/track/BVT-100482', 'Order tracking', () { final o = app.orders.where((o) => o.id == 'BVT-100482'); if (o.isNotEmpty) { push(context, OrderTrackingScreen(o.first)); } else { toast(context, 'Sign in to open this order', icon: Icons.lock_outline); } }),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Deep links tester')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Shared links open the app directly (iOS Universal Links, Android App Links). Tap a link to simulate.', style: TextStyle(color: BvtColors.muted)),
        const SizedBox(height: 12),
        for (final l in links) Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: const Icon(Icons.link, color: BvtColors.deepSaffron), title: Text(l.$2, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(l.$1, style: const TextStyle(fontSize: 12)), trailing: const Icon(Icons.open_in_new), onTap: l.$3)),
      ]),
    );
  }
}
