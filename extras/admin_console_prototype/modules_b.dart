import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/search.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart' show dateFmt;
import 'admin_state.dart';
import 'admin_widgets.dart';

// ============================================================ WhatsApp campaigns
class WhatsAppModule extends StatefulWidget {
  const WhatsAppModule({super.key});
  @override
  State<WhatsAppModule> createState() => _WhatsAppModuleState();
}

class _WhatsAppModuleState extends State<WhatsAppModule> {
  late String template = adm.templates.firstWhere((t) => t.category == 'MARKETING').name;
  String segment = 'All opted-in · India';
  bool schedule = false;
  DateTime when = DateTime.now().add(const Duration(days: 1));
  final _name = TextEditingController(text: 'Diwali special');
  static const segments = ['All opted-in · India', 'All opted-in · International', 'Subscribers only', 'BMM members', 'Youth readers', 'Wishlist alerts'];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: adm,
        builder: (context, _) {
          final t = adm.templates.firstWhere((t) => t.name == template);
          final audience = switch (segment) { 'All opted-in · India' => 11840, 'All opted-in · International' => 1620, 'Subscribers only' => 2310, 'BMM members' => 410, 'Youth readers' => 3100, _ => 212 };
          return AdminPage(
            module: 'whatsapp',
            title: 'WhatsApp campaigns',
            subtitle: 'Meta Cloud API · template-only business-initiated messages · opt-in/out compliance',
            children: [
              Wrap(spacing: 12, runSpacing: 12, children: const [
                StatTile('Opted-in contacts', '13,460', Icons.how_to_reg, color: BvtColors.whatsapp),
                StatTile('Opt-outs (30d)', '84', Icons.person_off, color: BvtColors.red),
                StatTile('Avg delivery rate', '98.1%', Icons.done_all, color: BvtColors.green),
                StatTile('Avg read rate', '71.4%', Icons.visibility, color: Color(0xFF3B6EA5)),
              ]),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, c) {
                final compose = Panel(
                  title: 'Compose campaign',
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    TextField(controller: _name, decoration: const InputDecoration(labelText: 'Campaign name')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(initialValue: template, decoration: const InputDecoration(labelText: 'Approved template'), items: [for (final x in adm.templates.where((x) => x.status == 'APPROVED')) DropdownMenuItem(value: x.name, child: Text('${x.name} · ${x.category}'))], onChanged: (v) => setState(() => template = v!)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(initialValue: segment, decoration: const InputDecoration(labelText: 'Audience segment'), items: [for (final s in segments) DropdownMenuItem(value: s, child: Text(s))], onChanged: (v) => setState(() => segment = v!)),
                    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Schedule for later'), subtitle: Text(schedule ? dayTime(when) : 'Send immediately (rate-limited per Meta policy)'), value: schedule, onChanged: (v) => setState(() => schedule = v)),
                    if (schedule) OutlinedButton.icon(onPressed: () async { final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)), initialDate: when); if (d != null) setState(() => when = d); }, icon: const Icon(Icons.event), label: const Text('Pick date')),
                    const SizedBox(height: 10),
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFDCF8C6), borderRadius: BorderRadius.circular(10)), child: Text(t.body.replaceAll('{{1}}', '20%').replaceAll('{{2}}', 'all Gītā titles').replaceAll('{{3}}', 'bvks.in/x'), style: const TextStyle(fontSize: 13))),
                    const SizedBox(height: 10),
                    Text('Audience: ~$audience contacts · opt-out list excluded automatically', style: const TextStyle(fontSize: 12, color: BvtColors.muted)),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () {
                        if (!adm.act(context, 'whatsapp', '${schedule ? 'Scheduled' : 'Sent'} campaign · ${_name.text}', after: '$audience recipients')) return;
                        final cp = Campaign(_name.text, template, segment, schedule ? 'Scheduled' : 'Sending', schedule ? when : DateTime.now(), schedule ? 0 : audience, 0, 0);
                        adm.campaigns.insert(0, cp);
                        adm.changed();
                        if (!schedule) {
                          Future.delayed(const Duration(milliseconds: 1500), () { cp.delivered = (audience * 0.97).round(); cp.read = (audience * 0.4).round(); cp.status = 'Sent'; adm.changed(); });
                        }
                        adminToast(context, schedule ? 'Campaign scheduled' : 'Campaign queued — sending in throttled batches');
                      },
                      icon: const Icon(Icons.send),
                      label: Text(schedule ? 'Schedule campaign' : 'Send campaign'),
                    ),
                  ]),
                );
                final tpls = Panel(
                  title: 'Message templates',
                  actions: [TextButton.icon(onPressed: () => _newTemplate(context), icon: const Icon(Icons.add), label: const Text('New'))],
                  child: Column(children: [for (final x in adm.templates) ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(x.name, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(x.body, maxLines: 2, overflow: TextOverflow.ellipsis), trailing: Pill(x.status, color: x.status == 'APPROVED' ? BvtColors.green : const Color(0xFFE65100)))]),
                );
                return c.maxWidth > 900 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: compose), const SizedBox(width: 16), Expanded(child: tpls)]) : Column(children: [compose, tpls]);
              }),
              Panel(
                title: 'Campaign performance',
                child: DataGrid(['Campaign', 'Segment', 'When', 'Status', 'Sent', 'Delivered', 'Read'], [
                  for (final c in adm.campaigns)
                    [Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)), Text(c.segment, style: const TextStyle(fontSize: 12)), Text(shortDate(c.when)), Pill(c.status, color: c.status == 'Sent' ? BvtColors.green : BvtColors.deepSaffron), Text('${c.sent}'), Text(c.sent == 0 ? '—' : '${c.delivered} (${(c.delivered * 100 / c.sent).round()}%)'), Text(c.sent == 0 ? '—' : '${c.read} (${(c.read * 100 / c.sent).round()}%)')],
                ]),
              ),
              Panel(
                title: 'Inbound queue · human hand-off',
                child: Column(children: [
                  for (final q in [('+91 98765 43210', 'Refund for damaged parcel BVT-100311', '4 min ago'), ('+44 7700 900123', 'International shipping to UK', '12 min ago'), ('+91 90040 11223', 'Cannot access reader after payment', '31 min ago')])
                    ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const CircleAvatar(radius: 16, backgroundColor: Color(0xFFE7F8EE), child: Icon(Icons.chat, size: 16, color: BvtColors.whatsapp)), title: Text(q.$2), subtitle: Text('${q.$1} · ${q.$3} · AI context attached'), trailing: OutlinedButton(onPressed: () => adminToast(context, 'Opened chat with ${q.$1} (demo)'), child: const Text('Take over'))),
                ]),
              ),
            ],
          );
        },
      );

  void _newTemplate(BuildContext context) {
    final n = TextEditingController(), b = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit template to Meta'),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: n, decoration: const InputDecoration(labelText: 'Template name (snake_case)')), const SizedBox(height: 10), TextField(controller: b, maxLines: 3, decoration: const InputDecoration(labelText: 'Body with {{1}} variables'))])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () { if (!adm.act(context, 'whatsapp', 'Template submitted · ${n.text}')) return; adm.templates.add(WaTemplate(n.text.isEmpty ? 'new_template' : n.text, 'MARKETING', 'PENDING', b.text)); adm.changed(); Navigator.pop(ctx); }, child: const Text('Submit for approval'))],
      ),
    );
  }
}

