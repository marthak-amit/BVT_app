import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth.dart';
import 'orders.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int step = 0;
  Address? address;
  ShippingOption? ship;
  String method = 'upi';
  late bool wa = app.waOptIn;
  bool createAccount = false, failSim = false, busy = false, addingNew = false;
  final _guestEmail = TextEditingController();

  // new address form
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _phone = TextEditingController(), _l1 = TextEditingController(), _city = TextEditingController(), _pin = TextEditingController(), _gstin = TextEditingController();
  String state = 'Gujarat', country = 'India';
  bool saveAddr = true;

  static const stepNames = ['Address', 'Shipping', 'Payment', 'Review'];

  @override
  void initState() {
    super.initState();
    if (app.loggedIn && app.addresses.isNotEmpty) address = app.addresses.first;
    addingNew = !(app.loggedIn && app.addresses.isNotEmpty);
    if (app.loggedIn) {
      _name.text = app.name;
      _phone.text = app.phone;
    }
  }

  @override
  void dispose() {
    for (final c in [_guestEmail, _name, _phone, _l1, _city, _pin, _gstin]) {
      c.dispose();
    }
    super.dispose();
  }

  CartSummary get summary => app.summary(ship: ship, addr: address);

  int get netForShip => app.summary().afterLine - app.summary().promoDiscount;

  List<(String, String, IconData)> get methods {
    final intl = address != null && !address!.isIndia;
    if (intl) return [('card', 'Credit / Debit card — Stripe', Icons.credit_card), ('paypal', 'PayPal', Icons.account_balance_wallet_outlined), ('apple', 'Apple Pay', Icons.apple)];
    return [
      ('upi', 'UPI — GPay, PhonePe, Paytm (Razorpay)', Icons.qr_code_2),
      ('card', 'Credit / Debit card', Icons.credit_card),
      ('nb', 'Net banking', Icons.account_balance),
      ('wallet', 'Wallets', Icons.wallet),
      ('emi', 'EMI (orders above ₹3,000)', Icons.calendar_month),
      ('apple', 'Apple Pay', Icons.apple),
      if (summary.total <= 5000) ('cod', 'Cash on Delivery (physical books, India)', Icons.payments_outlined),
      if (app.bmm) ('credit', 'BMM 45-day credit', Icons.credit_score),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (app.cart.isEmpty && step < 4) {
      return Scaffold(appBar: AppBar(), body: const EmptyState(Icons.shopping_cart_outlined, 'Your cart is empty', 'Add something to continue.'));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(children: [
        _Stepper(step, stepNames),
        Expanded(
          child: ListenableBuilder(
            listenable: app,
            builder: (_, _) => switch (step) { 0 => _addressStep(), 1 => _shippingStep(), 2 => _paymentStep(), _ => _reviewStep() },
          ),
        ),
        _bottom(),
      ]),
    );
  }

  Widget _bottom() {
    final s = summary;
    final enabled = switch (step) { 0 => address != null, 1 => ship != null, 2 => true, _ => !busy };
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEBD9BC)))),
        child: Row(children: [
          if (step > 0) IconButton.outlined(onPressed: () => setState(() => step--), icon: const Icon(Icons.arrow_back)),
          if (step > 0) const SizedBox(width: 10),
          Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(app.t('total'), style: const TextStyle(fontSize: 11.5, color: BvtColors.muted)),
            Text(inr(s.total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: BvtColors.maroon)),
          ]),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: enabled ? _next : null,
              child: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(step == 3 ? (method == 'cod' ? 'Place order' : 'Pay & place order') : 'Continue'),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _next() async {
    if (step == 0) {
      if (addingNew) {
        if (!_form.currentState!.validate()) return;
        if (!app.loggedIn && !_guestEmail.text.contains('@')) {
          toast(context, 'Enter your email for the order confirmation', icon: Icons.mail_outline);
          return;
        }
        final a = Address(id: 'ad${DateTime.now().millisecondsSinceEpoch}', name: _name.text, phone: _phone.text, line1: _l1.text, city: _city.text, state: country == 'India' ? state : '-', pin: _pin.text, country: country, gstin: _gstin.text.isEmpty ? null : _gstin.text);
        if (app.loggedIn && saveAddr) app.addAddress(a);
        address = a;
      }
      ship = null;
      final opts = app.shippingOptions(address, netForShip);
      ship = opts.first;
      if (!methods.any((m) => m.$1 == method)) method = methods.first.$1;
      setState(() => step = 1);
    } else if (step == 1) {
      setState(() => step = 2);
    } else if (step == 2) {
      setState(() => step = 3);
    } else {
      await _pay();
    }
  }

  Future<void> _pay({int? partial}) async {
    final s = summary;
    setState(() => busy = true);
    if (method != 'cod' && method != 'credit') {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isDismissible: false,
        builder: (_) => _GatewaySheet(method: method, amount: partial ?? s.total, intl: address != null && !address!.isIndia, fail: failSim && partial == null),
      );
      if (!mounted) return;
      if (ok != true) {
        setState(() => busy = false);
        _failed(s);
        return;
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 700));
    }
    if (!mounted) return;
    app.waOptIn = wa;
    final label = switch (method) {
      'upi' => 'UPI · Razorpay',
      'card' => (address != null && !address!.isIndia) ? 'Card · Stripe' : 'Card · Razorpay',
      'nb' => 'Net banking · Razorpay',
      'wallet' => 'Wallet · Razorpay',
      'emi' => 'EMI · Razorpay',
      'apple' => 'Apple Pay',
      'paypal' => 'PayPal',
      'cod' => 'Cash on Delivery',
      _ => 'BMM 45-day credit',
    };
    final order = app.placeOrder(address: address!, ship: ship!, payment: label, s: s, paidNow: partial);
    if (!app.loggedIn && createAccount) {
      app.register(address!.name, _guestEmail.text, address!.phone, wa: wa);
    }
    setState(() => busy = false);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order, accountCreated: createAccount)));
  }

  void _failed(CartSummary s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: BvtColors.red, size: 44),
        title: const Text('Payment failed'),
        content: const Text('Your payment could not be completed and you have not been charged. Your cart is safe.\n\nYou can retry, use another method, or pay part now and the rest later via a payment link.'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); setState(() { step = 2; failSim = false; }); }, child: const Text('Change method')),
          TextButton(onPressed: () { Navigator.pop(ctx); setState(() => failSim = false); _pay(partial: (s.total / 2).round()); }, child: Text('Pay ${inr((s.total / 2).round())} now')),
          FilledButton(onPressed: () { Navigator.pop(ctx); setState(() => failSim = false); _pay(); }, child: const Text('Retry')),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- steps
  Widget _addressStep() {
    final logged = app.loggedIn;
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (!logged)
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline, color: BvtColors.deepSaffron),
            title: const Text('Have an account?'),
            subtitle: const Text('Sign in for saved addresses, or continue as guest'),
            trailing: TextButton(onPressed: () async { await push(context, const LoginScreen()); if (mounted) setState(() { if (app.loggedIn && app.addresses.isNotEmpty) { address = app.addresses.first; addingNew = false; } }); }, child: const Text('Sign in')),
          ),
        ),
      if (logged && app.addresses.isNotEmpty) ...[
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Saved addresses', style: TextStyle(fontWeight: FontWeight.w800))),
        for (final a in app.addresses)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: address?.id == a.id && !addingNew ? BvtColors.saffron : const Color(0xFFEBD9BC), width: address?.id == a.id && !addingNew ? 2 : 1)),
            child: ListTile(
              onTap: () => setState(() { address = a; addingNew = false; }),
              leading: Icon(address?.id == a.id && !addingNew ? Icons.radio_button_checked : Icons.radio_button_off, color: BvtColors.saffron),
              title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${a.oneLine}\n${a.phone}${a.gstin != null ? '\nGSTIN ${a.gstin}' : ''}'),
              isThreeLine: true,
            ),
          ),
        OutlinedButton.icon(onPressed: () => setState(() => addingNew = !addingNew), icon: Icon(addingNew ? Icons.close : Icons.add), label: Text(addingNew ? 'Use a saved address' : 'Add a new address')),
      ],
      if (addingNew) ...[
        const SizedBox(height: 12),
        Form(
          key: _form,
          child: Column(children: [
            if (!logged) ...[
              TextFormField(controller: _guestEmail, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (for confirmation & invoice)', prefixIcon: Icon(Icons.mail_outline))),
              const SizedBox(height: 12),
            ],
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name'), validator: _req),
            const SizedBox(height: 12),
            TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone / WhatsApp number'), validator: (v) => (v ?? '').length < 8 ? 'Enter a valid number' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _l1, decoration: const InputDecoration(labelText: 'Address line'), validator: _req),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'City'), validator: _req)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _pin, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PIN / ZIP'), validator: (v) => (v ?? '').length < 5 ? 'Invalid' : null)),
            ]),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Country'),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, isDense: true, value: country, items: [for (final c in countries) DropdownMenuItem(value: c, child: Text(c))], onChanged: (v) => setState(() => country = v!))),
            ),
            if (country == 'India') ...[
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'State (decides CGST+SGST / IGST)'),
                child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, isDense: true, value: state, items: [for (final c in indianStates) DropdownMenuItem(value: c, child: Text(c))], onChanged: (v) => setState(() => state = v!))),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _gstin, decoration: const InputDecoration(labelText: 'GSTIN (optional, for GST invoice)')),
            ],
            if (logged) CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: saveAddr, onChanged: (v) => setState(() => saveAddr = v!), title: const Text('Save this address')),
          ]),
        ),
      ],
    ]);
  }

  String? _req(String? v) => (v ?? '').trim().isEmpty ? 'Required' : null;

  Widget _shippingStep() {
    final opts = app.shippingOptions(address, netForShip);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: ListTile(leading: const Icon(Icons.location_on, color: BvtColors.deepSaffron), title: Text(address!.name), subtitle: Text(address!.oneLine), trailing: TextButton(onPressed: () => setState(() => step = 0), child: const Text('Change')))),
      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Choose delivery method', style: TextStyle(fontWeight: FontWeight.w800))),
      for (final o in opts)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: ship?.id == o.id ? BvtColors.saffron : const Color(0xFFEBD9BC), width: ship?.id == o.id ? 2 : 1)),
          child: ListTile(
            onTap: () => setState(() => ship = o),
            leading: Icon(ship?.id == o.id ? Icons.radio_button_checked : Icons.radio_button_off, color: BvtColors.saffron),
            title: Text(o.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${o.courier} · ${o.eta}\nLive rate fetched from courier API'),
            isThreeLine: true,
            trailing: Text(o.fee == 0 ? 'FREE' : inr(o.fee), style: TextStyle(fontWeight: FontWeight.w900, color: o.fee == 0 ? BvtColors.green : BvtColors.ink)),
          ),
        ),
      const SizedBox(height: 8),
      _orderMini(),
    ]);
  }

  Widget _paymentStep() {
    final intl = address != null && !address!.isIndia;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(intl ? 'International payment · Stripe / PayPal' : 'India payment · Razorpay', style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      for (final m in methods)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: method == m.$1 ? BvtColors.saffron : const Color(0xFFEBD9BC), width: method == m.$1 ? 2 : 1)),
          child: ListTile(
            onTap: () => setState(() => method = m.$1),
            leading: Icon(m.$3, color: BvtColors.deepSaffron),
            title: Text(m.$2),
            trailing: Icon(method == m.$1 ? Icons.radio_button_checked : Icons.radio_button_off, color: BvtColors.saffron),
          ),
        ),
      if (app.loggedIn && app.bmm)
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('BMM 45-day credit'), subtitle: const Text('Toggle credit terms for this order'), value: app.credit45, onChanged: (v) => app.update(() => app.credit45 = v)),
      const Divider(height: 28),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: const Icon(Icons.chat, color: BvtColors.whatsapp),
        title: const Text('Get order updates on WhatsApp'),
        subtitle: const Text('Explicit opt-in. Order confirmed → packed → dispatched → delivered, with live tracking link.'),
        value: wa,
        onChanged: (v) => setState(() => wa = v),
      ),
      if (!app.loggedIn) CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: createAccount, onChanged: (v) => setState(() => createAccount = v!), title: const Text('Create an account after purchase'), subtitle: const Text('Track orders and access your library')),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Demo: simulate payment failure'), subtitle: const Text('Shows retry & partial-payment handling'), value: failSim, onChanged: (v) => setState(() => failSim = v)),
      const Text('🔒 PCI-DSS: no raw card data is stored on BVT servers — gateway tokenisation only.', style: TextStyle(fontSize: 12, color: BvtColors.muted)),
    ]);
  }

  Widget _reviewStep() {
    final s = summary;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: ListTile(leading: const Icon(Icons.location_on, color: BvtColors.deepSaffron), title: Text(address!.name), subtitle: Text(address!.oneLine), trailing: TextButton(onPressed: () => setState(() => step = 0), child: const Text('Edit')))),
      const SizedBox(height: 8),
      Card(child: ListTile(leading: const Icon(Icons.local_shipping, color: BvtColors.deepSaffron), title: Text('${ship!.name} · ${ship!.courier}'), subtitle: Text(ship!.eta), trailing: TextButton(onPressed: () => setState(() => step = 1), child: const Text('Edit')))),
      const SizedBox(height: 8),
      Card(child: ListTile(leading: const Icon(Icons.payment, color: BvtColors.deepSaffron), title: Text(methods.firstWhere((m) => m.$1 == method, orElse: () => methods.first).$2), subtitle: Text(wa ? 'WhatsApp updates ON' : 'WhatsApp updates OFF'), trailing: TextButton(onPressed: () => setState(() => step = 2), child: const Text('Edit')))),
      const SectionHeader('Items'),
      for (final lc in s.lines)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: BookCover(lc.book, width: 38, showLang: false),
          title: Text(lc.book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text('${lc.line.format.label} × ${lc.line.qty}'),
          trailing: Text(inr(lc.net), style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      const Divider(),
      _orderMini(),
    ]);
  }

  Widget _orderMini() {
    final s = summary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          KeyVal('Subtotal', inr(s.gross)),
          if (s.lineDiscount > 0) KeyVal('Bulk / member savings', '-${inr(s.lineDiscount)}', color: BvtColors.green),
          if (s.promoDiscount > 0) KeyVal('Promo', '-${inr(s.promoDiscount)}', color: BvtColors.green),
          KeyVal('Shipping', ship == null ? '—' : (s.shipping == 0 ? 'FREE' : inr(s.shipping))),
          KeyVal(s.taxLabel, s.tax == 0 ? '₹0 (books 0% GST)' : inr(s.tax)),
          const Divider(height: 20),
          KeyVal(app.t('total'), inr(s.total), bold: true),
        ]),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int step;
  final List<String> names;
  const _Stepper(this.step, this.names);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: Row(children: [
          for (var i = 0; i < names.length; i++) ...[
            Expanded(
              child: Column(children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: i <= step ? BvtColors.saffron : const Color(0xFFE2CFAE),
                  child: i < step ? const Icon(Icons.check, size: 16, color: Colors.white) : Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 3),
                Text(names[i], style: TextStyle(fontSize: 11.5, fontWeight: i == step ? FontWeight.w800 : FontWeight.w500)),
              ]),
            ),
            if (i < names.length - 1) Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 16), color: i < step ? BvtColors.saffron : const Color(0xFFE2CFAE))),
          ],
        ]),
      );
}

