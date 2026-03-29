/// Réponse typique `GET /me` après inscription ou connexion.
class RemoteUserProfile {
  const RemoteUserProfile({
    required this.firstName,
    required this.email,
    this.hearAboutUs,
    this.ageRange,
  });

  final String firstName;
  final String email;
  final String? hearAboutUs;
  final String? ageRange;

  factory RemoteUserProfile.fromJson(Map<String, dynamic> j) {
    return RemoteUserProfile(
      firstName: j['firstName'] as String? ?? j['first_name'] as String? ?? '',
      email: j['email'] as String? ?? '',
      hearAboutUs: j['hearAboutUs'] as String? ?? j['hear_about_us'] as String?,
      ageRange: j['ageRange'] as String? ?? j['age_range'] as String?,
    );
  }
}

class RegisterResult {
  RegisterResult({
    required this.token,
    required this.user,
  });

  final String token;
  final RemoteUserProfile user;

  factory RegisterResult.fromJson(Map<String, dynamic> j) {
    final token = j['token'] as String? ??
        j['accessToken'] as String? ??
        j['access_token'] as String? ??
        '';
    final userRaw = j['user'] as Map<String, dynamic>? ?? j;
    return RegisterResult(
      token: token,
      user: RemoteUserProfile.fromJson(userRaw),
    );
  }
}