// ============================================================ Chatbot KB
class ChatbotKbModule extends StatefulWidget {
  const ChatbotKbModule({super.key});
  @override
  State<ChatbotKbModule> createState() => _ChatbotKbModuleState();
}

class _ChatbotKbModuleState extends State<ChatbotKbModule> {
  final _test = TextEditingController();
  String? answer;
  @override
  void dispose() {
    _test.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([adm, app]),
        builder: (context, _) => AdminPage(
          module: 'chatbot',
          title: 'Chatbot knowledge base',
          subtitle: 'FAQs, policies and catalog Q&A used by the RAG chatbot · changes apply instantly, no code deploy',
          actions: [FilledButton.icon(onPressed: () => _edit(context, null), icon: const Icon(Icons.add), label: const Text('Add entry'))],
          children: [
            Panel(
              title: 'Entries (${app.kb.length})',
              child: Column(children: [
                for (final e in app.kb)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.q, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(e.a, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(context, e)), IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { if (adm.act(context, 'chatbot', 'Deleted KB entry · ${e.q}')) { app.kb.remove(e); adm.changed(); } })]),
                  ),
              ]),
            ),
            Panel(
              title: 'Test the bot',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: TextField(controller: _test, decoration: const InputDecoration(hintText: 'Ask a question, e.g. “what is your return policy?”'), onSubmitted: (_) => _ask())),
                  const SizedBox(width: 10),
                  FilledButton(onPressed: _ask, child: const Text('Ask')),
                ]),
                if (answer != null) Padding(padding: const EdgeInsets.only(top: 10), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFDCF8C6), borderRadius: BorderRadius.circular(10)), child: Text(answer!))),
                const SizedBox(height: 8),
                const Text('LLM: GPT-4-class model · retrieval over this knowledge base + catalog · fallback to human agent with full chat context.', style: TextStyle(fontSize: 12, color: BvtColors.muted)),
              ]),
            ),
          ],
        ),
      );

  void _ask() {
    final t = _test.text.toLowerCase();
    KbEntry? hit;
    for (final e in app.kb) {
      if (e.q.toLowerCase().split(' ').any((w) => w.length > 2 && t.contains(w))) hit = e;
    }
    setState(() => answer = hit?.a ?? 'I am not sure — escalating to a human agent.');
  }

  void _edit(BuildContext context, KbEntry? e) {
    final q = TextEditingController(text: e?.q ?? ''), a = TextEditingController(text: e?.a ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(e == null ? 'New KB entry' : 'Edit entry'),
        content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: q, decoration: const InputDecoration(labelText: 'Topic / question keywords')), const SizedBox(height: 10), TextField(controller: a, maxLines: 4, decoration: const InputDecoration(labelText: 'Answer'))])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            if (!adm.act(context, 'chatbot', e == null ? 'Added KB entry · ${q.text}' : 'Edited KB entry · ${q.text}', before: e?.a ?? '—', after: a.text)) return;
            if (e == null) { app.kb.add(KbEntry(q.text, a.text)); } else { e.q = q.text; e.a = a.text; }
            adm.changed();
            Navigator.pop(ctx);
          }, child: const Text('Save')),
        ],
      ),
    );
  }
}

