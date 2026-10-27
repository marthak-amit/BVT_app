import '../state/app_state.dart';
import 'catalog.dart';
import 'models.dart';

/// "Customers also bought" — same language, related category first.
List<Book> alsoBought(Book b, {int limit = 8}) {
  final pool = catalog.where((x) => x.group != b.group && x.language == b.language && !x.isPoster == !b.isPoster).toList();
  pool.sort((x, y) {
    final sx = (x.category == b.category ? 2 : 0) + x.rating / 5;
    final sy = (y.category == b.category ? 2 : 0) + y.rating / 5;
    return sy.compareTo(sx);
  });
  return pool.take(limit).toList();
}

List<Book> relatedBooks(Book b, {int limit = 8}) {
  final pool = catalog.where((x) => x.group != b.group && x.category == b.category).toList();
  pool.sort((x, y) => (x.language == b.language ? 0 : 1).compareTo(y.language == b.language ? 0 : 1));
  return pool.take(limit).toList();
}

/// Personalised shelf based on purchases, browsing and subscriptions.
({List<Book> books, String reason}) recommendedForUser() {
  final cats = <String, int>{};
  String? seed;
  for (final o in app.orders) {
    for (final l in o.lines) {
      final b = maybeBook(l.bookId);
      if (b != null) {
        cats[b.category] = (cats[b.category] ?? 0) + 2;
        seed ??= b.title;
      }
    }
  }
  for (final id in app.recent) {
    final b = maybeBook(id);
    if (b != null) {
      cats[b.category] = (cats[b.category] ?? 0) + 1;
      seed ??= b.title;
    }
  }
  final owned = app.orders.expand((o) => o.lines.map((l) => maybeBook(l.bookId)?.group)).toSet();
  final lang = app.preferredBookLang;
  final pool = catalog.where((b) => !owned.contains(b.group) && b.language == lang).toList();
  if (pool.isEmpty) pool.addAll(catalog.where((b) => b.language == 'en'));
  pool.sort((a, b) => ((cats[b.category] ?? 0) * 2 + b.rating).compareTo((cats[a.category] ?? 0) * 2 + a.rating));
  final reason = seed != null
      ? 'Because you bought or viewed “$seed”'
      : 'Popular in ${langOf(lang).name}';
  return (books: pool.take(10).toList(), reason: reason);
}