class _GatewaySheet extends StatefulWidget {
  final String method;
  final int amount;
  final bool intl, fail;
  const _GatewaySheet({required this.method, required this.amount, required this.intl, required this.fail});
  @override
  State<_GatewaySheet> createState() => _GatewaySheetState();
}

class _GatewaySheetState extends State<_GatewaySheet> {
  bool processing = false;
  @override
  Widget build(BuildContext context) {
    final brand = widget.method == 'paypal' ? 'PayPal' : (widget.intl ? 'Stripe' : 'Razorpay');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [Icon(Icons.lock, size: 18, color: BvtColors.green), const SizedBox(width: 6), Text('$brand Secure Checkout', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const Spacer(), const Text('Prototype', style: TextStyle(color: BvtColors.muted, fontSize: 11))]),
          const Divider(height: 24),
          Text(inr(widget.amount), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: BvtColors.maroon)),
          const Text('Bhakti Vikas Trust', style: TextStyle(color: BvtColors.muted)),
          const SizedBox(height: 16),
          if (widget.method == 'upi') const ListTile(leading: Icon(Icons.qr_code_2, size: 36), title: Text('Pay with UPI'), subtitle: Text('radhika@okaxis · request sent to your UPI app')),
          if (widget.method == 'card' || widget.method == 'emi') const ListTile(leading: Icon(Icons.credit_card, size: 32), title: Text('•••• •••• •••• 4242'), subtitle: Text('Tokenised card · 3-D Secure')),
          if (widget.method == 'nb') const ListTile(leading: Icon(Icons.account_balance, size: 32), title: Text('HDFC Bank'), subtitle: Text('You will be redirected to net banking')),
          if (widget.method == 'wallet') const ListTile(leading: Icon(Icons.wallet, size: 32), title: Text('Paytm Wallet'), subtitle: Text('Balance sufficient')),
          if (widget.method == 'apple') const ListTile(leading: Icon(Icons.apple, size: 34), title: Text('Apple Pay'), subtitle: Text('Double-click side button to confirm')),
          if (widget.method == 'paypal') const ListTile(leading: Icon(Icons.account_balance_wallet, size: 32), title: Text('PayPal balance')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: processing ? null : () => Navigator.pop(context, false), child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: processing ? null : () async {
                  setState(() => processing = true);
                  await Future.delayed(const Duration(milliseconds: 1300));
                  if (context.mounted) Navigator.pop(context, !widget.fail);
                },
                child: processing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Pay ${inr(widget.amount)}'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

Future<bool?> showPaySheet(BuildContext c, String method, int amount, bool intl, {bool fail = false}) =>
    showModalBottomSheet<bool>(context: c, isDismissible: false, builder: (_) => _GatewaySheet(method: method, amount: amount, intl: intl, fail: fail));
