import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth.dart';
import 'shell.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});
  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool splash = true;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => splash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (_, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: splash
            ? const _Splash(key: ValueKey('splash'))
            : (app.onboarded ? const AppShell(key: ValueKey('shell')) : const _Welcome(key: ValueKey('welcome'))),
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [BvtColors.deepSaffron, BvtColors.maroon]),
          ),
          child: const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.spa, size: 84, color: BvtColors.gold),
              SizedBox(height: 16),
              Text('BHAKTI VIKAS TRUST', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2)),
              SizedBox(height: 6),
              Text('books.bvks.com', style: TextStyle(color: Colors.white70, letterSpacing: 1)),
              SizedBox(height: 40),
              SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white70)),
            ]),
          ),
        ),
      );
}

class _Welcome extends StatelessWidget {
  const _Welcome({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const SizedBox(height: 12),
            const Icon(Icons.spa, size: 56, color: BvtColors.saffron),
            const SizedBox(height: 12),
            Text(app.t('welcome'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: BvtColors.maroon)),
            const SizedBox(height: 6),
            const Text('Books, posters and digital reading in 16 languages — delivered worldwide with WhatsApp order updates.', style: TextStyle(color: BvtColors.muted, height: 1.4)),
            const SizedBox(height: 28),
            Text(app.t('language'), style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (final e in uiLanguages.entries)
                ChoiceChip(label: Text(e.value), selected: app.locale == e.key, onSelected: (_) => app.update(() => app.locale = e.key)),
            ]),
            const SizedBox(height: 22),
            const Text('Preferred reading language', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('We detected this from your device. You can change it any time.', style: TextStyle(color: BvtColors.muted, fontSize: 12.5)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final l in languages)
                ChoiceChip(label: Text(l.native), selected: app.preferredBookLang == l.code, onSelected: (_) => app.update(() => app.preferredBookLang = l.code)),
            ]),
            const SizedBox(height: 28),
            const _Feature(Icons.chat, BvtColors.whatsapp, 'WhatsApp-first updates', 'Order, shipping and subscription updates delivered where you already are.'),
            const _Feature(Icons.auto_stories, BvtColors.saffron, 'Digital reading subscriptions', 'Read in the DRM-protected in-app reader, online or offline.'),
            const _Feature(Icons.local_shipping, BvtColors.maroon, 'Worldwide shipping', 'Courier partners for India and international delivery.'),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => app.update(() => app.onboarded = true), child: const Text('Start exploring')),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () async {
                app.update(() => app.onboarded = true);
              },
              child: const Text('Continue as guest'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => push(context, const LoginScreen()).then((_) => app.update(() => app.onboarded = true)),
              child: Text('${app.t('sign_in')} / Register'),
            ),
          ]),
        ),
      );
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, text;
  const _Feature(this.icon, this.color, this.title, this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(text, style: const TextStyle(color: BvtColors.muted, fontSize: 13)),
          ])),
        ]),
      );
}
