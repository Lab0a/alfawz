import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ayah.dart';
import '../models/ayah_word_timings.dart';

/// Données lecteur : arabe + anglais + MP3 + timings — même source [api.quran.com](https://api.quran.com).
class SurahReaderPayload {
  const SurahReaderPayload({
    required this.ayahs,
    required this.audioUrls,
    required this.wordTimings,
  });

  final List<Ayah> ayahs;
  final List<String> audioUrls;
  final List<AyahWordTimings> wordTimings;
}

class _ParsedVerse {
  _ParsedVerse({
    required this.ayah,
    required this.audioUrl,
    this.timings,
  });

  final Ayah ayah;
  final String audioUrl;
  final AyahWordTimings? timings;
}

/// Texte + segments audio mot à mot — récitation [recitationId] (7 = Mishari Rashid al-`Afasy).
class QuranComApiService {
  QuranComApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _base = 'https://api.quran.com/api/v4';

  /// CDN officiel des MP3 **par verset** (alignés sur les `segments` de la même API).
  static const audioCdnBase = 'https://audio.qurancdn.com/';

  /// Sourate complète : Uthmani, traduction, URL audio et timings — une seule chaîne de vérité.
  Future<SurahReaderPayload> fetchSurahAlignedContent(
    int surahNumber, {
    int recitationId = 7,
    int translationId = 20,
    int perPage = 50,
  }) async {
    final rows = await _fetchParsedVerses(
      surahNumber,
      recitationId: recitationId,
      translationId: translationId,
      perPage: perPage,
    );
    return SurahReaderPayload(
      ayahs: rows.map((e) => e.ayah).toList(),
      audioUrls: rows.map((e) => e.audioUrl).toList(),
      wordTimings: rows.map((e) => e.timings).whereType<AyahWordTimings>().toList(),
    );
  }

  Future<List<_ParsedVerse>> _fetchParsedVerses(
    int surahNumber, {
    required int recitationId,
    required int translationId,
    required int perPage,
  }) async {
    if (surahNumber < 1 || surahNumber > 114) {
      throw ArgumentError('sourate 1–114');
    }
    final rows = <_ParsedVerse>[];
    var page = 1;
    while (true) {
      final uri = Uri.parse('$_base/verses/by_chapter/$surahNumber').replace(
        queryParameters: <String, String>{
          'words': 'true',
          'audio': '$recitationId',
          'fields': 'text_uthmani',
          'word_fields': 'text_uthmani',
          'translations': '$translationId',
          'per_page': '$perPage',
          'page': '$page',
        },
      );
      final r = await _client.get(uri);
      if (r.statusCode != 200) {
        throw Exception('Quran.com by_chapter: ${r.statusCode}');
      }
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final verses = data['verses'] as List<dynamic>;
      final pag = data['pagination'] as Map<String, dynamic>;

      for (final raw in verses) {
        final row = _parseAlignedVerse(raw as Map<String, dynamic>);
        if (row != null) rows.add(row);
      }

      final totalPages = pag['total_pages'] as int? ?? 1;
      if (page >= totalPages) break;
      page++;
    }

    rows.sort(
      (a, b) => a.ayah.numberInSurah.compareTo(b.ayah.numberInSurah),
    );
    return rows;
  }

  _ParsedVerse? _parseAlignedVerse(Map<String, dynamic> v) {
    final verseNum = v['verse_number'] as int;
    final textAr = v['text_uthmani'] as String? ?? '';
    final textEn = _translationText(v);
    final sajda = v['sajdah_number'] != null;

    final wordsJson = v['words'] as List<dynamic>? ?? [];
    final wordRows = wordsJson
        .map((e) => e as Map<String, dynamic>)
        .where((w) => w['char_type_name'] == 'word')
        .toList();

    final audio = v['audio'] as Map<String, dynamic>?;
    final relUrl = audio?['url'] as String?;
    final audioUrl =
        relUrl != null && relUrl.isNotEmpty ? '$audioCdnBase$relUrl' : '';

    final segs = audio?['segments'] as List<dynamic>?;
    AyahWordTimings? timings;
    if (segs != null && segs.isNotEmpty) {
      final timed = <TimedWord>[];
      final n = wordRows.length < segs.length ? wordRows.length : segs.length;
      for (var i = 0; i < n; i++) {
        final seg = segs[i];
        if (seg is! List || seg.length < 4) continue;
        final startRaw = seg[2];
        final endRaw = seg[3];
        final start = startRaw is int
            ? startRaw
            : (startRaw is num ? startRaw.round() : null);
        final end =
            endRaw is int ? endRaw : (endRaw is num ? endRaw.round() : null);
        if (start == null || end == null) continue;
        final w = wordRows[i];
        final text = (w['text_uthmani'] as String?) ??
            (w['text'] as String?) ??
            '';
        timed.add(TimedWord(text: text, startMs: start, endMs: end));
      }
      if (timed.isNotEmpty) {
        timings = AyahWordTimings(numberInSurah: verseNum, words: timed);
      }
    }

    return _ParsedVerse(
      ayah: Ayah(
        numberInSurah: verseNum,
        textAr: textAr,
        textEn: textEn,
        sajda: sajda,
      ),
      audioUrl: audioUrl,
      timings: timings,
    );
  }

  String _translationText(Map<String, dynamic> v) {
    final list = v['translations'] as List<dynamic>?;
    if (list == null || list.isEmpty) return '';
    final first = list.first as Map<String, dynamic>;
    final raw = first['text'] as String? ?? '';
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s*\d+\s*'), ' ')
        .trim();
  }

  /// Timings seuls (même requête réseau que [fetchSurahAlignedContent]).
  Future<List<AyahWordTimings>> fetchSurahWordTimings(
    int surahNumber, {
    int recitationId = 7,
    int perPage = 50,
  }) async {
    final rows = await _fetchParsedVerses(
      surahNumber,
      recitationId: recitationId,
      translationId: 20,
      perPage: perPage,
    );
    return rows.map((e) => e.timings).whereType<AyahWordTimings>().toList();
  }
}
