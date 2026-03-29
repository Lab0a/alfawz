import 'package:shared_preferences/shared_preferences.dart';

class ReadingProgress {
  const ReadingProgress({required this.surahNumber, required this.ayahNumber});

  final int surahNumber;
  final int ayahNumber;
}

class ReadingProgressStore {
  static const _kSurah = 'alfawz_last_surah';
  static const _kAyah = 'alfawz_last_ayah';

  Future<ReadingProgress?> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getInt(_kSurah);
    final a = p.getInt(_kAyah);
    if (s == null || a == null) return null;
    return ReadingProgress(surahNumber: s, ayahNumber: a);
  }

  Future<void> save(int surahNumber, int ayahNumber) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kSurah, surahNumber);
    await p.setInt(_kAyah, ayahNumber);
  }
}
