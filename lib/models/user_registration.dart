/// Données envoyées à l’inscription (aligné sur un schéma REST classique).
class UserRegistration {
  const UserRegistration({
    required this.hearAboutUs,
    required this.ageRange,
    required this.firstName,
    required this.email,
  });

  final String hearAboutUs;
  final String ageRange;
  final String firstName;
  final String email;

  Map<String, dynamic> toJson() => {
        'hearAboutUs': hearAboutUs,
        'ageRange': ageRange,
        'firstName': firstName,
        'email': email,
      };
}
