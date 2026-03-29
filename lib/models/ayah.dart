class Ayah {
  const Ayah({
    required this.numberInSurah,
    required this.textAr,
    required this.textEn,
    this.sajda = false,
  });

  final int numberInSurah;
  final String textAr;
  final String textEn;
  final bool sajda;

  Map<String, dynamic> toJson() => {
        'numberInSurah': numberInSurah,
        'textAr': textAr,
        'textEn': textEn,
        'sajda': sajda,
      };

  factory Ayah.fromJson(Map<String, dynamic> j) {
    return Ayah(
      numberInSurah: j['numberInSurah'] as int,
      textAr: j['textAr'] as String,
      textEn: j['textEn'] as String,
      sajda: j['sajda'] as bool? ?? false,
    );
  }
}
