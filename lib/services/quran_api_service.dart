import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ayah.dart';
import '../models/surah_summary.dart';

/// API publique sans clé — https://alquran.cloud/api
bool _parseSajda(dynamic raw) {
  if (raw == null || raw == false) return false;
  if (raw is bool) return raw;
  if (raw is Map) return raw.isNotEmpty;
  return true;
}

class QuranApiService {
  QuranApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _base = 'https://api.alquran.cloud/v1';

  Future<List<SurahSummary>> fetchSurahList() async {
    final r = await _client.get(Uri.parse('$_base/surah'));
    if (r.statusCode != 200) {
      throw Exception('Surahs: ${r.statusCode}');
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>)
        .map((e) => SurahSummary.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<List<Ayah>> fetchSurahAyahs(int surahNumber) async {
    final arUri = Uri.parse(
      '$_base/surah/$surahNumber/quran-uthmani',
    );
    final enUri = Uri.parse(
      '$_base/surah/$surahNumber/en.sahih',
    );

    final results = await Future.wait([
      _client.get(arUri),
      _client.get(enUri),
    ]);

    for (final r in results) {
      if (r.statusCode != 200) {
        throw Exception('Ayahs: ${r.statusCode}');
      }
    }

    final arData = jsonDecode(results[0].body) as Map<String, dynamic>;
    final enData = jsonDecode(results[1].body) as Map<String, dynamic>;

    final arAyahs = (arData['data'] as Map<String, dynamic>)['ayahs']
        as List<dynamic>;
    final enAyahs = (enData['data'] as Map<String, dynamic>)['ayahs']
        as List<dynamic>;

    if (arAyahs.length != enAyahs.length) {
      throw Exception('Mismatch ayah count');
    }

    final out = <Ayah>[];
    for (var i = 0; i < arAyahs.length; i++) {
      final a = arAyahs[i] as Map<String, dynamic>;
      final e = enAyahs[i] as Map<String, dynamic>;
      final sajda = _parseSajda(a['sajda']);
      out.add(
        Ayah(
          numberInSurah: a['numberInSurah'] as int,
          textAr: a['text'] as String,
          textEn: e['text'] as String,
          sajda: sajda,
        ),
      );
    }
    return out;
  }

  /// URLs MP3 par verset (ordre `numberInSurah`) — édition audio API, ex. `ar.alafasy`.
  Future<List<String>> fetchSurahAudioUrls(
    int surahNumber, {
    String audioEdition = 'ar.alafasy',
  }) async {
    final r = await _client.get(
      Uri.parse('$_base/surah/$surahNumber/$audioEdition'),
    );
    if (r.statusCode != 200) {
      throw Exception('Audio sourate: ${r.statusCode}');
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final ayahs =
        (data['data'] as Map<String, dynamic>)['ayahs'] as List<dynamic>;
    final sorted = ayahs.map((e) => e as Map<String, dynamic>).toList()
      ..sort(
        (a, b) => (a['numberInSurah'] as int).compareTo(
          b['numberInSurah'] as int,
        ),
      );
    return sorted.map((e) => e['audio'] as String).toList();
  }

  /// Première sourate / ayah d’un juz (1–30).
  Future<({int surahNumber, int ayahNumber})> fetchJuzStart(int juz) async {
    if (juz < 1 || juz > 30) {
      throw ArgumentError('juz must be 1–30');
    }
    final r = await _client.get(Uri.parse('$_base/juz/$juz/quran-uthmani'));
    if (r.statusCode != 200) throw Exception('Juz: ${r.statusCode}');
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final ayahs = (data['data'] as Map<String, dynamic>)['ayahs'] as List;
    if (ayahs.isEmpty) throw Exception('Empty juz');
    final first = ayahs.first as Map<String, dynamic>;
    final surah = first['surah'] as Map<String, dynamic>;
    return (
      surahNumber: surah['number'] as int,
      ayahNumber: first['numberInSurah'] as int,
    );
  }
}
