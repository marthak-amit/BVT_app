import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth.dart';
import 'reader.dart';

class PlansScreen extends StatefulWidget {
  final Book? forBook;
  const PlansScreen({super.key, this.forBook});
  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  bool yearly = false, gift = false;
  late String selected = widget.forBook != null ? 'book' : 'lang';
  late String lang = widget.forBook?.language ?? app.preferredBookLang;
  late Book? book = widget.forBook;
  final _giftTo = TextEditingController();

  @override
  void dispose() {
    _giftTo.dispose();
    super.dispose();
  }

  Plan get plan => planById(selected);
  int get price => yearly ? plan.yearly : plan.monthly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(app.t('subscription_plans'))),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEBD9BC)))),
          child: Row(children: [
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${inr(price)}${yearly ? '/year' : '/month'}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: BvtColors.maroon)),
              Text(gift ? 'Gift · no trial' : '${app.trialOverride > 0 ? app.trialOverride : plan.trialDays}-day free trial', style: const TextStyle(fontSize: 12, color: BvtColors.green, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: () async {
                  if (!await requireLogin(context, 'Sign in to subscribe') || !context.mounted) return;
                  if (selected == 'book' && book == null) {
                    toast(context, 'Please choose a book for the per-book plan', icon: Icons.info_outline);
                    return;
                  }
                  if (gift && _giftTo.text.trim().isEmpty) {
                    toast(context, 'Enter the recipient’s registered email or WhatsApp number', icon: Icons.card_giftcard);
                    return;
                  }
                  push(context, SubscribeCheckout(plan: plan, yearly: yearly, book: book, lang: lang, gift: gift, giftTo: _giftTo.text.trim()));
                },
                child: Text(gift ? 'Gift this plan' : 'Start free trial'),
              ),
            ),
          ]),
        ),
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [BvtColors.sand, BvtColors.cream])),
          child: Column(children: [
            const Icon(Icons.auto_stories, size: 44, color: BvtColors.deepSaffron),
            const SizedBox(height: 8),
            Text('Read more. Anywhere.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: BvtColors.maroon)),
            const SizedBox(height: 4),
            const Text('DRM-protected in-app reader with bookmarks, highlights and offline chapters.', textAlign: TextAlign.center, style: TextStyle(color: BvtColors.muted)),
            const SizedBox(height: 14),
            SegmentedButton<bool>(
              segments: const [ButtonSegment(value: false, label: Text('Monthly')), ButtonSegment(value: true, label: Text('Yearly · save ~25%'))],
              selected: {yearly},
              onSelectionChanged: (s) => setState(() => yearly = s.first),
            ),
          ]),
        ),
        for (final p in plans)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => selected = p.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected == p.id ? BvtColors.saffron : const Color(0xFFEBD9BC), width: selected == p.id ? 2.5 : 1),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(selected == p.id ? Icons.radio_button_checked : Icons.radio_button_off, color: BvtColors.saffron),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
                    if (p.id == 'lang') const Pill('MOST POPULAR', color: BvtColors.green),
                  ]),
                  Padding(padding: const EdgeInsets.only(left: 34), child: Text(p.blurb, style: const TextStyle(color: BvtColors.muted))),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 34),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(inr(yearly ? p.yearly : p.monthly), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: BvtColors.maroon)),
                      Text(yearly ? ' /year' : ' /month', style: const TextStyle(color: BvtColors.muted)),
                    ]),
                  ),
                  if (selected == p.id) ...[
                    const SizedBox(height: 10),
                    for (final perk in p.perks) Padding(padding: const EdgeInsets.only(left: 30, bottom: 4), child: Row(children: [const Icon(Icons.check_circle, size: 16, color: BvtColors.green), const SizedBox(width: 8), Expanded(child: Text(perk, style: const TextStyle(fontSize: 13)))])),
                    if (p.id == 'lang') ...[
                      const SizedBox(height: 8),
                      Padding(padding: const EdgeInsets.only(left: 34), child: Wrap(spacing: 6, runSpacing: 0, children: [for (final l in languages.take(8)) ChoiceChip(label: Text(l.native, style: const TextStyle(fontSize: 12)), selected: lang == l.code, onSelected: (_) => setState(() => lang = l.code))])),
                    ],
                    if (p.id == 'book') ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 34),
                        child: OutlinedButton.icon(
                          onPressed: () => _pickBook(context),
                          icon: const Icon(Icons.menu_book, size: 18),
                          label: Text(book == null ? 'Choose a book' : book!.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ],
                ]),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(children: [
                SwitchListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 8), secondary: const Icon(Icons.card_giftcard, color: BvtColors.deepSaffron), title: const Text('Gift this subscription'), subtitle: const Text('Send to another registered user'), value: gift, onChanged: (v) => setState(() => gift = v)),
                if (gift) Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 8), child: TextField(controller: _giftTo, decoration: const InputDecoration(labelText: 'Recipient email or WhatsApp number', prefixIcon: Icon(Icons.person_add_alt)))),
              ]),
            ),
          ),
        ),
        const SectionHeader('Compare plans'),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _Compare()),
        const SectionHeader('Frequently asked questions'),
        for (final f in faqs) Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3), child: Card(child: ExpansionTile(shape: const Border(), title: Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14), expandedCrossAxisAlignment: CrossAxisAlignment.start, children: [Text(f.$2, style: const TextStyle(height: 1.45, color: BvtColors.muted))]))),
        const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 0), child: Text('Ebooks from Kindle / Apple Books / Google Play are separate purchases on those stores.', style: TextStyle(fontSize: 12, color: BvtColors.muted))),
      ]),
    );
  }

  void _pickBook(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (_, sc) => ListView(controller: sc, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Choose a book', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
          for (final b in allBooks.where((b) => b.subEligible && b.language == (book?.language ?? app.preferredBookLang)))
            ListTile(leading: BookCover(b, width: 34, showLang: false), title: Text(b.title), subtitle: Text(langOf(b.language).name), onTap: () { setState(() => book = b); Navigator.pop(context); }),
        ]),
      ),
    );
  }
}