// ============================================================ CMS
class CmsModule extends StatefulWidget {
  const CmsModule({super.key});
  @override
  State<CmsModule> createState() => _CmsModuleState();
}

class _CmsModuleState extends State<CmsModule> {
  static const templates = [('Blog Post', Icons.edit_note), ('Article', Icons.article_outlined), ('Static Info Page', Icons.info_outline), ('FAQ Page', Icons.help_outline), ('Landing Page', Icons.rocket_launch_outlined)];
  String tpl = 'Blog Post';
  final _title = TextEditingController(text: 'Why Ekādaśī Matters');
  final _body = TextEditingController(text: 'Write your content here. Use the blocks below to add images and related products — no coding required.');
  bool related = true, publish = true;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([adm, app]),
        builder: (context, _) => AdminPage(
          module: 'cms',
          title: 'CMS page builder',
          subtitle: 'Create blog posts, articles and static pages from templates — no code',
          children: [
            Panel(
              title: 'Pages',
              child: Column(children: [
                for (final p in app.cmsPages)
                  ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.description_outlined), title: Text(p.$1, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(p.$2), trailing: Pill(p.$3, color: p.$3 == 'Published' ? BvtColors.green : BvtColors.muted)),
                for (final a in app.blog.take(app.blog.length - articles.length)) ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.article_outlined), title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Blog / Article'), trailing: const Pill('Published', color: BvtColors.green)),
              ]),
            ),
            Panel(
              title: 'New page',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('1. Choose a template', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final t in templates)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => tpl = t.$1),
                      child: Container(
                        width: 128,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: tpl == t.$1 ? BvtColors.saffron : const Color(0xFFEBD9BC), width: tpl == t.$1 ? 2 : 1), color: tpl == t.$1 ? BvtColors.saffron.withValues(alpha: 0.08) : null),
                        child: Column(children: [Icon(t.$2, size: 30, color: BvtColors.deepSaffron), const SizedBox(height: 6), Text(t.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))]),
                      ),
                    ),
                ]),
                const SizedBox(height: 16),
                const Text('2. Add content', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(controller: _title, decoration: const InputDecoration(labelText: 'Page title'), onChanged: (_) => setState(() {})),
                const SizedBox(height: 10),
                TextField(controller: _body, maxLines: 5, decoration: const InputDecoration(labelText: 'Body (rich text)'), onChanged: (_) => setState(() {})),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Show related books widget'), value: related, onChanged: (v) => setState(() => related = v)),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Publish immediately'), subtitle: const Text('Otherwise saved as draft'), value: publish, onChanged: (v) => setState(() => publish = v)),
                const SizedBox(height: 8),
                const Text('Preview', style: TextStyle(fontWeight: FontWeight.w700)),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: BvtColors.sand, borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Pill(tpl), const SizedBox(height: 6), Text(_title.text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), const SizedBox(height: 6), Text(_body.text), if (related) const Padding(padding: EdgeInsets.only(top: 8), child: Text('[ Related books widget ]', style: TextStyle(color: BvtColors.muted)))]),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    if (!adm.act(context, 'cms', '${publish ? 'Published' : 'Saved draft'} $tpl · ${_title.text}', after: tpl)) return;
                    if (tpl == 'Blog Post' || tpl == 'Article') {
                      if (publish) app.blog.insert(0, Article('cms${app.blog.length}', _title.text, _body.text.length > 100 ? _body.text.substring(0, 100) : _body.text, adm.userName, dateFmt(DateTime.now()), '3 min', [_body.text], related ? ['beginners-guide'] : [], BvtColors.deepSaffron));
                    } else {
                      app.cmsPages.insert(0, (_title.text, tpl, publish ? 'Published' : 'Draft'));
                    }
                    app.update(() {});
                    adm.changed();
                    adminToast(context, publish ? 'Published — live on the storefront (Articles / Browse → More)' : 'Saved as draft');
                  },
                  icon: const Icon(Icons.publish),
                  label: Text(publish ? 'Publish page' : 'Save draft'),
                ),
              ]),
            ),
          ],
        ),
      );
}

