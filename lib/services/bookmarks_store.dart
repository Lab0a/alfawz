import 'package:shared_preferences/shared_preferences.dart';

class BookmarkEntry {
  const BookmarkEntry({
    required this.surahNumber,
    required this.startAyah,
    required this.endAyah,
  });

  final int surahNumber;
  final int startAyah;
  /// Inclusif ; égal à [startAyah] pour un signet simple.
  final int endAyah;

  bool get isRange => startAyah != endAyah;

  String get storageKey => startAyah == endAyah
      ? '$surahNumber:$startAyah'
      : '$surahNumber:$startAyah-$endAyah';

  bool coversAyah(int ayah) =>
      ayah >= startAyah && ayah <= endAyah;

  static BookmarkEntry? parse(String key) {
    final p = key.split(':');
    if (p.length != 2) return null;
    final s = int.tryParse(p[0]);
    if (s == null) return null;
    final rest = p[1].trim();
    if (rest.contains('-')) {
      final parts = rest.split('-');
      if (parts.length != 2) return null;
      final a = int.tryParse(parts[0].trim());
      final b = int.tryParse(parts[1].trim());
      if (a == null || b == null) return null;
      final lo = a < b ? a : b;
      final hi = a < b ? b : a;
      return BookmarkEntry(surahNumber: s, startAyah: lo, endAyah: hi);
    }
    final a = int.tryParse(rest);
    if (a == null) return null;
    return BookmarkEntry(surahNumber: s, startAyah: a, endAyah: a);
  }
}

class BookmarksStore {
  static const _k = 'alfawz_bookmarks';

  Future<Set<String>> loadKeys() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_k)?.toSet() ?? {};
  }

  Future<void> toggleSingle(int surah, int ayah) async {
    final p = await SharedPreferences.getInstance();
    final set = p.getStringList(_k)?.toSet() ?? {};
    final k = BookmarkEntry(surahNumber: surah, startAyah: ayah, endAyah: ayah)
        .storageKey;
    if (set.contains(k)) {
      set.remove(k);
    } else {
      set.add(k);
    }
    await p.setStringList(_k, set.toList());
  }

  /// Signet sur une plage inclusive [startAyah]–[endAyah].
  Future<void> addOrUpdateRange(int surah, int startAyah, int endAyah) async {
    final lo = startAyah < endAyah ? startAyah : endAyah;
    final hi = startAyah < endAyah ? endAyah : startAyah;
    final p = await SharedPreferences.getInstance();
    final set = p.getStringList(_k)?.toSet() ?? {};
    final k = BookmarkEntry(surahNumber: surah, startAyah: lo, endAyah: hi).storageKey;
    set.add(k);
    await p.setStringList(_k, set.toList());
  }

  /// Signet simple exact (une entrée `surah:ayah` uniquement).
  Future<bool> hasSingleBookmark(int surah, int ayah) async {
    final keys = await loadKeys();
    return keys.contains(
      BookmarkEntry(surahNumber: surah, startAyah: ayah, endAyah: ayah).storageKey,
    );
  }

  @Deprecated('Utiliser hasSingleBookmark')
  Future<bool> contains(int surah, int ayah) => hasSingleBookmark(surah, ayah);
}
