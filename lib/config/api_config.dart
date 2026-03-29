/// Configuration du **backend Alfawz**.
///
/// Build (exemple) :
/// `flutter run --dart-define=ALFAWZ_API_BASE=https://api.mondomaine.com --dart-define=ALFAWZ_API_KEY=...`
/// Sans slash final pour l’URL.
// ignore: avoid_classes_with_only_static_members
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'ALFAWZ_API_BASE',
    defaultValue: '',
  );

  /// Clé **fictive** pour les tests (à remplacer en prod par `--dart-define` ou secrets).
  /// Envoyée dans l’en-tête `X-API-Key`.
  static const String apiKey = String.fromEnvironment(
    'ALFAWZ_API_KEY',
    defaultValue: 'alfawz-test-sk-7f3c9e2a1b8d4e6f0a5c-example-only',
  );

  static bool get isConfigured => baseUrl.trim().isNotEmpty;

  /// Si `true` (défaut), tu peux **créer un compte sans backend** : session enregistrée sur l’appareil
  /// avec un jeton `local_…`. Désactive en prod stricte : `--dart-define=ALFAWZ_ALLOW_LOCAL_ONLY=false`.
  static const bool allowLocalRegistration = bool.fromEnvironment(
    'ALFAWZ_ALLOW_LOCAL_ONLY',
    defaultValue: true,
  );

  /// Inscription autorisée (serveur configuré ou mode local).
  static bool get canRegister => isConfigured || allowLocalRegistration;
}
