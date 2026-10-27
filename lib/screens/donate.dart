import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'checkout.dart' show showPaySheet;

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});
  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  int amount = 1100;
  final _custom = TextEditingController();
  final _name = TextEditingController();
  final _pan = TextEditingController();
  bool anon = false, monthly = false, intl = false, busy = false;
  String cause = 'Book distribution';
  String method = 'upi';

  static const amounts = [251, 501, 1100, 2100, 5100];
  static const causes = [('Book distribution', Icons.menu_book, 'Free books to students and libraries'), ('Temple & festival seva', Icons.temple_hindu, 'Maintenance and festivals'), ('Annadāna', Icons.rice_bowl, 'Sanctified meals for the needy'), ('Where needed most', Icons.favorite, 'General fund')];

  @override
  void dispose() {
    _custom.dispose();
    _name.dispose();
    _pan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(app.t('donate'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [BvtColors.deepSaffron, BvtColors.maroon])),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.volunteer_activism, color: Colors.white, size: 34),
            SizedBox(height: 8),
            Text('Support the mission', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            SizedBox(height: 4),
            Text('Your seva helps print and distribute transcendental literature. 80G tax-exemption receipt provided.', style: TextStyle(color: Colors.white70, height: 1.4)),
          ]),
        ),
        const SectionHeader('Choose an amount'),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final a in amounts) ChoiceChip(label: Text(inr(a), style: const TextStyle(fontWeight: FontWeight.w800)), selected: amount == a && _custom.text.isEmpty, onSelected: (_) => setState(() { amount = a; _custom.clear(); })),
        ]),
        const SizedBox(height: 12),
        TextField(controller: _custom, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Other amount', prefixText: '₹ '), onChanged: (v) => setState(() => amount = int.tryParse(v) ?? 0)),
        const SectionHeader('Frequency'),
        SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('One-time'), icon: Icon(Icons.bolt)), ButtonSegment(value: true, label: Text('Monthly'), icon: Icon(Icons.autorenew))], selected: {monthly}, onSelectionChanged: (s) => setState(() => monthly = s.first)),
        if (monthly) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Recurring via Razorpay Subscriptions (India) / Stripe Billing (international).', style: TextStyle(fontSize: 12, color: BvtColors.muted))),
        const SectionHeader('Dedicate to'),
        for (final c in causes)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: cause == c.$1 ? BvtColors.saffron : const Color(0xFFEBD9BC), width: cause == c.$1 ? 2 : 1)),
            child: ListTile(onTap: () => setState(() => cause = c.$1), leading: Icon(c.$2, color: BvtColors.deepSaffron), title: Text(c.$1, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(c.$3), trailing: Icon(cause == c.$1 ? Icons.radio_button_checked : Icons.radio_button_off, color: BvtColors.saffron)),
          ),
        const SectionHeader('Donor details'),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Donate anonymously'), value: anon, onChanged: (v) => setState(() => anon = v)),
        if (!anon) TextField(controller: _name, decoration: InputDecoration(labelText: 'Donor name (optional)', hintText: app.loggedIn ? app.name : null)),
        const SizedBox(height: 10),
        TextField(controller: _pan, decoration: const InputDecoration(labelText: 'PAN (optional, for 80G receipt)')),
        const SectionHeader('Payment'),
        SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('India · Razorpay')), ButtonSegment(value: true, label: Text('International · Stripe'))], selected: {intl}, onSelectionChanged: (s) => setState(() { intl = s.first; method = intl ? 'card' : 'upi'; })),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final m in intl ? [('card', 'Card'), ('paypal', 'PayPal')] : [('upi', 'UPI'), ('card', 'Card'), ('nb', 'Net banking'), ('wallet', 'Wallet')]) ChoiceChip(label: Text(m.$2), selected: method == m.$1, onSelected: (_) => setState(() => method = m.$1)),
        ]),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: busy || amount < 10 ? null : _donate,
          icon: const Icon(Icons.favorite),
          label: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Donate ${inr(amount)}${monthly ? ' / month' : ''}'),
        ),
      ]),
    );
  }

  Future<void> _donate() async {
    setState(() => busy = true);
    final ok = await showPaySheet(context, method, amount, intl);
    if (!mounted) return;
    setState(() => busy = false);
    if (ok != true) return;
    final donor = anon ? 'Anonymous' : (_name.text.isEmpty ? (app.loggedIn ? app.name : 'Friend') : _name.text);
    app.recordDonation(amount, donor, intl ? 'Stripe' : 'Razorpay', cause);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.favorite, color: BvtColors.red, size: 48),
        title: const Text('Thank you!'),
        content: Text('${inr(amount)} received${monthly ? ' (monthly)' : ''} for $cause.\nHare Kṛṣṇa, $donor 🙏\n\n80G receipt sent by email and WhatsApp.'),
        actions: [FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('Done'))],
      ),
    );
  }
}
