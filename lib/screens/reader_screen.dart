import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ayah.dart';
import '../models/ayah_word_timings.dart';
import '../models/surah_summary.dart';
import '../services/bookmarks_store.dart';
import '../services/offline_surah_cache.dart';
import '../services/quran_api_service.dart';
import '../services/quran_com_api.dart';
import '../services/reading_progress.dart';
import '../theme/alfawz_colors.dart';
import '../theme/quran_arabic_text_style.dart';

enum ReaderAyahLoop { off, oneAyah, range }

/// Page « Soutenez-nous » — remplace par ton vrai lien (Ko-fi, site, etc.).
const String _alfawzSupportUrl = 'https://alfawz.app/soutien';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.surah,
    required this.initialAyah,
    required this.api,
    required this.quranComApi,
    this.offlineCache,
    required this.bookmarksStore,
    required this.progressStore,
    this.arabicFontSize = 26,
    this.surahBefore,
    this.surahAfter,
    this.onJumpToSurah,
  });

  final SurahSummary surah;
  final int initialAyah;
  final QuranApiService api;
  final QuranComApiService quranComApi;
  final OfflineSurahCache? offlineCache;
  final BookmarksStore bookmarksStore;
  final ReadingProgressStore progressStore;
  final double arabicFontSize;
  final SurahSummary? surahBefore;
  final SurahSummary? surahAfter;
  final void Function(SurahSummary surah, {int ayah})? onJumpToSurah;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late Future<
      ({
        List<Ayah> ayahs,
        List<String> audioUrls,
        Map<int, AyahWordTimings> wordTimings,
      })> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadContent();
  }

  ({
    List<Ayah> ayahs,
    List<String> audioUrls,
    Map<int, AyahWordTimings> wordTimings,
  }) _packPayload(SurahReaderPayload aligned) {
    if (aligned.ayahs.length != aligned.audioUrls.length) {
      throw Exception('Réponse alignée incohérente');
    }
    final wordTimings = {
      for (final t in aligned.wordTimings) t.numberInSurah: t,
    };
    return (
      ayahs: aligned.ayahs,
      audioUrls: aligned.audioUrls,
      wordTimings: wordTimings,
    );
  }

  Future<
      ({
        List<Ayah> ayahs,
        List<String> audioUrls,
        Map<int, AyahWordTimings> wordTimings,
      })> _loadContent() async {
    try {
      final aligned = await widget.quranComApi.fetchSurahAlignedContent(
        widget.surah.number,
      );
      return _packPayload(aligned);
    } catch (_) {
      final offline = await widget.offlineCache?.load(widget.surah.number);
      if (offline != null) {
        try {
          return _packPayload(offline);
        } catch (_) {}
      }
    }

    try {
      final results = await Future.wait([
        widget.api.fetchSurahAyahs(widget.surah.number),
        widget.api.fetchSurahAudioUrls(widget.surah.number),
      ]);
      final ayahs = results[0] as List<Ayah>;
      final urls = results[1] as List<String>;
      if (ayahs.length != urls.length) {
        throw Exception('Audio: nombre de versets incohérent');
      }
      var wordTimings = <int, AyahWordTimings>{};
      try {
        final tw = await widget.quranComApi.fetchSurahWordTimings(
          widget.surah.number,
        );
        wordTimings = {for (final t in tw) t.numberInSurah: t};
      } catch (_) {}
      return (ayahs: ayahs, audioUrls: urls, wordTimings: wordTimings);
    } catch (_) {
      final offline = await widget.offlineCache?.load(widget.surah.number);
      if (offline != null) return _packPayload(offline);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlfawzColors.surface,
      body: FutureBuilder<
          ({
            List<Ayah> ayahs,
            List<String> audioUrls,
            Map<int, AyahWordTimings> wordTimings,
          })>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erreur: ${snap.error}'),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          return _ReaderContent(
            surah: widget.surah,
            ayahs: data.ayahs,
            audioUrls: data.audioUrls,
            wordTimingsByAyah: data.wordTimings,
            initialAyah: widget.initialAyah,
            arabicFontSize: widget.arabicFontSize,
            progressStore: widget.progressStore,
            bookmarksStore: widget.bookmarksStore,
            quranComApi: widget.quranComApi,
            offlineCache: widget.offlineCache,
            surahBefore: widget.surahBefore,
            surahAfter: widget.surahAfter,
            onJumpToSurah: widget.onJumpToSurah,
          );
        },
      ),
    );
  }
}

