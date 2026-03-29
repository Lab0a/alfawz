import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/surah_summary.dart';

/// Dernière liste de sourates réussie (lecture hors-ligne minimale).
class SurahListCache {
  static const _k = 'alfawz_surah_list_json_v1';

  static Future<void> save(List<SurahSummary> surahs) async {
    final p = await SharedPreferences.getInstance();
    final list = surahs.map((s) => s.toJson()).toList();
    await p.setString(_k, jsonEncode(list));
  }

  static Future<List<SurahSummary>?> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_k);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SurahSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
