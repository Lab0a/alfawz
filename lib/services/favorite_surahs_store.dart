import 'package:shared_preferences/shared_preferences.dart';

class FavoriteSurahsStore {
  static const _k = 'alfawz_favorite_surahs';

  Future<Set<int>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_k);
    if (raw == null) return {};
    return raw.map(int.parse).toSet();
  }

  Future<void> toggle(int surahNumber) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_k) ?? <String>[];
    final set = raw.map(int.parse).toSet();
    if (set.contains(surahNumber)) {
      set.remove(surahNumber);
    } else {
      set.add(surahNumber);
    }
    await p.setStringList(_k, set.map((e) => '$e').toList());
  }
}