class _ReaderContent extends StatefulWidget {
  const _ReaderContent({
    required this.surah,
    required this.ayahs,
    required this.audioUrls,
    required this.wordTimingsByAyah,
    required this.initialAyah,
    required this.arabicFontSize,
    required this.progressStore,
    required this.bookmarksStore,
    required this.quranComApi,
    this.offlineCache,
    required this.surahBefore,
    required this.surahAfter,
    required this.onJumpToSurah,
  });

  final SurahSummary surah;
  final List<Ayah> ayahs;
  final List<String> audioUrls;
  final Map<int, AyahWordTimings> wordTimingsByAyah;
  final int initialAyah;
  final double arabicFontSize;
  final ReadingProgressStore progressStore;
  final BookmarksStore bookmarksStore;
  final QuranComApiService quranComApi;
  final OfflineSurahCache? offlineCache;
  final SurahSummary? surahBefore;
  final SurahSummary? surahAfter;
  final void Function(SurahSummary surah, {int ayah})? onJumpToSurah;

  @override
  State<_ReaderContent> createState() => _ReaderContentState();
}

class _ReaderContentState extends State<_ReaderContent> {
  late final AudioPlayer _player;
  late final PageController _versePageController;
  /// Verset affiché (lecture silencieuse ou suivi de l’audio).
  late int _viewIndex;

  StreamSubscription<SequenceState?>? _seqSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  int? _currentTrackIndex;
  String? _audioPrepareError;
  var _audioReady = false;
  var _bookmarked = false;
  var _isSurahCached = false;
  int? _lastSavedAyah;

  ReaderAyahLoop _loopMode = ReaderAyahLoop.off;
  int? _loopRangeLo;
  int? _loopRangeHi;
  var _loopSeekCooldown = false;

  /// Numéro de verset affiché (signets, dialogues).
  int get _displayAyahNumber {
    if (widget.ayahs.isEmpty) return 1;
    final i = _viewIndex.clamp(0, widget.ayahs.length - 1);
    return widget.ayahs[i].numberInSurah;
  }

  /// Indice de piste (0-based) pour le numéro de verset dans [widget.ayahs].
  int? _playlistIndexForAyahNumber(int ayahNum) {
    final i = widget.ayahs.indexWhere((a) => a.numberInSurah == ayahNum);
    return i < 0 ? null : i;
  }

