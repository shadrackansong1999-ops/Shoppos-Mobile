/// Generic relevance search used anywhere a screen filters a list by a
/// text query (Products, POS, Customers, Suppliers, ...). Ranks matches
/// instead of just filtering, and tolerates small typos, so it behaves
/// closer to how a person actually searches than a plain `.contains()`.
///
/// Scoring (lower is better - sorted ascending):
///   0  exact match on any field
///   1  a field starts with the query
///   2  a field contains the query as one substring
///   3  every word in the query appears somewhere across the fields
///      (out of order) - "choc milk" finds "Chocolate Milk 500ml"
///   4  close typo match (edit distance) on a field
///   (no match -> excluded entirely)
List<T> rankBySearch<T>(
  List<T> items,
  String query, {
  required List<String> Function(T item) fields,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;
  final qWords = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  final scored = <MapEntry<T, int>>[];
  for (final item in items) {
    final values = fields(item).map((f) => f.toLowerCase()).where((f) => f.isNotEmpty).toList();
    if (values.isEmpty) continue;

    int? score;

    // 0: exact match
    if (values.any((v) => v == q)) {
      score = 0;
    }
    // 1: starts with
    else if (values.any((v) => v.startsWith(q))) {
      score = 1;
    }
    // 2: plain substring anywhere
    else if (values.any((v) => v.contains(q))) {
      score = 2;
    }
    // 3: every word of a multi-word query shows up somewhere
    else if (qWords.length > 1 && qWords.every((w) => values.any((v) => v.contains(w)))) {
      score = 3;
    }
    // 4: typo-tolerant fallback - only for reasonably short queries,
    // where a couple of edits away from a field is still meaningfully
    // "this one", without matching everything under the sun.
    else if (q.length >= 3) {
      final maxAllowedEdits = q.length <= 5 ? 1 : 2;
      final close = values.any((v) => _withinEditDistance(q, v, maxAllowedEdits));
      if (close) score = 4;
    }

    if (score != null) scored.add(MapEntry(item, score));
  }

  scored.sort((a, b) => a.value.compareTo(b.value));
  return scored.map((e) => e.key).toList();
}

/// True if [query] is within [maxEdits] edits of some substring/window of
/// [text] roughly the same length - cheap approximation rather than full
/// Levenshtein-against-every-substring, which is plenty for short product
/// names and SKUs.
bool _withinEditDistance(String query, String text, int maxEdits) {
  if (text.length < query.length - maxEdits) return false;
  final windowSize = query.length + maxEdits;
  for (int start = 0; start <= (text.length - 1).clamp(0, text.length); start++) {
    if (start > 0 && text.length <= windowSize) break; // short text: only check once
    final end = (start + windowSize).clamp(0, text.length);
    final window = text.substring(start, end);
    if (_levenshtein(query, window) <= maxEdits) return true;
    if (text.length <= windowSize) break;
  }
  return false;
}

int _levenshtein(String a, String b) {
  final la = a.length, lb = b.length;
  if (la == 0) return lb;
  if (lb == 0) return la;
  var prev = List<int>.generate(lb + 1, (j) => j);
  for (int i = 1; i <= la; i++) {
    final curr = List<int>.filled(lb + 1, 0);
    curr[0] = i;
    for (int j = 1; j <= lb; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      curr[j] = [
        curr[j - 1] + 1, // insertion
        prev[j] + 1, // deletion
        prev[j - 1] + cost, // substitution
      ].reduce((x, y) => x < y ? x : y);
    }
    prev = curr;
  }
  return prev[lb];
}
