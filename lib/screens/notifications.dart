import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('Notifications'), actions: [TextButton(onPressed: () => app.update(() { for (final n in app.notifications) { n.read = true; } }), child: const Text('Mark all read'))]),
          body: app.notifications.isEmpty
              ? const EmptyState(Icons.notifications_none, 'All caught up', 'Order updates, subscription alerts and offers appear here. WhatsApp is the primary channel; push notifications are secondary.')
              : ListView.separated(
                  itemCount: app.notifications.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, i) {
                    final n = app.notifications[i];
                    final (icon, col) = switch (n.channel) { 'WhatsApp' => (Icons.chat, BvtColors.whatsapp), 'Email' => (Icons.mail_outline, BvtColors.maroon), 'Push' => (Icons.notifications_active, BvtColors.deepSaffron), _ => (Icons.info_outline, BvtColors.muted) };
                    return ListTile(
                      tileColor: n.read ? null : BvtColors.saffron.withValues(alpha: 0.07),
                      leading: CircleAvatar(backgroundColor: col.withValues(alpha: 0.15), child: Icon(icon, color: col)),
                      title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w500 : FontWeight.w800)),
                      subtitle: Text('${n.body}\nvia ${n.channel} · ${timeFmt(n.at)}'),
                      isThreeLine: true,
                      onTap: () => app.update(() => n.read = true),
                    );
                  },
                ),
        ),
      );
}
