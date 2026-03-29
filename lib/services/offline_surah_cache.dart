import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/ayah.dart';
import '../models/ayah_word_timings.dart';
import 'quran_com_api.dart';

/// Cache disque : texte + timings + MP3 par verset pour une sourate.
class OfflineSurahCache {
  OfflineSurahCache({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;
  static const _version = 1;

  Future<Directory> _surahDir(int surahNumber) async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}offline_surah_$surahNumber');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _payloadFile(int surahNumber) async {
    final d = await _surahDir(surahNumber);
    return File('${d.path}${Platform.pathSeparator}payload.json');
  }

  /// Indique si un cache valide est présent sur l’appareil.
  Future<bool> hasSurah(int surahNumber) async {
    final f = await _payloadFile(surahNumber);
    if (!await f.exists()) return false;
    try {
      final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return (j['version'] as int?) == _version;
    } catch (_) {
      return false;
    }
  }

  /// Charge [SurahReaderPayload] avec chemins `file://` pour l’audio.
  Future<SurahReaderPayload?> load(int surahNumber) async {
    if (!await hasSurah(surahNumber)) return null;
    final dir = await _surahDir(surahNumber);
    final f = File('${dir.path}${Platform.pathSeparator}payload.json');
    try {
      final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      if ((data['version'] as int?) != _version) return null;
      final ayahs = (data['ayahs'] as List<dynamic>)
          .map((e) => Ayah.fromJson(e as Map<String, dynamic>))
          .toList();
      final rels = (data['audioFiles'] as List<dynamic>).cast<String>();
      final urls = rels
          .map((r) => File('${dir.path}${Platform.pathSeparator}$r').uri.toString())
          .toList();
      final timingsRaw = data['wordTimings'] as List<dynamic>? ?? [];
      final wordTimings = timingsRaw
          .map((e) => AyahWordTimings.fromJson(e as Map<String, dynamic>))
          .toList();
      if (ayahs.length != urls.length) return null;
      for (final u in urls) {
        final path = Uri.parse(u).toFilePath();
        if (!File(path).existsSync()) return null;
      }
      return SurahReaderPayload(
        ayahs: ayahs,
        audioUrls: urls,
        wordTimings: wordTimings,
      );
    } catch (_) {
      return null;
    }
  }

  /// Télécharge les MP3 et enregistre le JSON (à appeler en ligne).
  Future<void> cacheFromPayload(
    int surahNumber,
    SurahReaderPayload payload,
    void Function(double progress)? onProgress,
  ) async {
    final dir = await _surahDir(surahNumber);
    final n = payload.ayahs.length;
    if (n != payload.audioUrls.length) {
      throw StateError('Payload incohérent');
    }
    final audioFiles = <String>[];
    for (var i = 0; i < n; i++) {
      final ayahNum = payload.ayahs[i].numberInSurah;
      final name = ayahNum.toString().padLeft(3, '0');
      final rel = '$name.mp3';
      audioFiles.add(rel);
      final out = File('${dir.path}${Platform.pathSeparator}$rel');
      final url = payload.audioUrls[i];
      if (url.isEmpty) {
        throw Exception('URL audio manquante (ayah $ayahNum)');
      }
      if (url.startsWith('file:')) {
        await File(Uri.parse(url).toFilePath()).copy(out.path);
      } else {
        final r = await _client.get(Uri.parse(url));
        if (r.statusCode != 200) {
          throw Exception('Téléchargement audio $ayahNum: ${r.statusCode}');
        }
        await out.writeAsBytes(r.bodyBytes);
      }
      onProgress?.call((i + 1) / n);
    }
    final wordTimingsJson = payload.wordTimings.map((t) => t.toJson()).toList();
    final map = <String, dynamic>{
      'version': _version,
      'surah': surahNumber,
      'ayahs': payload.ayahs.map((a) => a.toJson()).toList(),
      'audioFiles': audioFiles,
      'wordTimings': wordTimingsJson,
    };
    final f = File('${dir.path}${Platform.pathSeparator}payload.json');
    await f.writeAsString(jsonEncode(map));
  }

  Future<void> deleteSurah(int surahNumber) async {
    final root = await getApplicationSupportDirectory();
    final d = Directory(
      '${root.path}${Platform.pathSeparator}offline_surah_$surahNumber',
    );
    if (await d.exists()) await d.delete(recursive: true);
  }
}