class _Compare extends StatelessWidget {
  Widget _c(String t, {bool head = false, bool center = true}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: t == '✓'
            ? const Icon(Icons.check, color: BvtColors.green, size: 18)
            : t == '–'
                ? const Text('–', textAlign: TextAlign.center, style: TextStyle(color: BvtColors.muted))
                : Text(t, textAlign: center ? TextAlign.center : TextAlign.start, style: TextStyle(fontWeight: head ? FontWeight.w800 : FontWeight.w500, fontSize: 12.5)),
      );

  @override
  Widget build(BuildContext context) {
    final rows = <List<String>>[
      ['', 'Per-Book', 'Language', 'Global'],
      ['Titles', '1', 'All in 1 language', 'All, 16 languages'],
      ['In-app reader', '✓', '✓', '✓'],
      ['Offline chapters', '✓', '✓', '✓'],
      ['New releases', '–', '✓', '✓ early access'],
      ['Priority support', '–', '–', '✓'],
      ['Gifting', '✓', '✓', '✓'],
      ['Devices', '2', '3', '3'],
    ];
    return Card(
      child: Table(
        columnWidths: const {0: FlexColumnWidth(1.3)},
        border: const TableBorder(horizontalInside: BorderSide(color: Color(0xFFEBD9BC))),
        children: [for (var i = 0; i < rows.length; i++) TableRow(decoration: i == 0 ? const BoxDecoration(color: BvtColors.sand) : null, children: [for (var j = 0; j < 4; j++) _c(rows[i][j], head: i == 0 || j == 0, center: j != 0)])],
      ),
    );
  }
}

class SubscribeCheckout extends StatefulWidget {
  final Plan plan;
  final bool yearly, gift;
  final Book? book;
  final String lang, giftTo;
  const SubscribeCheckout({super.key, required this.plan, required this.yearly, this.book, required this.lang, this.gift = false, this.giftTo = ''});
  @override
  State<SubscribeCheckout> createState() => _SubscribeCheckoutState();
}

class _SubscribeCheckoutState extends State<SubscribeCheckout> {
  String region = 'India';
  String method = 'upi';
  bool busy = false, failSim = false;
  final _coupon = TextEditingController();
  int discount = 0;

  int get price => widget.yearly ? widget.plan.yearly : widget.plan.monthly;

