import 'package:flutter/material.dart';

import 'screens/onboarding.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() {
  runApp(const BvtApp());
}

class BvtApp extends StatelessWidget {
  const BvtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => MaterialApp(
        title: 'BVT Books',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        darkTheme: buildTheme(dark: true),
        themeMode: app.dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(textScaler: TextScaler.linear(app.textScale)),
            child: _Frame(child: child!),
          );
        },
        home: const OnboardingGate(),
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  final Widget child;
  const _Frame({required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (size.width < 640) return child;
    final h = size.height.clamp(600.0, 920.0);
    return Container(
      color: const Color(0xFF3A2416),
      alignment: Alignment.center,
      child: Container(
        width: 420,
        height: h - 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 12))],
        ),
        clipBehavior: Clip.antiAlias,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(size: Size(420, h - 24)),
          child: child,
        ),
      ),
    );
  }
}
