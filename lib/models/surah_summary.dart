class SurahSummary {
  const SurahSummary({
    required this.number,
    required this.nameEn,
    required this.nameAr,
    required this.verseCount,
    required this.revelationType,
    this.nameTranslationEn,
  });

  final int number;
  final String nameEn;
  final String nameAr;
  final int verseCount;
  final String revelationType;
  final String? nameTranslationEn;

  factory SurahSummary.fromJson(Map<String, dynamic> j) {
    return SurahSummary(
      number: j['number'] as int,
      nameEn: j['englishName'] as String,
      nameAr: j['name'] as String,
      verseCount: j['numberOfAyahs'] as int,
      revelationType: j['revelationType'] as String,
      nameTranslationEn: j['englishNameTranslation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'englishName': nameEn,
        'name': nameAr,
        'numberOfAyahs': verseCount,
        'revelationType': revelationType,
        'englishNameTranslation': nameTranslationEn,
      };
}