  @override
  Widget build(BuildContext context) {
    final intl = region != 'India';
    final methods = intl
        ? [('card', 'Card (Stripe Billing)', Icons.credit_card), ('apple', 'Apple Pay', Icons.apple), ('paypal', 'PayPal', Icons.account_balance_wallet_outlined)]
        : [('upi', 'UPI AutoPay (Razorpay Subscriptions)', Icons.qr_code_2), ('card', 'Credit / Debit card', Icons.credit_card), ('nb', 'Net banking e-mandate', Icons.account_balance), ('apple', 'Apple Pay', Icons.apple)];
    final gst = ((price - discount) * 18 / 118).round();
    final trialDays = app.trialOverride > 0 ? app.trialOverride : widget.plan.trialDays;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm subscription')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.plan.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              Text(widget.plan.kind == 'book' ? (widget.book?.title ?? '') : widget.plan.kind == 'language' ? '${langOf(widget.lang).name} — all books' : 'All books · all languages', style: const TextStyle(color: BvtColors.muted)),
              if (widget.gift) Padding(padding: const EdgeInsets.only(top: 6), child: Pill('Gift for ${widget.giftTo}', color: BvtColors.maroon, icon: Icons.card_giftcard)),
              const Divider(height: 24),
              KeyVal('Billing', widget.yearly ? 'Yearly' : 'Monthly'),
              KeyVal('Price', inr(price)),
              if (discount > 0) KeyVal('Coupon', '-${inr(discount)}', color: BvtColors.green),
              KeyVal('Includes GST (18%)', inr(gst)),
              if (!widget.gift) KeyVal('Free trial', '$trialDays days — ${inr(0)} today', color: BvtColors.green),
              const Divider(height: 24),
              KeyVal(widget.gift ? 'Pay now' : 'Due today', inr(widget.gift ? price - discount : 0), bold: true),
              if (!widget.gift) Text('Then ${inr(price - discount)}/${widget.yearly ? 'year' : 'month'} from ${dateFmt(DateTime.now().add(Duration(days: trialDays)))}. Cancel any time before then.', style: const TextStyle(fontSize: 12, color: BvtColors.muted)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _coupon, decoration: const InputDecoration(hintText: 'Coupon code (try BVT10)', prefixIcon: Icon(Icons.sell_outlined)))),
          const SizedBox(width: 10),
          OutlinedButton(onPressed: () {
            final c = _coupon.text.trim().toUpperCase();
            if (promoCodes.containsKey(c)) { setState(() => discount = (price * promoCodes[c]!.$2).round()); toast(context, 'Coupon applied', icon: Icons.check); } else { toast(context, 'Invalid code', icon: Icons.error_outline); }
          }, child: const Text('Apply')),
        ]),
        const SectionHeader('Billing region'),
        SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'India', label: Text('India · Razorpay')), ButtonSegment(value: 'Intl', label: Text('International · Stripe'))],
          selected: {region},
          onSelectionChanged: (s) => setState(() { region = s.first; method = region == 'India' ? 'upi' : 'card'; }),
        ),
        const SectionHeader('Payment method'),
        for (final m in methods)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(m.$3, color: BvtColors.deepSaffron),
              title: Text(m.$2),
              trailing: Icon(method == m.$1 ? Icons.radio_button_checked : Icons.radio_button_off, color: BvtColors.saffron),
              onTap: () => setState(() => method = m.$1),
            ),
          ),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Demo: simulate payment failure'), subtitle: const Text('Shows grace-period and retry handling'), value: failSim, onChanged: (v) => setState(() => failSim = v)),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: busy ? null : _pay,
          child: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(method == 'apple' ? ' Pay with Apple Pay' : (widget.gift ? 'Pay ${inr(price - discount)} & send gift' : 'Start $trialDays-day free trial')),
        ),
        const SizedBox(height: 8),
        const Text('No raw card data is stored on BVT servers — gateway tokenisation only (PCI-DSS).', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: BvtColors.muted)),
      ]),
    );
  }

  Future<void> _pay() async {
    setState(() => busy = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => busy = false);
    if (failSim) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.error_outline, color: BvtColors.red, size: 44),
          title: const Text('Payment failed'),
          content: const Text('Your bank declined the mandate. Nothing was charged.\n\nFor renewals we keep access for a 7-day grace period and retry automatically.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Change method')), FilledButton(onPressed: () { Navigator.pop(ctx); setState(() => failSim = false); _pay(); }, child: const Text('Retry'))],
        ),
      );
      return;
    }
    final s = app.subscribe(widget.plan, yearly: widget.yearly, bookId: widget.book?.id, langCode: widget.lang, gift: widget.gift, giftTo: widget.giftTo);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SubscribeSuccess(s, widget.gift, widget.giftTo, widget.book)));
  }
}

class SubscribeSuccess extends StatelessWidget {
  final Subscription sub;
  final bool gift;
  final String giftTo;
  final Book? book;
  const SubscribeSuccess(this.sub, this.gift, this.giftTo, this.book, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 600), curve: Curves.elasticOut, builder: (_, v, c) => Transform.scale(scale: v, child: c), child: const Icon(Icons.check_circle, size: 96, color: BvtColors.green)),
              const SizedBox(height: 16),
              Text(gift ? 'Gift sent!' : (sub.status == 'trial' ? 'Your free trial has started' : 'Subscription active'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(gift ? 'We notified $giftTo on WhatsApp and email.' : '${sub.title} — renews ${dateFmt(sub.renews)}.', textAlign: TextAlign.center, style: const TextStyle(color: BvtColors.muted)),
              const SizedBox(height: 14),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFE7F8EE), borderRadius: BorderRadius.circular(12)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.chat, color: BvtColors.whatsapp, size: 18), SizedBox(width: 8), Text('Confirmation sent on WhatsApp')])),
              const SizedBox(height: 28),
              if (!gift)
                FilledButton.icon(
                  onPressed: () {
                    final b = book ?? allBooks.firstWhere((x) => app.hasAccess(x), orElse: () => allBooks.first);
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ReaderScreen(b)));
                  },
                  icon: const Icon(Icons.auto_stories),
                  label: const Text('Start reading'),
                ),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text('Back to home')),
            ]),
          ),
        ),
      );
}