// ============================================================ Banners
class BannersModule extends StatefulWidget {
  const BannersModule({super.key});
  @override
  State<BannersModule> createState() => _BannersModuleState();
}

class _BannersModuleState extends State<BannersModule> {
  final Set<PromoBanner> ab = {};
  static const palette = [Color(0xFFB5541C), Color(0xFF7A2E0E), Color(0xFF3B6EA5), Color(0xFF2E7D32), Color(0xFF7B3FA0), Color(0xFFC9A227)];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([adm, app]),
        builder: (context, _) => AdminPage(
          module: 'banners',
          title: 'Promotional banners',
          subtitle: 'Homepage hero banners — add, edit, schedule and remove without code. Drag to reorder.',
          actions: [FilledButton.icon(onPressed: () => _edit(context, null), icon: const Icon(Icons.add), label: const Text('Add banner'))],
          children: [
            Panel(
              child: ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (o, n) {
                  if (!adm.act(context, 'banners', 'Reordered banners')) return;
                  if (n > o) n--;
                  final b = app.banners.removeAt(o);
                  app.banners.insert(n, b);
                  app.update(() {});
                },
                children: [
                  for (final b in app.banners)
                    ListTile(
                      key: ObjectKey(b),
                      contentPadding: EdgeInsets.zero,
                      leading: Container(width: 70, height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: b.color), child: const Icon(Icons.spa, color: Colors.white54)),
                      title: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Wrap(spacing: 6, children: [Text(b.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis), Pill(b.schedule, color: BvtColors.muted, icon: Icons.schedule), if (b.appExclusive) const Pill('App exclusive', color: BvtColors.gold), if (ab.contains(b)) const Pill('A/B test', color: Color(0xFF3B6EA5))]),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Tooltip(message: 'A/B testing', child: IconButton(icon: Icon(Icons.science_outlined, color: ab.contains(b) ? const Color(0xFF3B6EA5) : null), onPressed: () => setState(() => ab.contains(b) ? ab.remove(b) : ab.add(b)))),
                        Switch(value: b.active, onChanged: (v) { if (adm.act(context, 'banners', '${v ? 'Activated' : 'Deactivated'} banner · ${b.title}')) { b.active = v; app.update(() {}); } }),
                        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(context, b)),
                        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { if (adm.act(context, 'banners', 'Removed banner · ${b.title}')) { app.banners.remove(b); app.update(() {}); } }),
                        const SizedBox(width: 24),
                      ]),
                    ),
                ],
              ),
            ),
            const Text('Changes appear immediately in the storefront hero carousel (Home tab).', style: TextStyle(color: BvtColors.muted, fontSize: 12.5)),
          ],
        ),
      );

  void _edit(BuildContext context, PromoBanner? b) {
    final t = TextEditingController(text: b?.title ?? ''), s = TextEditingController(text: b?.subtitle ?? ''), cta = TextEditingController(text: b?.cta ?? 'Shop now'), sched = TextEditingController(text: b?.schedule ?? 'Always on');
    var col = b?.color ?? palette.first;
    var excl = b?.appExclusive ?? false;
    var target = b?.target ?? 'bulk';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(b == null ? 'New banner' : 'Edit banner'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: t, decoration: const InputDecoration(labelText: 'Headline')),
                const SizedBox(height: 10),
                TextField(controller: s, decoration: const InputDecoration(labelText: 'Subtitle')),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: TextField(controller: cta, decoration: const InputDecoration(labelText: 'Button text'))), const SizedBox(width: 10), Expanded(child: TextField(controller: sched, decoration: const InputDecoration(labelText: 'Schedule')))]),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(initialValue: ['plans', 'bulk', 'book:ramayana-en', 'book:gita-youth-en'].contains(target) ? target : 'bulk', decoration: const InputDecoration(labelText: 'Links to'), items: const [DropdownMenuItem(value: 'plans', child: Text('Subscription plans')), DropdownMenuItem(value: 'bulk', child: Text('Bulk order page')), DropdownMenuItem(value: 'book:ramayana-en', child: Text('Rāmāyaṇa (EN) product page')), DropdownMenuItem(value: 'book:gita-youth-en', child: Text('Gītā for Youth (EN) product page'))], onChanged: (v) => set(() => target = v!)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: [for (final c in palette) GestureDetector(onTap: () => set(() => col = c), child: CircleAvatar(radius: 14, backgroundColor: c, child: col == c ? const Icon(Icons.check, size: 16, color: Colors.white) : null))]),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('App-exclusive offer / early access'), value: excl, onChanged: (v) => set(() => excl = v)),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () {
              if (!adm.act(context, 'banners', b == null ? 'Created banner · ${t.text}' : 'Edited banner · ${t.text}', before: b?.title ?? '—', after: t.text)) return;
              if (b == null) {
                app.banners.add(PromoBanner(t.text.isEmpty ? 'New banner' : t.text, s.text, cta.text, target, col, appExclusive: excl, schedule: sched.text));
              } else {
                b..title = t.text..subtitle = s.text..cta = cta.text..color = col..appExclusive = excl..schedule = sched.text..target = target;
              }
              app.update(() {});
              Navigator.pop(ctx);
            }, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

