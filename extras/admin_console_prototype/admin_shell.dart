import 'package:flutter/material.dart';

import '../main.dart' show wideMode;
import '../theme.dart';
import 'admin_state.dart';
import 'admin_widgets.dart' hide Pill;
import 'modules_a.dart';
import 'modules_b.dart';
import 'modules_c.dart';

class AdminGate extends StatefulWidget {
  const AdminGate({super.key});
  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final _email = TextEditingController(text: 'admin@bvks.com');
  final _pass = TextEditingController(text: 'admin-demo');
  final _code = TextEditingController();
  bool step2 = false;
  late String roleName = adm.role.name;

  @override
  void initState() {
    super.initState();
    wideMode.value = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) => wideMode.value = false);
    _email.dispose();
    _pass.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (adm.authed) return const AdminShell();
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Console')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(24), children: [
            const Icon(Icons.admin_panel_settings, size: 56, color: BvtColors.maroon),
            const SizedBox(height: 8),
            Text('BVT Admin Console', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const Text('Role-based · 2FA enforced · IP allow-list', textAlign: TextAlign.center, style: TextStyle(color: BvtColors.muted)),
            const SizedBox(height: 24),
            if (!step2) ...[
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'Staff email', prefixIcon: Icon(Icons.mail_outline))),
              const SizedBox(height: 12),
              TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Sign in as role (demo)', prefixIcon: Icon(Icons.badge_outlined)),
                child: DropdownButtonHideUnderline(child: DropdownButton<String>(isDense: true, isExpanded: true, value: roleName, items: [for (final r in adm.roles) DropdownMenuItem(value: r.name, child: Text(r.name))], onChanged: (v) => setState(() => roleName = v!))),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => setState(() => step2 = true), child: const Text('Continue')),
              const SizedBox(height: 10),
              const Text('IP check: 103.21.58.14 ✓ allow-listed (demo)', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: BvtColors.green)),
            ] else ...[
              const Text('Two-factor authentication', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: '6-digit code from authenticator', helperText: 'Demo: enter any 6 digits, or tap Autofill')),
              Row(children: [
                TextButton(onPressed: () => setState(() => _code.text = '123456'), child: const Text('Autofill')),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    if (_code.text.length != 6) {
                      adminToast(context, 'Enter the 6-digit code');
                      return;
                    }
                    adm.role = adm.roles.firstWhere((r) => r.name == roleName);
                    setState(() => adm.authed = true);
                  },
                  child: const Text('Verify & sign in'),
                ),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  String current = 'dashboard';

  Widget _body() => switch (current) {
        'dashboard' => AdminDashboard(onGo: (k) => setState(() => current = k)),
        'products' => const ProductsModule(),
        'inventory' => const InventoryModule(),
        'orders' => const OrdersModule(),
        'subscriptions' => const SubscriptionsModule(),
        'customers' => const CustomersModule(),
        'shipping' => const ShippingModule(),
        'whatsapp' => const WhatsAppModule(),
        'chatbot' => const ChatbotKbModule(),
        'cms' => const CmsModule(),
        'banners' => const BannersModule(),
        'navigation' => const NavigationModule(),
        'search' => const SearchModule(),
        'reports' => const ReportsModule(),
        'finance' => const FinanceModule(),
        'zoho' => const ZohoModule(),
        'audit' => const AuditModule(),
        'roles' => const RolesModule(),
        _ => const SettingsModule(),
      };

  Widget _nav({bool drawer = false}) {
    return ListenableBuilder(
      listenable: adm,
      builder: (context, _) => Container(
        width: 250,
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1713) : const Color(0xFF3A1D0C),
        child: SafeArea(
          child: Column(children: [
            const Padding(padding: EdgeInsets.fromLTRB(16, 18, 16, 10), child: Row(children: [Icon(Icons.spa, color: BvtColors.gold), SizedBox(width: 10), Expanded(child: Text('BVT Admin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)))])),
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [const CircleAvatar(radius: 14, backgroundColor: BvtColors.gold, child: Text('A', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900))), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(adm.userName, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)), Text(adm.role.name, style: const TextStyle(color: Colors.white60, fontSize: 11))]))]),
            ),
            Expanded(
              child: ListView(children: [
                for (final m in adminModules)
                  ListTile(
                    dense: true,
                    selected: current == m.key,
                    selectedTileColor: Colors.white12,
                    iconColor: Colors.white70,
                    textColor: Colors.white70,
                    selectedColor: BvtColors.gold,
                    leading: Icon(m.icon, size: 20),
                    title: Text(m.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    trailing: !adm.canRead(m.key) ? const Icon(Icons.lock, size: 14, color: Colors.white38) : (!adm.canWrite(m.key) ? const Icon(Icons.visibility, size: 14, color: Colors.white38) : null),
                    onTap: () {
                      setState(() => current = m.key);
                      if (drawer) Navigator.pop(context);
                    },
                  ),
              ]),
            ),
            ListTile(dense: true, iconColor: Colors.white70, textColor: Colors.white70, leading: const Icon(Icons.logout, size: 20), title: const Text('Sign out of admin'), onTap: () { adm.authed = false; Navigator.of(context).pop(); }),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    final title = adminModules.firstWhere((m) => m.key == current).label;
    return PopScope(
      onPopInvokedWithResult: (_, __) => adm.authed = false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: wide ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () { adm.authed = false; Navigator.of(context).pop(); }) : null,
          actions: [
            const Center(child: Text('View as: ', style: TextStyle(fontSize: 12.5))),
            ListenableBuilder(
              listenable: adm,
              builder: (_, __) => DropdownButton<AdminRole>(
                value: adm.role,
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 13, color: BvtColors.maroon, fontWeight: FontWeight.w700),
                items: [for (final r in adm.roles) DropdownMenuItem(value: r, child: Text(r.name))],
                onChanged: (v) {
                  adm.role = v!;
                  adm.changed();
                  adminToast(context, 'Now viewing as ${v.name} — permissions enforced');
                },
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        drawer: wide ? null : Drawer(width: 250, child: _nav(drawer: true)),
        body: wide ? Row(children: [_nav(), Expanded(child: _body())]) : _body(),
      ),
    );
  }
}