class ManageSubscriptionsScreen extends StatelessWidget {
  const ManageSubscriptionsScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: Text(app.t('subscriptions'))),
          body: app.subscriptions.isEmpty
              ? EmptyState(Icons.workspace_premium, 'No active subscriptions', 'Start a free trial to read unlimited in the BVT Reader.', action: 'View plans', onAction: () => push(context, const PlansScreen()))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  for (final s in app.subscriptions) _SubCard(s),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(onPressed: () => push(context, const PlansScreen()), icon: const Icon(Icons.add), label: const Text('Add another plan')),
                ]),
        ),
      );
}

class _SubCard extends StatelessWidget {
  final Subscription s;
  const _SubCard(this.s);
  @override
  Widget build(BuildContext context) {
    final p = planById(s.planId);
    final (col, label) = switch (s.status) {
      'trial' => (BvtColors.deepSaffron, 'Free trial'),
      'active' => (BvtColors.green, 'Active'),
      'grace' => (const Color(0xFFE65100), 'Payment failed — grace period'),
      'paused' => (BvtColors.muted, 'Paused'),
      _ => (BvtColors.red, 'Cancelled'),
    };
    final price = s.yearly ? p.yearly : p.monthly;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))), Pill(label, color: col)]),
            Text('${p.name} · ${inr(price)}/${s.yearly ? 'yr' : 'mo'} · ${s.id}', style: const TextStyle(color: BvtColors.muted, fontSize: 12.5)),
            const SizedBox(height: 8),
            if (s.status == 'grace')
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)), child: const Text('We could not renew. Access continues for 7 days while we retry. Update your payment method to avoid suspension.', style: TextStyle(fontSize: 12.5))),
            if (s.status != 'cancelled') Text(s.status == 'paused' ? 'Paused — access suspended' : '${s.status == 'trial' ? 'Trial ends / first charge' : 'Renews'} ${dateFmt(s.renews)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              if (s.status == 'grace') FilledButton.tonal(onPressed: () { app.setSubStatus(s, 'active'); toast(context, 'Payment retried successfully', icon: Icons.check_circle); }, child: const Text('Retry payment')),
              if (s.status == 'active' || s.status == 'trial') ...[
                OutlinedButton(onPressed: () { app.changePlan(s, !s.yearly); toast(context, s.yearly ? 'Switched to yearly billing' : 'Switched to monthly billing', icon: Icons.swap_horiz); }, child: Text(s.yearly ? 'Downgrade to monthly' : 'Upgrade to yearly')),
                OutlinedButton(onPressed: () { app.setSubStatus(s, 'paused'); toast(context, 'Subscription paused', icon: Icons.pause_circle); }, child: const Text('Pause')),
              ],
              if (s.status == 'paused') FilledButton.tonal(onPressed: () => app.setSubStatus(s, 'active'), child: const Text('Resume')),
              if (s.status != 'cancelled') TextButton(onPressed: () => _cancel(context), child: const Text('Cancel', style: TextStyle(color: BvtColors.red))),
              if (s.status == 'active') TextButton(onPressed: () { app.setSubStatus(s, 'grace'); app.notify('Payment failed', '${s.title}: renewal failed. 7-day grace period started.', 'WhatsApp'); }, child: const Text('Demo: fail renewal', style: TextStyle(fontSize: 12))),
              if (s.status == 'cancelled') FilledButton.tonal(onPressed: () => push(context, const PlansScreen()), child: const Text('Resubscribe')),
            ]),
          ]),
        ),
      ),
    );
  }

  void _cancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel subscription?'),
        content: Text('You will keep access until ${dateFmt(s.renews)}. We will remind you before it ends.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep')), FilledButton(style: FilledButton.styleFrom(backgroundColor: BvtColors.red), onPressed: () { app.setSubStatus(s, 'cancelled'); Navigator.pop(ctx); toast(context, 'Subscription cancelled', icon: Icons.cancel); }, child: const Text('Cancel plan'))],
      ),
    );
  }
}
