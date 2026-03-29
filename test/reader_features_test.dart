import 'package:flutter_test/flutter_test.dart';

import 'package:alfawz/models/ayah.dart';
import 'package:alfawz/models/ayah_word_timings.dart';
import 'package:alfawz/models/surah_summary.dart';
import 'package:alfawz/services/bookmarks_store.dart';

void main() {
  group('BookmarkEntry', () {
    test('parse signet simple', () {
      final e = BookmarkEntry.parse('2:255');
      expect(e, isNotNull);
      expect(e!.surahNumber, 2);
      expect(e.startAyah, 255);
      expect(e.endAyah, 255);
      expect(e.storageKey, '2:255');
      expect(e.isRange, isFalse);
    });

    test('parse plage et ordre normalisé', () {
      final e = BookmarkEntry.parse('1:12-8');
      expect(e, isNotNull);
      expect(e!.startAyah, 8);
      expect(e.endAyah, 12);
      expect(e.storageKey, '1:8-12');
    });

    test('invalid', () {
      expect(BookmarkEntry.parse('oops'), isNull);
      expect(BookmarkEntry.parse('1'), isNull);
    });
  });

  group('JSON cache', () {
    test('Ayah + TimedWord + AyahWordTimings', () {
      const a = Ayah(
        numberInSurah: 1,
        textAr: 'بِسْمِ',
        textEn: 'In the name',
        sajda: false,
      );
      final aj = a.toJson();
      expect(Ayah.fromJson(aj).textAr, a.textAr);

      const tw = TimedWord(text: 'x', startMs: 0, endMs: 100);
      expect(TimedWord.fromJson(tw.toJson()).endMs, 100);

      final t = AyahWordTimings(numberInSurah: 1, words: [tw]);
      final t2 = AyahWordTimings.fromJson(t.toJson());
      expect(t2.words.length, 1);
      expect(t2.numberInSurah, 1);
    });

    test('SurahSummary', () {
      const s = SurahSummary(
        number: 1,
        nameEn: 'Al-Faatiha',
        nameAr: 'الفاتحة',
        verseCount: 7,
        revelationType: 'Meccan',
        nameTranslationEn: 'The Opening',
      );
      final s2 = SurahSummary.fromJson(s.toJson());
      expect(s2.nameEn, s.nameEn);
      expect(s2.verseCount, 7);
    });
  });
}
