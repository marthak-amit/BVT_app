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
              Positioned(left: 12, right: 12, bottom: 8, child: _CookieBanner()),
          ]),
          floatingActionButton: (i == 0 || i == 1)
              ? FloatingActionButton.extended(
                  backgroundColor: BvtColors.whatsapp,
                  foregroundColor: Colors.white,
                  onPressed: () => push(context, const ChatbotScreen()),
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat'),
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
        elevation: 8,
        borderRadius: BorderRadius.circular(14),
        color: BvtColors.maroon,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('We value your privacy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('We use cookies for essential features, analytics (GA4) and Meta Pixel. GDPR-compliant consent for EU visitors.', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () => app.update(() => app.cookieConsentShown = true), child: const Text('Essential only', style: TextStyle(color: Colors.white70))))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: BvtColors.gold, foregroundColor: Colors.black, minimumSize: const Size(90, 38)),
                onPressed: () => app.update(() => app.cookieConsentShown = true),
                child: const Text('Accept all'),
              ),
            ]),
          ]),
        ),
      );
}
