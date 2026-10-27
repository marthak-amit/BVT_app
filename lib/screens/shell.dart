import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'account.dart';
import 'browse.dart';
import 'cart.dart';
import 'chatbot.dart';
import 'home.dart';
import 'library.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([app, tabIndex]),
      builder: (context, _) {
        final i = tabIndex.value;
        return Scaffold(
          body: Stack(children: [
            IndexedStack(index: i, children: const [HomeTab(), BrowseTab(), LibraryTab(), CartTab(), AccountTab()]),
            if (!app.cookieConsentShown)
              Positioned(left: 14, right: 14, bottom: 10, child: _CookieBanner()),
          ]),
          floatingActionButton: ((i == 0 || i == 1) && app.cookieConsentShown)
              ? FloatingActionButton(
                  backgroundColor: BvtColors.whatsapp,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  tooltip: 'Chat support',
                  onPressed: () => push(context, const ChatbotScreen()),
                  child: const Icon(Icons.chat_rounded),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: i,
            onDestinationSelected: (v) => tabIndex.value = v,
            destinations: [
              NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: app.t('home')),
              NavigationDestination(icon: const Icon(Icons.grid_view_outlined), selectedIcon: const Icon(Icons.grid_view_rounded), label: app.t('browse')),
              NavigationDestination(icon: const Icon(Icons.auto_stories_outlined), selectedIcon: const Icon(Icons.auto_stories), label: app.t('library')),
              NavigationDestination(
                icon: Badge(isLabelVisible: app.cartCount > 0, label: Text('${app.cartCount}'), child: const Icon(Icons.shopping_cart_outlined)),
                selectedIcon: Badge(isLabelVisible: app.cartCount > 0, label: Text('${app.cartCount}'), child: const Icon(Icons.shopping_cart)),
                label: app.t('cart'),
              ),
              NavigationDestination(
                icon: Badge(isLabelVisible: app.unreadCount > 0, smallSize: 8, child: const Icon(Icons.person_outline)),
                selectedIcon: const Icon(Icons.person),
                label: app.t('account'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CookieBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Material(
        elevation: 10,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(18),
        color: BvtColors.ink,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          child: Row(children: [
            const Icon(Icons.cookie_outlined, color: BvtColors.gold, size: 22),
            const SizedBox(width: 10),
            const Expanded(child: Text('We use cookies for analytics (GA4, Meta Pixel). GDPR-compliant consent.', style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35))),
            const SizedBox(width: 6),
            TextButton(onPressed: () => app.update(() => app.cookieConsentShown = true), child: const Text('Essential', style: TextStyle(color: Colors.white60, fontSize: 12))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: BvtColors.gold, foregroundColor: Colors.black, minimumSize: const Size(64, 36), padding: const EdgeInsets.symmetric(horizontal: 14)),
              onPressed: () => app.update(() => app.cookieConsentShown = true),
              child: const Text('Accept', style: TextStyle(fontSize: 12.5)),
            ),
          ]),
        ),
      );
}
