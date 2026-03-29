/// Valeurs `id` envoyées au backend — garde les mêmes clés côté API.
class SignupOption {
  const SignupOption({required this.id, required this.label});

  final String id;
  final String label;
}

const hearAboutUsOptions = [
  SignupOption(id: 'instagram', label: 'Instagram'),
  SignupOption(id: 'tiktok', label: 'TikTok'),
  SignupOption(id: 'friend_family', label: 'Bouche-à-oreille / proches'),
  SignupOption(id: 'search', label: 'Recherche web (Google, etc.)'),
  SignupOption(id: 'youtube', label: 'YouTube'),
  SignupOption(id: 'podcast', label: 'Podcast / radio'),
  SignupOption(id: 'article_blog', label: 'Article ou blog'),
  SignupOption(id: 'other', label: 'Autre'),
];

const ageRangeOptions = [
  SignupOption(id: 'under_18', label: 'Moins de 18 ans'),
  SignupOption(id: '18_24', label: '18 – 24 ans'),
  SignupOption(id: '25_34', label: '25 – 34 ans'),
  SignupOption(id: '35_44', label: '35 – 44 ans'),
  SignupOption(id: '45_54', label: '45 – 54 ans'),
  SignupOption(id: '55_plus', label: '55 ans et +'),
  SignupOption(id: 'prefer_not_say', label: 'Je préfère ne pas dire'),
];

String labelForHearAbout(String id) {
  for (final o in hearAboutUsOptions) {
    if (o.id == id) return o.label;
  }
  return id;
}

String labelForAgeRange(String id) {
  for (final o in ageRangeOptions) {
    if (o.id == id) return o.label;
  }
  return id;
}