// ============================================================ Navigation
class NavigationModule extends StatelessWidget {
  const NavigationModule({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([adm, app]),
        builder: (context, _) => AdminPage(
          module: 'navigation',
          title: 'Navigation menu',
          subtitle: 'Add or remove main-menu items as new pages are created · reflected on the storefront Home tab',
          actions: [FilledButton.icon(onPressed: () => _add(context), icon: const Icon(Icons.add), label: const Text('Add item'))],
          children: [
            Panel(
              title: 'Live preview',
              child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final n in app.navItems) Padding(padding: const EdgeInsets.only(right: 8), child: Chip(label: Text(n)))])),
            ),
            Panel(
              child: ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (o, n) {
                  if (!adm.act(context, 'navigation', 'Reordered navigation')) return;
                  if (n > o) n--;
                  app.navItems.insert(n, app.navItems.removeAt(o));
                  app.update(() {});
                },
                children: [
                  for (final n in app.navItems)
                    ListTile(key: ValueKey(n), contentPadding: EdgeInsets.zero, leading: const Icon(Icons.drag_indicator), title: Text(n), trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { if (adm.act(context, 'navigation', 'Removed menu item · $n')) { app.navItems.remove(n); app.update(() {}); } })),
                ],
              ),
            ),
          ],
        ),
      );

  void _add(BuildContext context) {
    final c = TextEditingController();
    final pages = app.cmsPages.where((p) => p.$3 == 'Published').map((p) => p.$1).where((p) => !app.navItems.contains(p)).toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add menu item'),
        content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: c, decoration: const InputDecoration(labelText: 'Label')),
          if (pages.isNotEmpty) ...[const SizedBox(height: 12), const Text('Or pick a published CMS page', style: TextStyle(fontSize: 12.5, color: BvtColors.muted)), Wrap(spacing: 6, children: [for (final p in pages) ActionChip(label: Text(p), onPressed: () => c.text = p)])],
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () { if (c.text.isEmpty || !adm.act(context, 'navigation', 'Added menu item · ${c.text}')) return; app.navItems.add(c.text); app.update(() {}); Navigator.pop(ctx); }, child: const Text('Add'))],
      ),
    );
  }
}

