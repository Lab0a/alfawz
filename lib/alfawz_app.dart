import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/reader_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'config/api_config.dart';
import 'theme/alfawz_colors.dart';
import 'models/remote_user_profile.dart';
import 'models/surah_summary.dart';
import 'services/bookmarks_store.dart';
import 'services/favorite_surahs_store.dart';
import 'models/user_registration.dart';
import 'services/alfawz_backend_api.dart';
import 'services/offline_surah_cache.dart';
import 'services/quran_api_service.dart';
import 'services/quran_com_api.dart';
import 'services/reading_progress.dart';
import 'services/surah_list_cache.dart';
import 'services/user_prefs_store.dart';
import 'theme/alfawz_theme.dart';
import 'widgets/alfawz_bottom_nav.dart';

bool _isLocalOnlyToken(String? t) => t != null && t.startsWith('local_');

class AlfawzApp extends StatefulWidget {
  const AlfawzApp({super.key});

  @override
  State<AlfawzApp> createState() => _AlfawzAppState();
}

class _AlfawzAppState extends State<AlfawzApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _api = QuranApiService();
  final _quranComApi = QuranComApiService();
  final _offlineSurahCache = OfflineSurahCache();
  final _progress = ReadingProgressStore();
  final _bookmarks = BookmarksStore();
  final _favSurahs = FavoriteSurahsStore();
  final _prefs = UserPrefsStore();
  final _backend = AlfawzBackendApi();

  AlfawzTab _tab = AlfawzTab.home;
  List<SurahSummary> _surahs = [];
  Set<int> _favoriteSurahs = {};
  /// `null` = préférences pas encore lues ; `false` = inscription à faire.
  bool? _registered;
  var _loading = false;
  String? _error;
  double _arabicFontSize = 26;
  bool _dailyReminder = true;
  int _homeRefreshEpoch = 0;
  String? _displayName;
  String? _email;
  String? _hearAboutUs;
  String? _ageRange;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (mounted) setState(() => _registered = null);
    final reg = await _prefs.loadRegistrationComplete();
    try {
      final results = await Future.wait([
        _favSurahs.load(),
        _prefs.loadArabicFontSize(),
        _prefs.loadDailyReminder(),
      ]);
      final fav = results[0] as Set<int>;
      final font = results[1] as double;
      final rem = results[2] as bool;
      if (!mounted) return;

      if (!reg) {
        setState(() {
          _registered = false;
          _displayName = null;
          _email = null;
          _hearAboutUs = null;
          _ageRange = null;
          _favoriteSurahs = fav;
          _arabicFontSize = font;
          _dailyReminder = rem;
          _error = null;
        });
        return;
      }

      final token = await _prefs.loadAuthToken();
      var name = await _prefs.loadDisplayName();
      var mail = await _prefs.loadEmail();
      var hear = await _prefs.loadHearAboutUs();
      var age = await _prefs.loadAgeRange();

      if (token != null &&
          token.isNotEmpty &&
          !_isLocalOnlyToken(token)) {
        try {
          final profile = await _backend.fetchProfile(token);
          await _prefs.applyProfileSnapshot(profile);
          name = await _prefs.loadDisplayName();
          mail = await _prefs.loadEmail();
          hear = await _prefs.loadHearAboutUs();
          age = await _prefs.loadAgeRange();
        } on AlfawzBackendException catch (e) {
          if (e.statusCode == 401 || e.statusCode == 403) {
            await _prefs.clearRegistration();
            if (!mounted) return;
            setState(() {
              _registered = false;
              _displayName = null;
              _email = null;
              _hearAboutUs = null;
              _ageRange = null;
              _favoriteSurahs = fav;
              _arabicFontSize = font;
              _dailyReminder = rem;
              _error = null;
            });
            return;
          }
        } catch (_) {
          /* hors ligne : garde le cache local */
        }
      }

      if (!mounted) return;
      setState(() {
        _registered = true;
        _displayName = name;
        _email = mail;
        _hearAboutUs = hear;
        _ageRange = age;
        _favoriteSurahs = fav;
        _arabicFontSize = font;
        _dailyReminder = rem;
        _loading = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
        _registered = reg;
      });
      return;
    }

    try {
      final surahs = await _api.fetchSurahList();
      await SurahListCache.save(surahs);
      if (!mounted) return;
      setState(() {
        _surahs = surahs;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      final cached = await SurahListCache.load();
      if (!mounted) return;
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _surahs = cached;
          _loading = false;
          _error = null;
        });
        return;
      }
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _onRegistrationComplete(UserRegistration data) async {
    RegisterResult? result;

    if (ApiConfig.isConfigured) {
      try {
        result = await _backend.register(data);
      } catch (e) {
        if (!ApiConfig.allowLocalRegistration) {
          if (mounted &&
              _navigatorKey.currentContext != null &&
              _navigatorKey.currentContext!.mounted) {
            ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
              SnackBar(content: Text('Inscription impossible : $e')),
            );
          }
          return;
        }
        if (mounted &&
            _navigatorKey.currentContext != null &&
            _navigatorKey.currentContext!.mounted) {
          ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
            const SnackBar(
              content: Text(
                'Serveur indisponible — compte créé sur cet appareil uniquement.',
              ),
            ),
          );
        }
      }
    }

    result ??= RegisterResult(
      token: 'local_${DateTime.now().microsecondsSinceEpoch}',
      user: RemoteUserProfile(
        firstName: data.firstName,
        email: data.email,
        hearAboutUs: data.hearAboutUs,
        ageRange: data.ageRange,
      ),
    );

    await _prefs.saveRemoteSession(
      token: result.token,
      profile: result.user,
      hearAboutUs: data.hearAboutUs,
      ageRange: data.ageRange,
    );

    if (!mounted) return;
    setState(() {
      _registered = true;
      _displayName = data.firstName;
      _email = data.email;
      _hearAboutUs = data.hearAboutUs;
      _ageRange = data.ageRange;
      _loading = true;
      _error = null;
    });
    try {
      final surahs = await _api.fetchSurahList();
      await SurahListCache.save(surahs);
      final fav = await _favSurahs.load();
      if (!mounted) return;
      setState(() {
        _surahs = surahs;
        _favoriteSurahs = fav;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      final cached = await SurahListCache.load();
      final fav = await _favSurahs.load();
      if (!mounted) return;
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _surahs = cached;
          _favoriteSurahs = fav;
          _loading = false;
          _error = null;
        });
        return;
      }
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _signOut() async {
    final t = await _prefs.loadAuthToken();
    if (t != null && t.isNotEmpty && !_isLocalOnlyToken(t)) {
      await _backend.logout(t);
    }
    await _prefs.clearRegistration();
    if (!mounted) return;
    setState(() {
      _registered = false;
      _displayName = null;
      _email = null;
      _hearAboutUs = null;
      _ageRange = null;
      _surahs = [];
      _tab = AlfawzTab.home;
      _error = null;
    });
  }

  Future<void> _retryLoadSurahs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final surahs = await _api.fetchSurahList();
      await SurahListCache.save(surahs);
      if (!mounted) return;
      setState(() {
        _surahs = surahs;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      final cached = await SurahListCache.load();
      if (!mounted) return;
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _surahs = cached;
          _loading = false;
          _error = null;
        });
        return;
      }
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _refreshLocalState() async {
    final fav = await _favSurahs.load();
    if (mounted) setState(() => _favoriteSurahs = fav);
  }

  void _openSurah(SurahSummary s, {int ayah = 1}) {
    final nav = _navigatorKey.currentState;
    if (nav == null) return;
    nav
        .push(
      MaterialPageRoute<void>(
        builder: (routeContext) {
          Widget buildReader(SurahSummary sur, {int ayah = 1}) {
            return ReaderScreen(
              surah: sur,
              initialAyah: ayah,
              api: _api,
              quranComApi: _quranComApi,
              offlineCache: _offlineSurahCache,
              bookmarksStore: _bookmarks,
              progressStore: _progress,
              arabicFontSize: _arabicFontSize,
              surahBefore:
                  sur.number > 1 ? _surahs[sur.number - 2] : null,
              surahAfter:
                  sur.number < 114 ? _surahs[sur.number] : null,
              onJumpToSurah: (next, {int ayah = 1}) {
                Navigator.of(routeContext).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => buildReader(next, ayah: ayah),
                  ),
                );
              },
            );
          }

          return buildReader(s, ayah: ayah);
        },
      ),
    )
        .then((_) {
      if (mounted) setState(() => _homeRefreshEpoch++);
    });
  }

  Future<void> _toggleFavorite(int n) async {
    await _favSurahs.toggle(n);
    await _refreshLocalState();
  }

  Future<void> _setArabicFontSize(double v) async {
    await _prefs.saveArabicFontSize(v);
    if (mounted) setState(() => _arabicFontSize = v);
  }

  Future<void> _setDailyReminder(bool v) async {
    await _prefs.saveDailyReminder(v);
    if (mounted) setState(() => _dailyReminder = v);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Alfawz',
      debugShowCheckedModeBanner: false,
      theme: AlfawzTheme.light(),
      home: _root(),
    );
  }

  Widget _root() {
    if (_registered == null) {
      return Scaffold(
        backgroundColor: AlfawzColors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_registered == false) {
      return RegistrationScreen(onComplete: _onRegistrationComplete);
    }
    if (_loading) {
      return Scaffold(
        backgroundColor: AlfawzColors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AlfawzColors.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Connexion ou données indisponibles.\n$_error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _retryLoadSurahs,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: _body(),
      bottomNavigationBar: AlfawzBottomNav(
        current: _tab,
        onSelect: (t) => setState(() => _tab = t),
      ),
    );
  }

  Widget _body() {
    switch (_tab) {
      case AlfawzTab.home:
        return HomeScreen(
          key: ValueKey(_homeRefreshEpoch),
          surahs: _surahs,
          api: _api,
          bookmarksStore: _bookmarks,
          progressStore: _progress,
          favoriteSurahs: _favoriteSurahs,
          onToggleFavorite: _toggleFavorite,
          onOpenSurah: _openSurah,
          onSearchTap: () => setState(() => _tab = AlfawzTab.search),
        );
      case AlfawzTab.search:
        return SearchScreen(
          surahs: _surahs,
          onOpenSurah: (s) => _openSurah(s, ayah: 1),
        );
      case AlfawzTab.library:
        return LibraryScreen(
          surahs: _surahs,
          favoriteNumbers: _favoriteSurahs,
          onOpenSurah: (s) => _openSurah(s, ayah: 1),
        );
      case AlfawzTab.settings:
        return SettingsScreen(
          displayName: _displayName,
          email: _email,
          hearAboutUs: _hearAboutUs,
          ageRange: _ageRange,
          onSignOut: _signOut,
          arabicFontSize: _arabicFontSize,
          onArabicFontSizeChanged: _setArabicFontSize,
          dailyReminder: _dailyReminder,
          onDailyReminderChanged: _setDailyReminder,
        );
    }
  }
}
