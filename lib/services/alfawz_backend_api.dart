import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/remote_user_profile.dart';
import '../models/user_registration.dart';

class AlfawzBackendException implements Exception {
  AlfawzBackendException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'Erreur API ($statusCode): ${_shortBody(body)}';
}

String _shortBody(String s) {
  if (s.length <= 120) return s;
  return '${s.substring(0, 120)}…';
}

/// Client HTTP vers **ton** serveur.
///
/// Contrat attendu (modifiable dans ce fichier si tes routes diffèrent) :
/// - En-tête optionnel `X-API-Key` : [ApiConfig.apiKey] (fictif en dev).
/// - `POST /api/v1/auth/register` — body JSON [UserRegistration.toJson], réponse JSON [RegisterResult.fromJson]
/// - `GET /api/v1/users/me` — `Authorization: Bearer <token utilisateur>`
class AlfawzBackendApi {
  AlfawzBackendApi({
    String? baseUrl,
    http.Client? client,
  })  : _base = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), ''),
        _client = client ?? http.Client();

  final String _base;
  final http.Client _client;

  Map<String, String> _headersJson() {
    final h = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    };
    final k = ApiConfig.apiKey.trim();
    if (k.isNotEmpty) {
      h['X-API-Key'] = k;
    }
    return h;
  }

  Map<String, String> _headersBearer(String bearerToken) {
    final h = <String, String>{
      'Authorization': 'Bearer $bearerToken',
      'Accept': 'application/json',
    };
    final k = ApiConfig.apiKey.trim();
    if (k.isNotEmpty) {
      h['X-API-Key'] = k;
    }
    return h;
  }

  /// Création de compte.
  Future<RegisterResult> register(UserRegistration data) async {
    final uri = Uri.parse('$_base/api/v1/auth/register');
    final r = await _client.post(
      uri,
      headers: _headersJson(),
      body: jsonEncode(data.toJson()),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw AlfawzBackendException(r.statusCode, r.body);
    }
    final map = jsonDecode(r.body) as Map<String, dynamic>;
    final result = RegisterResult.fromJson(map);
    if (result.token.isEmpty) {
      throw AlfawzBackendException(
        500,
        'Réponse serveur sans jeton (token / accessToken)',
      );
    }
    return result;
  }

  /// Profil courant (à rappeler au lancement pour resynchroniser l’UI).
  Future<RemoteUserProfile> fetchProfile(String bearerToken) async {
    final uri = Uri.parse('$_base/api/v1/users/me');
    final r = await _client.get(
      uri,
      headers: _headersBearer(bearerToken),
    );
    if (r.statusCode == 401 || r.statusCode == 403) {
      throw AlfawzBackendException(r.statusCode, r.body);
    }
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw AlfawzBackendException(r.statusCode, r.body);
    }
    final map = jsonDecode(r.body) as Map<String, dynamic>;
    final inner = map['user'] as Map<String, dynamic>? ?? map;
    return RemoteUserProfile.fromJson(inner);
  }

  /// Optionnel : invalider le jeton côté serveur.
  Future<void> logout(String bearerToken) async {
    try {
      final uri = Uri.parse('$_base/api/v1/auth/logout');
      await _client.post(
        uri,
        headers: _headersBearer(bearerToken),
      );
    } catch (_) {}
  }
}