// ============================================================ Search & merchandising
class SearchModule extends StatefulWidget {
  const SearchModule({super.key});
  @override
  State<SearchModule> createState() => _SearchModuleState();
}

class _SearchModuleState extends State<SearchModule> {
  final _k = TextEditingController(), _v = TextEditingController();
  String pinQ = '';
  @override
  void dispose() {
    _k.dispose();
    _v.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([adm, app]),
        builder: (context, _) {
          final pinCands = pinQ.length < 2 ? <Book>[] : searchBooks(pinQ).take(5).toList();
          return AdminPage(
            module: 'search',
            title: 'Search & merchandising',
            subtitle: 'Elasticsearch / Typesense · multilingual tokenisation · synonyms · sponsored pinning',
            children: [
              Panel(
                title: 'Zero-result searches (catalog gap analysis)',
                child: app.zeroResults.isEmpty
                    ? const Text('No zero-result queries logged yet. Try searching for something unusual in the app.')
                    : DataGrid(['Query', 'When', ''], [for (final z in app.zeroResults.take(15)) [Text(z.$1, style: const TextStyle(fontWeight: FontWeight.w700)), Text(dayTime(z.$2)), TextButton(onPressed: () { if (adm.act(context, 'search', 'Added to catalog-gap list · ${z.$1}')) adminToast(context, '“${z.$1}” added to the catalog gap backlog'); }, child: const Text('Add to gap list'))]]),
              ),
              Panel(
                title: 'Synonyms (${synonyms.length})',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final e in synonyms.entries) InputChip(label: Text('${e.key} → ${e.value}', style: const TextStyle(fontSize: 12)), onDeleted: () { if (adm.act(context, 'search', 'Removed synonym ${e.key}')) { synonyms.remove(e.key); adm.changed(); } })]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextField(controller: _k, decoration: const InputDecoration(labelText: 'When user types', isDense: true))),
                    const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.arrow_forward)),
                    Expanded(child: TextField(controller: _v, decoration: const InputDecoration(labelText: 'Treat as', isDense: true))),
                    const SizedBox(width: 10),
                    FilledButton(onPressed: () { if (_k.text.isEmpty || _v.text.isEmpty || !adm.act(context, 'search', 'Added synonym ${_k.text} → ${_v.text}')) return; synonyms[_k.text.toLowerCase()] = _v.text.toLowerCase(); _k.clear(); _v.clear(); adm.changed(); }, child: const Text('Add')),
                  ]),
                  const SizedBox(height: 6),
                  const Text('Try: add “gitaji → gita”, then search “gitaji” in the app.', style: TextStyle(fontSize: 12, color: BvtColors.muted)),
                ]),
              ),
              Panel(
                title: 'Sponsored / pinned products',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 6, children: [for (final id in app.pinned) InputChip(label: Text(maybeBook(id)?.title ?? id, style: const TextStyle(fontSize: 12)), onDeleted: () { if (adm.act(context, 'search', 'Unpinned $id')) { app.pinned.remove(id); app.update(() {}); } })]),
                  const SizedBox(height: 10),
                  TextField(decoration: const InputDecoration(hintText: 'Find a product to pin…', prefixIcon: Icon(Icons.push_pin_outlined), isDense: true), onChanged: (v) => setState(() => pinQ = v)),
                  for (final b in pinCands) ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(b.title), subtitle: Text(langOf(b.language).name), trailing: FilledButton.tonal(onPressed: () { if (adm.act(context, 'search', 'Pinned ${b.id}')) { app.pinned.add(b.id); app.update(() {}); } }, child: const Text('Pin'))),
                ]),
              ),
            ],
          );
        },
      );
}
