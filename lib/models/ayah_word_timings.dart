/// Mot aligné sur l’audio (API Quran.com + récitation Mishary / Alafasy).
class TimedWord {
  const TimedWord({
    required this.text,
    required this.startMs,
    required this.endMs,
  });

  final String text;
  final int startMs;
  final int endMs;

  Map<String, dynamic> toJson() => {
        'text': text,
        'startMs': startMs,
        'endMs': endMs,
      };

  factory TimedWord.fromJson(Map<String, dynamic> j) {
    return TimedWord(
      text: j['text'] as String,
      startMs: j['startMs'] as int,
      endMs: j['endMs'] as int,
    );
  }
}

/// Portion de verset alignée sur l’audio (regroupe plusieurs mots, pauses naturelles).
class AyahPhraseSegment {
  const AyahPhraseSegment({
    required this.startMs,
    required this.endMs,
    required this.firstWordIndex,
    required this.lastWordIndex,
  });

  final int startMs;
  final int endMs;
  final int firstWordIndex;
  final int lastWordIndex;

  int get durationMs => (endMs - startMs).clamp(0, 1 << 30);
}

/// Segments mot à mot pour un verset (timestamps relatifs au MP3 de ce verset).
class AyahWordTimings {
  const AyahWordTimings({
    required this.numberInSurah,
    required this.words,
  });

  final int numberInSurah;
  final List<TimedWord> words;

  int get endMs => words.isEmpty ? 0 : words.last.endMs;

  static String normalizeVerseSpacing(String s) =>
      s.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Texte reconstitué à partir des mots API (pour comparaison avec `Ayah.textAr`).
  String get joinedWordsText =>
      normalizeVerseSpacing(words.map((w) => w.text).join(' '));

  /// Même graphie Uthmani que le verset affiché — on peut surligner par phrase dans le texte.
  bool matchesAyahArabic(String textAr) =>
      joinedWordsText == normalizeVerseSpacing(textAr);

  /// Texte affichable d’une phrase (continu, espaces naturels entre mots).
  String phraseText(AyahPhraseSegment segment) {
    return words
        .sublist(segment.firstWordIndex, segment.lastWordIndex + 1)
        .map((w) => w.text)
        .join(' ');
  }

  /// Phrases déduites des pauses entre mots (sans modifier le texte affiché).
  List<AyahPhraseSegment> phraseSegments({int pauseThresholdMs = 140}) {
    return AyahWordTimings._splitIntoPhrases(words, pauseThresholdMs);
  }

  /// Indice de la phrase active pour une position dans le MP3 du verset (ms).
  int phraseIndexAt(int ms, {int pauseThresholdMs = 140}) {
    return AyahWordTimings.phraseIndexForSegments(
      phraseSegments(pauseThresholdMs: pauseThresholdMs),
      ms,
    );
  }

  /// Réutiliser la liste déjà calculée (une seule coupure `phraseSegments` par frame).
  static int phraseIndexForSegments(List<AyahPhraseSegment> segs, int ms) {
    if (segs.isEmpty) return -1;
    for (var i = 0; i < segs.length; i++) {
      final s = segs[i];
      if (ms >= s.startMs && ms < s.endMs) return i;
    }
    if (ms < segs.first.startMs) return -1;
    if (ms >= segs.last.endMs) return segs.length - 1;
    for (var i = segs.length - 1; i >= 0; i--) {
      if (ms >= segs[i].startMs) return i;
    }
    return -1;
  }

  static List<AyahPhraseSegment> _splitIntoPhrases(
    List<TimedWord> words,
    int pauseThresholdMs,
  ) {
    if (words.isEmpty) return [];
    final out = <AyahPhraseSegment>[];
    var phraseFirstIdx = 0;
    var phraseStart = words.first.startMs;
    var phraseEnd = words.first.endMs;
    for (var i = 0; i < words.length - 1; i++) {
      final gap = words[i + 1].startMs - words[i].endMs;
      if (gap > pauseThresholdMs) {
        out.add(
          AyahPhraseSegment(
            startMs: phraseStart,
            endMs: phraseEnd,
            firstWordIndex: phraseFirstIdx,
            lastWordIndex: i,
          ),
        );
        phraseFirstIdx = i + 1;
        phraseStart = words[i + 1].startMs;
      }
      phraseEnd = words[i + 1].endMs;
    }
    out.add(
      AyahPhraseSegment(
        startMs: phraseStart,
        endMs: phraseEnd,
        firstWordIndex: phraseFirstIdx,
        lastWordIndex: words.length - 1,
      ),
    );
    if (out.length > 1 || words.length <= 6) return out;
    return _chunkByWordCount(words, maxWordsPerPhrase: 5);
  }

  /// Quand il n’y a presque pas de pauses mesurées, regrouper par blocs de mots.
  static List<AyahPhraseSegment> _chunkByWordCount(
    List<TimedWord> words, {
    required int maxWordsPerPhrase,
  }) {
    final out = <AyahPhraseSegment>[];
    var i = 0;
    while (i < words.length) {
      final end = (i + maxWordsPerPhrase < words.length)
          ? i + maxWordsPerPhrase - 1
          : words.length - 1;
      out.add(
        AyahPhraseSegment(
          startMs: words[i].startMs,
          endMs: words[end].endMs,
          firstWordIndex: i,
          lastWordIndex: end,
        ),
      );
      i = end + 1;
    }
    return out;
  }

  /// Indice du mot pour une position dans le MP3 du verset (ms).
  int wordIndexAt(int ms) {
    if (words.isEmpty) return -1;
    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      if (ms >= w.startMs && ms < w.endMs) return i;
    }
    if (ms < words.first.startMs) return -1;
    if (ms >= words.last.endMs) return words.length - 1;
    for (var i = words.length - 1; i >= 0; i--) {
      if (ms >= words[i].startMs) return i;
    }
    return -1;
  }

  Map<String, dynamic> toJson() => {
        'numberInSurah': numberInSurah,
        'words': words.map((w) => w.toJson()).toList(),
      };

  factory AyahWordTimings.fromJson(Map<String, dynamic> j) {
    final raw = j['words'] as List<dynamic>? ?? [];
    return AyahWordTimings(
      numberInSurah: j['numberInSurah'] as int,
      words: raw
          .map((e) => TimedWord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
