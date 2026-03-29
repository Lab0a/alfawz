import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/surah_summary.dart';
import '../services/bookmarks_store.dart';
import '../services/quran_api_service.dart';
import '../services/reading_progress.dart';
import '../theme/alfawz_colors.dart';
import '../theme/quran_arabic_text_style.dart';
import '../widgets/glass_sliver_app_bar.dart';

enum HomeListTab { surah, juz, bookmarks }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.surahs,
    required this.api,
    required this.bookmarksStore,
    required this.progressStore,
    required this.onOpenSurah,
    required this.onSearchTap,
    required this.favoriteSurahs,
    required this.onToggleFavorite,
  });

  final List<SurahSummary> surahs;
  final QuranApiService api;
  final BookmarksStore bookmarksStore;
  final ReadingProgressStore progressStore;
  final void Function(SurahSummary surah, {int ayah}) onOpenSurah;
  final VoidCallback onSearchTap;
  final Set<int> favoriteSurahs;
  final void Function(int surahNumber) onToggleFavorite;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  HomeListTab _tab = HomeListTab.surah;
  ReadingProgress? _lastRead;
  Set<String> _bookmarkKeys = {};

  @override
  void initState() {
    super.initState();
    _reloadProgress();
  }

  Future<void> _reloadProgress() async {
    final p = await widget.progressStore.load();
    final b = await widget.bookmarksStore.loadKeys();
    if (mounted) {
      setState(() {
        _lastRead = p;
        _bookmarkKeys = b;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SurahSummary> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return widget.surahs;
    return widget.surahs.where((s) {
      return s.nameEn.toLowerCase().contains(q) ||
          s.number.toString() == q ||
          (s.nameTranslationEn?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  SurahSummary? _surahByNumber(int n) {
    try {
      return widget.surahs.firstWhere((s) => s.number == n);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            GlassSliverAppBar(
              title: 'Alfawz',
              actions: [
                IconButton(
                  onPressed: widget.onSearchTap,
                  icon: const Icon(Icons.search_rounded),
                  color: AlfawzColors.primary,
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _searchField(),
                  const SizedBox(height: 22),
                  _lastReadCard(),
                  const SizedBox(height: 26),
                  _tabRow(),
                  const SizedBox(height: 18),
                  ..._tabBody(),
                ]),
              ),
            ),
          ],
        ),
        Positioned(
          right: 22,
          bottom: 96,
          child: FloatingActionButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Lecture audio — à brancher (récitateur, flux…)',
                  ),
                ),
              );
            },
            backgroundColor: AlfawzColors.secondaryContainer,
            foregroundColor: AlfawzColors.onSecondaryContainer,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.mic_rounded, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (_) => setState(() {}),
      cursorColor: AlfawzColors.secondary,
      decoration: InputDecoration(
        hintText: 'Recherche sourate, juz, ayah…',
        prefixIcon: const Icon(Icons.search_rounded, color: AlfawzColors.outline),
      ),
    );
  }

  Widget _lastReadCard() {
    final pr = _lastRead;
    final surah = pr != null ? _surahByNumber(pr.surahNumber) : null;
    if (surah == null && pr != null) {
      // Liste pas encore chargée
    }
    if (pr == null || surah == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [AlfawzColors.primaryContainer, AlfawzColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AlfawzColors.primary.withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book_rounded, color: AlfawzColors.secondaryContainer),
                const SizedBox(width: 8),
                Text(
                  'DERNIÈRE LECTURE',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: AlfawzColors.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Commencez une sourate',
              style: GoogleFonts.notoSerif(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AlfawzColors.onPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre position sera mémorisée ici.',
              style: GoogleFonts.plusJakartaSans(
                color: AlfawzColors.onPrimary.withValues(alpha: 0.88),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => widget.onOpenSurah(surah, ayah: pr.ayahNumber),
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [AlfawzColors.primaryContainer, AlfawzColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AlfawzColors.primary.withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: Opacity(
                opacity: 0.12,
                child: Text(
                  surah.nameAr,
                  style: QuranArabicStyle.ayah(52, height: 1),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book_rounded,
                        color: AlfawzColors.secondaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      'DERNIÈRE LECTURE',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: AlfawzColors.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  surah.nameEn,
                  style: GoogleFonts.notoSerif(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AlfawzColors.onPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ayah ${pr.ayahNumber}',
                  style: GoogleFonts.plusJakartaSans(
                    color: AlfawzColors.secondaryContainer.withValues(alpha: 0.95),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AlfawzColors.secondaryContainer,
                    foregroundColor: AlfawzColors.onSecondaryContainer,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () =>
                      widget.onOpenSurah(surah, ayah: pr.ayahNumber),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: Text(
                    'Continuer',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabRow() {
    Widget tab(String label, HomeListTab t) {
      final on = _tab == t;
      return Expanded(
        child: InkWell(
          onTap: () {
            setState(() => _tab = t);
            if (t == HomeListTab.bookmarks) _reloadProgress();
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.notoSerif(
                  fontSize: 19,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  color: on ? AlfawzColors.primary : AlfawzColors.outline,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 3,
                decoration: BoxDecoration(
                  color: on ? AlfawzColors.secondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tab('Sourate', HomeListTab.surah),
        tab('Juz', HomeListTab.juz),
        tab('Signets', HomeListTab.bookmarks),
      ],
    );
  }

  List<Widget> _tabBody() {
    switch (_tab) {
      case HomeListTab.surah:
        return _filtered
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _surahTile(s),
                ))
            .toList();
      case HomeListTab.juz:
        return List.generate(
          30,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _juzTile(i + 1),
          ),
        );
      case HomeListTab.bookmarks:
        final entries = _bookmarkKeys
            .map(BookmarkEntry.parse)
            .whereType<BookmarkEntry>()
            .toList()
          ..sort((a, b) =>
              a.surahNumber != b.surahNumber
                  ? a.surahNumber.compareTo(b.surahNumber)
                  : a.startAyah.compareTo(b.startAyah));
        if (entries.isEmpty) {
          return [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Aucun signet. Ouvrez une sourate et utilisez l’icône dans l’en-tête.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ];
        }
        return entries.map((e) {
          final s = _surahByNumber(e.surahNumber);
          if (s == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: AlfawzColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              child: ListTile(
                title: Text(s.nameEn, style: GoogleFonts.notoSerif()),
                subtitle: Text(
                  e.isRange
                      ? 'Ayahs ${e.startAyah}–${e.endAyah}'
                      : 'Ayah ${e.startAyah}',
                ),
                trailing: Text(
                  s.nameAr,
                  style: QuranArabicStyle.ayah(20).copyWith(
                    color: AlfawzColors.primaryContainer,
                  ),
                ),
                onTap: () => widget.onOpenSurah(s, ayah: e.startAyah),
              ),
            ),
          );
        }).toList();
    }
  }

  Widget _juzTile(int juz) {
    return Material(
      color: AlfawzColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          try {
            final start = await widget.api.fetchJuzStart(juz);
            final s = _surahByNumber(start.surahNumber);
            if (s != null && mounted) {
              widget.onOpenSurah(s, ayah: start.ayahNumber);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Juz: $e')),
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AlfawzColors.secondary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '$juz',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: AlfawzColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Juz $juz',
                style: GoogleFonts.notoSerif(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AlfawzColors.primary,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: AlfawzColors.outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _surahTile(SurahSummary s) {
    final fav = widget.favoriteSurahs.contains(s.number);
    return Material(
      color: AlfawzColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => widget.onOpenSurah(s, ayah: 1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              _surahNumberOrnament(s.number),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.nameEn,
                      style: GoogleFonts.notoSerif(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AlfawzColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.nameTranslationEn ?? s.revelationType} • ${s.verseCount} versets',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        letterSpacing: 1.4,
                        color: AlfawzColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    s.nameAr,
                    style: QuranArabicStyle.ayah(22).copyWith(
                      color: AlfawzColors.primaryContainer,
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onToggleFavorite(s.number),
                    icon: Icon(
                      fav ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: fav
                          ? AlfawzColors.secondary
                          : AlfawzColors.secondary.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _surahNumberOrnament(int n) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.785,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AlfawzColors.secondary.withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
          Text(
            '$n',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: AlfawzColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
