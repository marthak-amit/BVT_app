import 'package:flutter/material.dart';

import '../theme.dart';
import 'admin_state.dart';

class AdminPage extends StatelessWidget {
  final String module, title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;
  const AdminPage({super.key, required this.module, required this.title, this.subtitle, this.actions = const [], required this.children});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: adm,
      builder: (context, _) {
        if (!adm.canRead(module)) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_outline, size: 60, color: BvtColors.red),
                const SizedBox(height: 12),
                const Text('403 · Access denied', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('The role “${adm.role.name}” has no access to ${adm.moduleLabel(module)}.\nPermissions are enforced server-side — never trust client-side role claims.', textAlign: TextAlign.center, style: const TextStyle(color: BvtColors.muted)),
              ]),
            ),
          );
        }
        return ListView(padding: const EdgeInsets.all(20), children: [
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 8, children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: BvtColors.maroon)),
            if (!adm.canWrite(module)) const Pill('READ ONLY', color: BvtColors.muted, icon: Icons.visibility),
            ...actions,
          ]),
          if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle!, style: const TextStyle(color: BvtColors.muted))),
          const SizedBox(height: 16),
          ...children,
        ]);
      },
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Pill(this.text, {super.key, this.color = BvtColors.saffron, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ]),
      );
}

class StatTile extends StatelessWidget {
  final String label, value;
  final String? delta;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const StatTile(this.label, this.value, this.icon, {super.key, this.delta, this.color = BvtColors.saffron, this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 210,
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [CircleAvatar(radius: 16, backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, size: 18, color: color)), const Spacer(), if (delta != null) Text(delta!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: delta!.startsWith('-') ? BvtColors.red : BvtColors.green))]),
                const SizedBox(height: 10),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                Text(label, style: const TextStyle(fontSize: 12.5, color: BvtColors.muted)),
              ]),
            ),
          ),
        ),
      );
}

class Panel extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget> actions;
  const Panel({super.key, this.title, required this.child, this.actions = const []});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (title != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Expanded(child: Text(title!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), ...actions])),
              child,
            ]),
          ),
        ),
      );
}

class DataGrid extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  const DataGrid(this.columns, this.rows, {super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width > 900 ? 760 : 0),
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 64,
            columnSpacing: 22,
            headingTextStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: BvtColors.muted),
            columns: [for (final c in columns) DataColumn(label: Text(c))],
            rows: [for (final r in rows) DataRow(cells: [for (final c in r) DataCell(c)])],
          ),
        ),
      );
}

class BarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double height;
  final String Function(double)? fmt;
  const BarChart(this.values, this.labels, {super.key, this.color = BvtColors.saffron, this.height = 180, this.fmt});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: CustomPaint(painter: _BarPainter(values, labels, color, Theme.of(context).brightness == Brightness.dark ? Colors.white70 : BvtColors.muted), size: Size.infinite),
      );
}

class _BarPainter extends CustomPainter {
  final List<double> v;
  final List<String> l;
  final Color c, tc;
  _BarPainter(this.v, this.l, this.c, this.tc);
  @override
  void paint(Canvas canvas, Size size) {
    if (v.isEmpty) return;
    final maxV = v.reduce((a, b) => a > b ? a : b) * 1.1;
    final bw = size.width / v.length;
    final grid = Paint()..color = tc.withValues(alpha: 0.15);
    for (var i = 0; i <= 3; i++) {
      final y = (size.height - 22) * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var i = 0; i < v.length; i++) {
      final h = (size.height - 22) * (v[i] / maxV);
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(i * bw + bw * 0.18, size.height - 22 - h, bw * 0.64, h), const Radius.circular(4));
      canvas.drawRRect(r, Paint()..color = c.withValues(alpha: 0.35 + 0.65 * (i / v.length)));
      if (i < l.length && (v.length <= 8 || i % 2 == 0)) {
        final tp = TextPainter(text: TextSpan(text: l[i], style: TextStyle(fontSize: 10, color: tc)), textDirection: TextDirection.ltr)..layout(maxWidth: bw * 2);
        tp.paint(canvas, Offset(i * bw + bw / 2 - tp.width / 2, size.height - 16));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => old.v != v;
}

class HBar extends StatelessWidget {
  final String label;
  final double value, max;
  final String text;
  final Color color;
  const HBar(this.label, this.value, this.max, this.text, {super.key, this.color = BvtColors.saffron});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          SizedBox(width: 130, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
          Expanded(child: LinearProgressIndicator(value: (value / max).clamp(0, 1), minHeight: 10, borderRadius: BorderRadius.circular(5), color: color, backgroundColor: color.withValues(alpha: 0.15))),
          const SizedBox(width: 10),
          SizedBox(width: 72, child: Text(text, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5))),
        ]),
      );
}

void showExport(BuildContext c, String file, String preview) {
  showDialog(
    context: c,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.download_done, color: BvtColors.green, size: 40),
      title: Text(file),
      content: Container(width: 460, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: BvtColors.sand, borderRadius: BorderRadius.circular(8)), child: Text(preview, style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, height: 1.5))),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
    ),
  );
}

void adminToast(BuildContext c, String msg) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

String shortDate(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]}';
}

String dayTime(DateTime d) => '${shortDate(d)}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
