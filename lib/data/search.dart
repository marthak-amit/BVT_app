import 'catalog.dart';
import 'models.dart';

const _diacritics = {
  'ā': 'a', 'ī': 'i', 'ū': 'u', 'ṛ': 'r', 'ṝ': 'r', 'ṣ': 's', 'ś': 's', 'ṇ': 'n', 'ṭ': 't', 'ḍ': 'd',
  'ṁ': 'm', 'ṃ': 'm', 'ḥ': 'h', 'ñ': 'n', 'ṅ': 'n', 'é': 'e', 'á': 'a', 'ó': 'o',
};

// A few Devanagari/Gujarati words mapped to Latin keys so script queries work.
const _scriptWords = {
  'कृष्ण': 'krsna',
  'રામાયણ': 'ramayana',
  'रामायण': 'ramayana',
  'गीता': 'gita',
  'गीत': 'gita',
  'चैतन्य': 'caitanya',
  'प्रभुपाद': 'prabhupada',
  'कृष्णा': 'krsna',
  'કૃષ્ણ': 'krsna',
  'ગીતા': 'gita',
  'প্রভুপাদ': 'prabhupada',
};

final Map<String, String> synonyms = {
  'geeta': 'gita',
  'gitaa': 'gita',
  'bhagwad': 'bhagavad',
  'bhagwat': 'bhagavad',
  'ramayan': 'ramayana',
  'chaitanya': 'caitanya',
  'caitanya': 'caitanya',
  'kids': 'children',
  'child': 'children',
  'pooja': 'puja',
  'tulsi': 'tulasi',
};

/// Phonetic key so that krishna / Krsna / Kṛṣṇa all collapse to "krsna".
String phoneticKey(String input) {
  var s = input.toLowerCase();
  _diacritics.forEach((k, v) => s = s.replaceAll(k, v));
  _scriptWords.forEach((k, v) => s = s.replaceAll(k, v));
  s = s
      .replaceAll(RegExp(r'[^a-z0-9ऀ-෿ ]'), ' ')
      .replaceAll('sh', 's')
      .replaceAll('ri', 'r')
      .replaceAll('ee', 'i')
      .replaceAll('oo', 'u')
      .replaceAll('aa', 'a')
      .replaceAll('w', 'v')
      .replaceAll(RegExp(r'(?<=[bcdgjkpt])h'), '')
      .replaceAll('ch', 'c')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return s;
}

int _lev(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = [cur[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length];
}

String _blob(Book b) =>
    '${phoneticKey(b.title)} ${phoneticKey(b.aliases)} ${phoneticKey(b.author)} ${phoneticKey(b.category)} ${phoneticKey(langOf(b.language).name)} ${b.title.toLowerCase()}';

final Map<String, String> _blobCache = {};

/// Relevance score of [b] for [query]; 0 = no match.
double scoreBook(Book b, String query) {
  final raw = query.trim().toLowerCase();
  if (raw.isEmpty) return 1;
  final blob = _blobCache.putIfAbsent(b.id, () => _blob(b));
  var tokens = phoneticKey(raw).split(' ').where((t) => t.isNotEmpty).toList();
  tokens = tokens.map((t) => synonyms[t] != null ? phoneticKey(synonyms[t]!) : t).toList();
  if (tokens.isEmpty) return 0;
  final words = blob.split(' ').where((w) => w.isNotEmpty).toList();
  var score = 0.0;
  for (final t in tokens) {
    if (blob.contains(t)) {
      score += b.title.toLowerCase().contains(t) || phoneticKey(b.title).contains(t) ? 3 : 1.5;
      continue;
    }
    final tol = t.length >= 7 ? 2 : (t.length >= 4 ? 1 : 0);
    if (tol == 0) return 0;
    final hit = words.any((w) => (w.length - t.length).abs() <= tol && _lev(w, t) <= tol);
    if (!hit) return 0;
    score += 1;
  }
  if (phoneticKey(b.title).startsWith(tokens.first)) score += 1;
  if (b.language == 'en') score += 0.2;
  return score + b.rating / 20;
}

List<Book> searchBooks(String query, {List<Book>? within}) {
  final src = within ?? catalog;
  final scored = <(Book, double)>[];
  for (final b in src) {
    final s = scoreBook(b, query);
    if (s > 0) scored.add((b, s));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return scored.map((e) => e.$1).toList();
}

List<String> suggestTitles(String query, {int limit = 6}) {
  if (query.trim().length < 2) return const [];
  final seen = <String>{};
  final out = <String>[];
  for (final b in searchBooks(query)) {
    if (seen.add(b.group)) out.add(b.title);
    if (out.length >= limit) break;
  }
  return out;
}