  /// [just_audio] sur le web : pas de [seek]/[play] dans le même tick qu’un
  /// callback de flux — sinon `Cannot fire new event. Controller is already firing`.
  Future<void> _deferAudioOp(Future<void> Function() op) async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await op();
  }

  @override
  void initState() {
    super.initState();
    final initI =
        widget.ayahs.indexWhere((a) => a.numberInSurah == widget.initialAyah);
    _viewIndex = initI >= 0 ? initI : 0;
    _versePageController = PageController(initialPage: _viewIndex);
    _player = AudioPlayer();
    _preparePlaylist();
    unawaited(_loadCachedFlag());
    unawaited(_syncBookmarkForAyah(_displayAyahNumber));
    _seqSub = _player.sequenceStateStream.listen((state) async {
      if (!mounted) return;
      final idx = state.currentIndex;
      if (_loopMode == ReaderAyahLoop.range &&
          _loopRangeLo != null &&
          _loopRangeHi != null &&
          idx != null &&
          !_loopSeekCooldown) {
        final endIdx = _playlistIndexForAyahNumber(_loopRangeHi!);
        final startIdx = _playlistIndexForAyahNumber(_loopRangeLo!);
        if (endIdx != null && startIdx != null && idx > endIdx) {
          _loopSeekCooldown = true;
          unawaited(() async {
            try {
              await _deferAudioOp(() async {
                await _player.seek(Duration.zero, index: startIdx);
                if (!mounted) return;
                setState(() {
                  _currentTrackIndex = startIdx;
                  _viewIndex = startIdx;
                });
                _syncPageAfterStateChange();
                if (!_player.playing) await _player.play();
              });
            } finally {
              await Future<void>.delayed(const Duration(milliseconds: 200));
              if (mounted) _loopSeekCooldown = false;
            }
            if (mounted) {
              _persistProgressForIndex(startIdx);
              unawaited(_syncBookmarkForAyah(_loopRangeLo!));
            }
          }());
          // Ne pas appliquer idx (piste hors plage) à l’état : cassait les tours suivants.
          return;
        }
      }
      if (idx != _currentTrackIndex) {
        if (_loopMode == ReaderAyahLoop.range &&
            _loopRangeHi != null &&
            idx != null) {
          final endIdx = _playlistIndexForAyahNumber(_loopRangeHi!);
          if (endIdx != null && idx > endIdx) {
            // Débordement géré par la position / seek — ignorer cet index fantôme.
            return;
          }
        }
        if (mounted) {
          setState(() {
            _currentTrackIndex = idx;
            if (idx != null) _viewIndex = idx;
          });
          if (idx != null) _syncPageAfterStateChange();
        } else {
          _currentTrackIndex = idx;
          if (idx != null) _viewIndex = idx;
        }
        _persistProgressForIndex(idx);
        if (idx != null &&
            idx >= 0 &&
            idx < widget.ayahs.length) {
          unawaited(
            _syncBookmarkForAyah(widget.ayahs[idx].numberInSurah),
          );
        }
      }
    });
    _posSub = _player.positionStream.listen((pos) async {
      if (!mounted || _loopSeekCooldown) return;

      if (_loopMode == ReaderAyahLoop.oneAyah) {
        final dur = _player.duration;
        if (dur == null || dur.inMilliseconds <= 0) return;
        if (pos.inMilliseconds < dur.inMilliseconds - 200) return;
        _loopSeekCooldown = true;
        unawaited(() async {
          try {
            await _deferAudioOp(() async {
              await _player.seek(Duration.zero);
            });
          } finally {
            await Future<void>.delayed(const Duration(milliseconds: 350));
            if (mounted) _loopSeekCooldown = false;
          }
        }());
        return;
      }

      if (_loopMode == ReaderAyahLoop.range &&
          _loopRangeLo != null &&
          _loopRangeHi != null) {
        final startIdx = _playlistIndexForAyahNumber(_loopRangeLo!);
        final endIdx = _playlistIndexForAyahNumber(_loopRangeHi!);
        final curIdx = _player.currentIndex;
        if (startIdx == null || endIdx == null || curIdx == null) return;
        if (curIdx != endIdx) return;
        final dur = _player.duration;
        if (dur == null || dur.inMilliseconds <= 0) return;
        if (pos.inMilliseconds < dur.inMilliseconds - 220) return;
        _loopSeekCooldown = true;
        unawaited(() async {
          try {
            await _deferAudioOp(() async {
              await _player.seek(Duration.zero, index: startIdx);
              if (!mounted) return;
              setState(() {
                _currentTrackIndex = startIdx;
                _viewIndex = startIdx;
              });
              _syncPageAfterStateChange();
              if (!_player.playing) await _player.play();
            });
          } finally {
            await Future<void>.delayed(const Duration(milliseconds: 380));
            if (mounted) _loopSeekCooldown = false;
          }
        }());
      }
    });
    _playerStateSub = _player.playerStateStream.listen((state) async {
      if (!mounted || _loopSeekCooldown) return;
      if (_loopMode != ReaderAyahLoop.range ||
          _loopRangeLo == null ||
          _loopRangeHi == null) {
        return;
      }
      if (state.processingState != ProcessingState.completed) return;
      final startIdx = _playlistIndexForAyahNumber(_loopRangeLo!);
      final endIdx = _playlistIndexForAyahNumber(_loopRangeHi!);
      final curIdx = _player.currentIndex;
      if (startIdx == null || endIdx == null || curIdx == null) return;
      if (curIdx != endIdx) return;
      _loopSeekCooldown = true;
      unawaited(() async {
        try {
          await _deferAudioOp(() async {
            await _player.seek(Duration.zero, index: startIdx);
            if (!mounted) return;
            setState(() {
              _currentTrackIndex = startIdx;
              _viewIndex = startIdx;
            });
            _syncPageAfterStateChange();
            await _player.play();
          });
        } finally {
          await Future<void>.delayed(const Duration(milliseconds: 380));
          if (mounted) _loopSeekCooldown = false;
        }
      }());
    });
  }

  Future<void> _loadCachedFlag() async {
    final c = widget.offlineCache;
    if (c == null) return;
    final ok = await c.hasSurah(widget.surah.number);
    if (mounted) setState(() => _isSurahCached = ok);
  }

  Future<void> _syncBookmarkForAyah(int ayah) async {
    final b =
        await widget.bookmarksStore.hasSingleBookmark(widget.surah.number, ayah);
    if (mounted) setState(() => _bookmarked = b);
  }

  Future<void> _toggleBookmark() async {
    final ayah = _displayAyahNumber;
    await widget.bookmarksStore.toggleSingle(widget.surah.number, ayah);
    await _syncBookmarkForAyah(ayah);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_bookmarked ? 'Signet ajouté' : 'Signet retiré'),
        ),
      );
    }
  }

  Future<void> _promptRangeBookmark() async {
    final cur = _displayAyahNumber;
    final last = widget.ayahs.last.numberInSurah;
    final startCtrl = TextEditingController(text: '$cur');
    final endCtrl = TextEditingController(text: '$cur');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Signet sur plage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startCtrl,
              decoration: const InputDecoration(labelText: 'Premier ayah'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: endCtrl,
              decoration: const InputDecoration(labelText: 'Dernier ayah'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final a = int.tryParse(startCtrl.text.trim());
    final b = int.tryParse(endCtrl.text.trim());
    if (a == null || b == null || a < 1 || b < 1 || a > last || b > last) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plage invalide')),
      );
      return;
    }
    await widget.bookmarksStore.addOrUpdateRange(widget.surah.number, a, b);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plage enregistrée dans Signets')),
      );
    }
  }

  Future<void> _promptLoopRange() async {
    final cur = _displayAyahNumber;
    final last = widget.ayahs.last.numberInSurah;
    final startCtrl = TextEditingController(text: '$cur');
    final endCtrl = TextEditingController(text: '$cur');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Répéter une plage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startCtrl,
              decoration: const InputDecoration(labelText: 'Du ayah'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: endCtrl,
              decoration: const InputDecoration(labelText: 'Au ayah'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Activer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final a = int.tryParse(startCtrl.text.trim());
    final b = int.tryParse(endCtrl.text.trim());
    if (a == null || b == null || a < 1 || b < 1 || a > last || b > last) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plage invalide')),
      );
      return;
    }
    final lo = a < b ? a : b;
    final hi = a < b ? b : a;
    final idx = _playlistIndexForAyahNumber(lo);
    setState(() {
      _loopMode = ReaderAyahLoop.range;
      _loopRangeLo = lo;
      _loopRangeHi = hi;
      if (idx != null) _viewIndex = idx;
    });
    _syncPageAfterStateChange();
    if (_audioReady && idx != null) {
      await _deferAudioOp(() async {
        await _player.seek(Duration.zero, index: idx);
      });
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Boucle ayahs $lo–$hi')),
      );
    }
  }

  Future<void> _downloadOffline() async {
    final cache = widget.offlineCache;
    if (cache == null) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Téléchargement…')),
    );
    try {
      final aligned = await widget.quranComApi.fetchSurahAlignedContent(
        widget.surah.number,
      );
      await cache.cacheFromPayload(widget.surah.number, aligned, (_) {});
      if (mounted) {
        setState(() => _isSurahCached = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sourate disponible hors-ligne')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec téléchargement : $e')),
        );
      }
    }
  }

  void _persistProgressForIndex(int? idx) {
    if (idx == null || idx < 0 || idx >= widget.ayahs.length) return;
    final ayahNum = widget.ayahs[idx].numberInSurah;
    if (_lastSavedAyah == ayahNum) return;
    _lastSavedAyah = ayahNum;
    unawaited(
      widget.progressStore.save(widget.surah.number, ayahNum),
    );
  }

  Future<void> _preparePlaylist() async {
    try {
      final sources = widget.audioUrls
          .map((u) => AudioSource.uri(Uri.parse(u)))
          .toList();
      await _player.setAudioSources(sources);
      final start = _viewIndex.clamp(0, sources.length - 1);
      if (start >= 0 && start < sources.length) {
        await _deferAudioOp(() async {
          await _player.seek(Duration.zero, index: start);
        });
      }
      if (mounted) {
        final pi = _player.currentIndex;
        setState(() {
          _audioReady = true;
          _audioPrepareError = null;
          _currentTrackIndex = pi;
          if (pi != null) _viewIndex = pi;
        });
        _syncPageAfterStateChange();
      }
      final idx = _player.currentIndex;
      _persistProgressForIndex(idx);
    } catch (e) {
      if (mounted) {
        setState(() {
          _audioPrepareError = '$e';
          _audioReady = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _seqSub?.cancel();
    _posSub?.cancel();
    _playerStateSub?.cancel();
    _versePageController.dispose();
    unawaited(_player.dispose());
    super.dispose();
  }

  void _syncPageAfterStateChange() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_versePageController.hasClients) return;
      final shown = _versePageController.page?.round() ?? _viewIndex;
      if (shown != _viewIndex) {
        _versePageController.jumpToPage(_viewIndex);
      }
    });
  }

  /// Navigation verset : marche **sans** audio ; si la piste est prête, [seek] aligné.
  void _goVerse({required bool next}) {
    final len = widget.ayahs.length;
    if (len == 0) return;
    final target = _viewIndex + (next ? 1 : -1);
    if (target < 0 || target >= len) return;
    setState(() => _viewIndex = target);
    if (_versePageController.hasClients) {
      _versePageController.jumpToPage(target);
    }
    _persistProgressForIndex(target);
    unawaited(_syncBookmarkForAyah(widget.ayahs[target].numberInSurah));
    if (_audioReady) {
      unawaited(_deferAudioOp(() async {
        await _player.seek(Duration.zero, index: target);
        if (mounted) setState(() => _currentTrackIndex = target);
      }));
    }
  }

  Future<void> _syncPlayToViewIndex() async {
    if (!_audioReady) return;
    final cur = _player.currentIndex;
    if (cur == _viewIndex) return;
    await _deferAudioOp(() async {
      await _player.seek(Duration.zero, index: _viewIndex);
      if (mounted) setState(() => _currentTrackIndex = _viewIndex);
    });
  }

  Future<void> _shareVerseAt(int index) async {
    if (index < 0 || index >= widget.ayahs.length) return;
    final a = widget.ayahs[index];
    final buffer = StringBuffer()
      ..writeln('${widget.surah.nameEn} — ${widget.surah.nameAr}')
      ..writeln(
        'Verset ${a.numberInSurah} / ${widget.ayahs.length}',
      )
      ..writeln()
      ..writeln(a.textAr)
      ..writeln()
      ..writeln(a.textEn)
      ..writeln()
      ..writeln('— Alfawz');
    await Share.share(buffer.toString().trim());
  }

  void _onVersePageChanged(int i) {
    if (i == _viewIndex) return;
    setState(() => _viewIndex = i);
    _persistProgressForIndex(i);
    unawaited(_syncBookmarkForAyah(widget.ayahs[i].numberInSurah));
    if (_audioReady) {
      unawaited(_deferAudioOp(() async {
        await _player.seek(Duration.zero, index: i);
        if (mounted) setState(() => _currentTrackIndex = i);
      }));
    }
  }

  Future<void> _openSupportPage() async {
    final uri = Uri.tryParse(_alfawzSupportUrl);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lien de soutien invalide (configurer dans le code).'),
          ),
        );
      }
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d’ouvrir le lien.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d’ouvrir le lien.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: ColoredBox(
              color: AlfawzColors.surface.withValues(alpha: 0.82),
              child: AppBar(
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  widget.surah.nameEn,
                  style: GoogleFonts.notoSerif(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AlfawzColors.primary,
                  ),
                ),
                actions: [
                  if (_isSurahCached)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.offline_pin_rounded, size: 22),
                    ),
                  IconButton(
                    icon: Icon(
                      _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    onPressed: _toggleBookmark,
                  ),
                  if (widget.offlineCache != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (v) {
                        if (v == 'dl') unawaited(_downloadOffline());
                        if (v == 'range') unawaited(_promptRangeBookmark());
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'dl',
                          child: Text('Télécharger pour hors-ligne'),
                        ),
                        const PopupMenuItem(
                          value: 'range',
                          child: Text('Signet sur plage…'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Column(
            children: [
              Text(
                widget.surah.nameAr,
                textDirection: TextDirection.rtl,
                style: QuranArabicStyle.ayah(22).copyWith(
                  color: AlfawzColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.surahBefore != null || widget.surahAfter != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.surahBefore != null)
                      TextButton(
                        onPressed: () => widget.onJumpToSurah?.call(
                          widget.surahBefore!,
                          ayah: 1,
                        ),
                        child: const Text('← Sourate préc.'),
                      ),
                    if (widget.surahAfter != null)
                      TextButton(
                        onPressed: () => widget.onJumpToSurah?.call(
                          widget.surahAfter!,
                          ayah: 1,
                        ),
                        child: const Text('Sourate suiv. →'),
                      ),
                  ],
                ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _versePageController,
            itemCount: widget.ayahs.length,
            onPageChanged: _onVersePageChanged,
            itemBuilder: (context, i) {
              final ayah = widget.ayahs[i];
              final audioHere = _audioReady && _currentTrackIndex == i;
              final timings = widget.wordTimingsByAyah[ayah.numberInSurah];
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Verset ${ayah.numberInSurah} · ${widget.ayahs.length}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: AlfawzColors.outline,
                        ),
                      ),
                    ),
                    _AyahBlock(
                      ayah: ayah,
                      wordTimings: timings,
                      audioPlayer: audioHere ? _player : null,
                      sajdaGlow: ayah.sajda,
                      arabicFontSize: widget.arabicFontSize,
                      highlighted: true,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _shareVerseAt(i),
                            icon: const Icon(
                              Icons.ios_share_rounded,
                              size: 20,
                              color: AlfawzColors.primary,
                            ),
                            label: Text(
                              'Partager',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AlfawzColors.primary,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              side: BorderSide(
                                color: AlfawzColors.primary
                                    .withValues(alpha: 0.35),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _openSupportPage,
                            icon: const Icon(
                              Icons.favorite_outline_rounded,
                              size: 20,
                              color: AlfawzColors.onSecondaryContainer,
                            ),
                            label: Text(
                              'Soutenez-nous',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AlfawzColors.secondaryContainer
                                  .withValues(alpha: 0.72),
                              foregroundColor:
                                  AlfawzColors.onSecondaryContainer,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _ReaderPlayerBar(
          ready: _audioReady,
          errorText: _audioPrepareError,
          player: _player,
          loopMode: _loopMode,
          onPrev: _viewIndex > 0 ? () => _goVerse(next: false) : null,
          onNext: _viewIndex < widget.ayahs.length - 1
              ? () => _goVerse(next: true)
              : null,
          beforePlay: _audioReady ? _syncPlayToViewIndex : null,
          onLoopMenuSelected: (mode) async {
            if (mode == ReaderAyahLoop.off) {
              setState(() {
                _loopMode = ReaderAyahLoop.off;
                _loopRangeLo = null;
                _loopRangeHi = null;
              });
              return;
            }
            if (mode == ReaderAyahLoop.oneAyah) {
              setState(() {
                _loopMode = ReaderAyahLoop.oneAyah;
                _loopRangeLo = null;
                _loopRangeHi = null;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Répétition : verset en cours')),
                );
              }
              return;
            }
            await _promptLoopRange();
          },
        ),
      ],
    );
  }
}

class _ReaderPlayerBar extends StatelessWidget {
  const _ReaderPlayerBar({
    required this.ready,
    required this.errorText,
    required this.player,
    required this.loopMode,
    this.onPrev,
    this.onNext,
    this.beforePlay,
    required this.onLoopMenuSelected,
  });

  final bool ready;
  final String? errorText;
  final AudioPlayer player;
  final ReaderAyahLoop loopMode;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final Future<void> Function()? beforePlay;
  final Future<void> Function(ReaderAyahLoop mode) onLoopMenuSelected;

  IconData get _loopIcon {
    switch (loopMode) {
      case ReaderAyahLoop.off:
        return Icons.repeat_rounded;
      case ReaderAyahLoop.oneAyah:
        return Icons.repeat_one_rounded;
      case ReaderAyahLoop.range:
        return Icons.loop_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorText != null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AlfawzColors.surface,
          border: Border(
            top: BorderSide(
              color: AlfawzColors.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Text(
              'Audio : $errorText',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AlfawzColors.error,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AlfawzColors.surface,
        border: Border(
          top: BorderSide(
            color: AlfawzColors.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              PopupMenuButton<ReaderAyahLoop>(
                enabled: ready,
                tooltip: 'Répétition',
                padding: const EdgeInsets.only(left: 4, right: 4),
                onSelected: (m) => onLoopMenuSelected(m),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: ReaderAyahLoop.off,
                    child: Text('Pas de répétition'),
                  ),
                  PopupMenuItem(
                    value: ReaderAyahLoop.oneAyah,
                    child: Text('Répéter le verset en cours'),
                  ),
                  PopupMenuItem(
                    value: ReaderAyahLoop.range,
                    child: Text('Répéter une plage…'),
                  ),
                ],
                child: Icon(
                  _loopIcon,
                  size: 24,
                  color: loopMode == ReaderAyahLoop.off
                      ? AlfawzColors.outline
                      : AlfawzColors.secondary,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: onPrev,
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 30,
                      color: AlfawzColors.primary,
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: StreamBuilder<PlayerState>(
                        stream: player.playerStateStream,
                        builder: (context, snap) {
                          final playing = snap.data?.playing ?? false;
                          return IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: ready
                                  ? AlfawzColors.primary
                                  : AlfawzColors.outlineVariant,
                              foregroundColor: ready
                                  ? AlfawzColors.onPrimary
                                  : AlfawzColors.outline,
                                                            fixedSize: const Size(54, 54),
                              minimumSize: const Size(54, 54),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: const CircleBorder(),
                            ),
                            onPressed: !ready
                                ? null
                                : () async {
                                    if (beforePlay != null) {
                                      await beforePlay!();
                                    }
                                    if (playing) {
                                      await player.pause();
                                    } else {
                                      await player.play();
                                    }
                                  },
                            icon: Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: onNext,
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 30,
                      color: AlfawzColors.primary,
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/// Texte arabe : bloc normal, ou surlignage **mot à mot** (style proche quran.com) si timings alignés.
class _AyahArabicWithTracking extends StatelessWidget {
  const _AyahArabicWithTracking({
    required this.ayah,
    required this.wordTimings,
    required this.audioPlayer,
    required this.arabicFontSize,
    required this.highlighted,
  });

  final Ayah ayah;
  final AyahWordTimings? wordTimings;
  final AudioPlayer? audioPlayer;
  final double arabicFontSize;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final plainStyle = QuranArabicStyle.ayah(arabicFontSize);
    final canWordHighlight = highlighted &&
        audioPlayer != null &&
        wordTimings != null &&
        wordTimings!.words.isNotEmpty &&
        wordTimings!.matchesAyahArabic(ayah.textAr);

    if (!canWordHighlight) {
      return Text(
        ayah.textAr,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: plainStyle,
      );
    }

    return _AyahArabicWordTracked(
      timings: wordTimings!,
      player: audioPlayer!,
      arabicFontSize: arabicFontSize,
    );
  }
}

/// Un span par mot : progression comme sur quran.com (mot actif mis en avant).
class _AyahArabicWordTracked extends StatelessWidget {
  const _AyahArabicWordTracked({
    required this.timings,
    required this.player,
    required this.arabicFontSize,
  });

  final AyahWordTimings timings;
  final AudioPlayer player;
  final double arabicFontSize;

  @override
  Widget build(BuildContext context) {
    final words = timings.words;
    final baseStyle = QuranArabicStyle.ayah(arabicFontSize);
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snap) {
        final ms = (snap.data ?? Duration.zero).inMilliseconds;
        final wix = timings.wordIndexAt(ms);
        return Text.rich(
          TextSpan(
            style: baseStyle,
            children: [
              for (var i = 0; i < words.length; i++) ...[
                TextSpan(
                  text: words[i].text,
                  style: baseStyle.copyWith(
                    backgroundColor: _wordHighlightColor(i, wix),
                  ),
                ),
                if (i < words.length - 1) TextSpan(text: ' ', style: baseStyle),
              ],
            ],
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        );
      },
    );
  }

  /// Mot en cours : fond plus marqué ; mots déjà lus : très léger ; à venir : aucun.
  static Color? _wordHighlightColor(int i, int activeIndex) {
    if (activeIndex < 0) return null;
    if (i == activeIndex) {
      return AlfawzColors.secondary.withValues(alpha: 0.34);
    }
    if (i < activeIndex) {
      return AlfawzColors.secondaryContainer.withValues(alpha: 0.22);
    }
    return null;
  }
}

class _AyahBlock extends StatelessWidget {
  const _AyahBlock({
    required this.ayah,
    required this.wordTimings,
    required this.audioPlayer,
    required this.sajdaGlow,
    required this.arabicFontSize,
    required this.highlighted,
  });

  final Ayah ayah;
  final AyahWordTimings? wordTimings;
  final AudioPlayer? audioPlayer;
  final bool sajdaGlow;
  final double arabicFontSize;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final card = Stack(
      clipBehavior: Clip.none,
      children: [
        if (sajdaGlow)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: -20),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AlfawzColors.tertiaryContainer
                          .withValues(alpha: 0.12),
                      blurRadius: 48,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                ayah.numberInSurah.toString().padLeft(2, '0'),
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AlfawzColors.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
            ),
            const SizedBox(height: 6),
            _AyahArabicWithTracking(
              ayah: ayah,
              wordTimings: wordTimings,
              audioPlayer: audioPlayer,
              arabicFontSize: arabicFontSize,
              highlighted: highlighted,
            ),
            if (highlighted && audioPlayer != null)
              wordTimings != null && wordTimings!.words.isNotEmpty
                  ? _AyahRecitationTracker(
                      player: audioPlayer!,
                      timings: wordTimings!,
                    )
                  : _AyahRecitationTrackerSimple(player: audioPlayer!),
            const SizedBox(height: 22),
            Text(
              ayah.textEn,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                height: 1.55,
                color: AlfawzColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );

    if (!highlighted) return card;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AlfawzColors.secondaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: card,
    );
  }
}

/// Barre de progression (timings verset) ; le surlignage des phrases est dans le texte arabe.
class _AyahRecitationTracker extends StatelessWidget {
  const _AyahRecitationTracker({
    required this.player,
    required this.timings,
  });

  final AudioPlayer player;
  final AyahWordTimings timings;

  @override
  Widget build(BuildContext context) {
    final total = timings.endMs.clamp(1, 1 << 30);
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, posSnap) {
        final ms = (posSnap.data ?? Duration.zero).inMilliseconds;
        final progress = (ms / total).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor:
                  AlfawzColors.outlineVariant.withValues(alpha: 0.28),
              color: AlfawzColors.secondary,
            ),
          ),
        );
      },
    );
  }
}

/// Sans timings Quran.com : seule la barre liée à la piste audio.
class _AyahRecitationTrackerSimple extends StatelessWidget {
  const _AyahRecitationTrackerSimple({required this.player});

  final AudioPlayer player;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: StreamBuilder<Duration>(
        stream: player.positionStream,
        builder: (context, posSnap) {
          return StreamBuilder<Duration?>(
            stream: player.durationStream,
            builder: (context, durSnap) {
              final pos = posSnap.data ?? Duration.zero;
              final dur = durSnap.data ?? Duration.zero;
              final maxMs = dur.inMilliseconds;
              final v = maxMs > 0
                  ? (pos.inMilliseconds / maxMs).clamp(0.0, 1.0)
                  : 0.0;
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 5,
                  backgroundColor:
                      AlfawzColors.outlineVariant.withValues(alpha: 0.28),
                  color: AlfawzColors.secondary,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
