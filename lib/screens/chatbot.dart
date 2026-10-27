import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/recs.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _c = TextEditingController();
  final _sc = ScrollController();
  bool typing = false, hindi = false, human = false;

  @override
  void initState() {
    super.initState();
    if (app.chat.isEmpty) {
      app.chat.add(WaMessage('Hare Kṛṣṇa 🙏 I am the BVT Assistant (AI). I can help with order status, book recommendations, shipping & returns. Ask in English or हिन्दी.'));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _sc.dispose();
    super.dispose();
  }

  void _scroll() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sc.hasClients) _sc.animateTo(_sc.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });

  bool _devanagari(String s) => RegExp(r'[ऀ-ॿ]').hasMatch(s);

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    _c.clear();
    setState(() { app.chat.add(WaMessage(t, fromBot: false)); typing = true; });
    _scroll();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final hi = hindi || _devanagari(t);
    final reply = _answer(t.toLowerCase(), hi);
    setState(() { app.chat.add(reply); typing = false; });
    _scroll();
    if (reply.text.startsWith('__HUMAN__')) {
      app.chat.removeLast();
      setState(() { app.chat.add(WaMessage(hi ? 'मैं आपको मानव सहायक से जोड़ रहा हूँ — पूरी चैट उन्हें दिख रही है…' : 'Connecting you to a human agent — they can see this full chat so you will not need to repeat yourself…')); human = true; typing = true; });
      _scroll();
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      setState(() { app.chat.add(WaMessage(hi ? 'नमस्ते, मैं मीरा, BVT सहायता टीम से। मैंने आपकी चैट पढ़ ली है — बताइए मैं कैसे मदद करूँ?' : 'Hi, this is Meera from the BVT support team. I have read your conversation so far — how can I help?', human: true)); typing = false; });
      _scroll();
    }
  }

  WaMessage _answer(String t, bool hi) {
    bool has(List<String> k) => k.any(t.contains);
    if (has(['human', 'agent', 'person', 'talk to', 'मानव', 'एजेंट', 'इंसान'])) return WaMessage('__HUMAN__');
    if (has(['hello', 'hi ', 'hare', 'namaste', 'नमस्ते', 'हरे']) && t.length < 20) return WaMessage(hi ? 'हरे कृष्ण! 🙏 आज मैं आपकी क्या सहायता कर सकता हूँ?' : 'Hare Kṛṣṇa! 🙏 How can I help you today?');
    if (has(['order', 'track', 'status', 'ऑर्डर', 'ट्रैक', 'आर्डर'])) {
      if (!app.loggedIn) return WaMessage(hi ? 'ऑर्डर देखने के लिए कृपया पहले साइन इन करें (Account टैब)।' : 'Please sign in first (Account tab) so I can look up your orders.');
      final o = app.orders.where((o) => !o.isDonation).toList();
      if (o.isEmpty) return WaMessage(hi ? 'आपका कोई ऑर्डर नहीं मिला।' : 'I could not find any orders on your account.');
      final x = o.first;
      return WaMessage(hi ? 'आपका ऑर्डर ${x.id}: ${x.statusLabel}। ${x.courier} AWB ${x.awb}। कुल ${inr(x.total)}।' : 'Your latest order ${x.id} is “${x.statusLabel}”. ${x.courier} AWB ${x.awb}. Total ${inr(x.total)}. Open Account → Orders for the live timeline.');
    }
    if (has(['recommend', 'suggest', 'which book', 'what should', 'सुझाव', 'कौन सी', 'पुस्तक बताओ', 'किताब'])) {
      final r = recommendedForUser().books.take(3).toList();
      return WaMessage(hi ? 'आपके लिए ये पुस्तकें सुझाई जाती हैं:' : 'Here are three books I think you will like:', books: r.map((b) => b.id).toList());
    }
    if (has(['catalog', 'language', 'browse', 'भाषा', 'कैटलॉग'])) return WaMessage(hi ? 'हमारे पास कई भाषाओं में पुस्तकें हैं — हिन्दी, गुजराती, मराठी, बंगाली, तेलुगु, तमिल आदि।' : 'We publish books in many languages — English, Hindi, Gujarati, Marathi, Bengali, Telugu, Tamil, Kannada, Malayalam, Odia and more. Try Browse → Shop by language.');
    for (final e in app.kb) {
      final words = e.q.toLowerCase().split(' ');
      if (words.any((w) => w.length > 2 && t.contains(w))) return WaMessage(hi ? 'जानकारी: ${e.a}' : e.a);
    }
    if (has(['price', 'cost', 'कीमत'])) return WaMessage(hi ? 'किताबों की कीमत ₹120 से शुरू होती है। किसी भी पुस्तक के पेज पर कीमत देखें।' : 'Books start from ₹120. Open any book page to see the price for each format.');
    return WaMessage(hi ? 'क्षमा करें, मुझे पूरी तरह समझ नहीं आया। क्या आप मानव सहायक से बात करना चाहेंगे?' : 'Sorry, I am not sure I understood. Would you like me to connect you to a human agent?');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(children: [
          const CircleAvatar(radius: 18, backgroundColor: Colors.white, child: Icon(Icons.spa, color: BvtColors.saffron)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('BVT Books', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            Text(human ? 'Human agent · online' : (typing ? 'typing…' : 'AI assistant · replies instantly'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
        ]),
        actions: [
          TextButton(onPressed: () => setState(() => hindi = !hindi), child: Text(hindi ? 'हिं' : 'EN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
          IconButton(icon: const Icon(Icons.support_agent), tooltip: 'Talk to a human', onPressed: () => _send('talk to a human agent')),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView(controller: _sc, padding: const EdgeInsets.all(12), children: [
            Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFFF3C4), borderRadius: BorderRadius.circular(8)), child: const Text('Messages are end-to-end encrypted · Opt-out any time by replying STOP', style: TextStyle(fontSize: 11)))),
            const SizedBox(height: 10),
            for (final m in app.chat) _Bubble(m),
            if (typing) const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.all(6), child: _Typing())),
          ]),
        ),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), children: [
            for (final q in hindi ? ['मेरा ऑर्डर कहाँ है?', 'पुस्तक सुझाव', 'रिटर्न नीति', 'मानव सहायक'] : ['Where is my order?', 'Recommend a book', 'Return policy', 'Shipping time', 'Cash on delivery', 'Talk to a human'])
              Padding(padding: const EdgeInsets.only(right: 8), child: ActionChip(backgroundColor: Colors.white, label: Text(q, style: const TextStyle(fontSize: 12.5)), onPressed: () => _send(q))),
          ]),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(children: [
              Expanded(child: TextField(controller: _c, onSubmitted: _send, textInputAction: TextInputAction.send, decoration: InputDecoration(hintText: hindi ? 'संदेश लिखें' : 'Type a message', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none)))),
              const SizedBox(width: 8),
              CircleAvatar(backgroundColor: const Color(0xFF075E54), child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: () => _send(_c.text))),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final WaMessage m;
  const _Bubble(this.m);
  @override
  Widget build(BuildContext context) {
    final me = !m.fromBot && !m.human;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(color: me ? const Color(0xFFDCF8C6) : Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (m.human) const Text('Meera · Support agent', style: TextStyle(color: Color(0xFF128C7E), fontWeight: FontWeight.w800, fontSize: 12)),
          Text(m.text, style: const TextStyle(height: 1.35)),
          for (final id in m.books)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                onTap: () => openBook(context, bookById(id)),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: BvtColors.cream, borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [BookCover(bookById(id), width: 34, showLang: false), const SizedBox(width: 8), Expanded(child: Text(bookById(id).title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))), const Icon(Icons.chevron_right, size: 18)]),
                ),
              ),
            ),
          Align(alignment: Alignment.centerRight, child: Text('${timeFmt(m.at)}${me ? '  ✓✓' : ''}', style: const TextStyle(fontSize: 10, color: BvtColors.muted))),
        ]),
      ),
    );
  }
}

class _Typing extends StatefulWidget {
  const _Typing();
  @override
  State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => Row(mainAxisSize: MainAxisSize.min, children: [for (var i = 0; i < 3; i++) Container(margin: const EdgeInsets.symmetric(horizontal: 2), width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.withValues(alpha: (((_c.value * 3) - i).abs() < 0.6) ? 1 : 0.35)))]),
        ),
      );
}
