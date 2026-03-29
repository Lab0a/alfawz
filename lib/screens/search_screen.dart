import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/surah_summary.dart';
import '../theme/alfawz_colors.dart';
import '../theme/quran_arabic_text_style.dart';
import '../widgets/glass_sliver_app_bar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.surahs,
    required this.onOpenSurah,
    this.onGoHome,
  });

  final List<SurahSummary> surahs;
  final void Function(SurahSummary surah) onOpenSurah;
  final VoidCallback? onGoHome;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<SurahSummary> get _hits {
    final q = _ctrl.text.trim().toLowerCase();
    if (q.isEmpty) return [];
    return widget.surahs.where((s) {
      return s.nameEn.toLowerCase().contains(q) ||
          s.number.toString() == q ||
          s.nameAr.contains(q) ||
          (s.nameTranslationEn?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        GlassSliverAppBar(
          title: 'Alfawz',
          leading: widget.onGoHome == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  color: AlfawzColors.primary,
                  onPressed: widget.onGoHome,
                ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              TextField(
                controller: _ctrl,
                onChanged: (_) => setState(() {}),
                cursorColor: AlfawzColors.secondary,
                decoration: const InputDecoration(
                  hintText: 'Sourates, versets ou mots-clés…',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AlfawzColors.outline,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Explorer',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 14),
              _bentoGrid(context),
              const SizedBox(height: 36),
              Text(
                'Sourates',
                style: GoogleFonts.notoSerif(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AlfawzColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              if (_ctrl.text.isEmpty)
                Text(
                  'Tapez pour filtrer les 114 sourates.',
                  style: Theme.of(context).textTheme.bodyLarge,
                )
              else if (_hits.isEmpty)
                Text(
                  'Aucun résultat.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ..._hits.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: AlfawzColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                    child: ListTile(
                      title: Text(
                        s.nameEn,
                        style: GoogleFonts.notoSerif(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${s.nameTranslationEn ?? ''} • ${s.verseCount} versets',
                        style: GoogleFonts.manrope(fontSize: 11),
                      ),
                      trailing: Text(
                        s.nameAr,
                        style: QuranArabicStyle.ayah(18).copyWith(
                          color: AlfawzColors.primaryContainer,
                        ),
                      ),
                      onTap: () => widget.onOpenSurah(s),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _bentoGrid(BuildContext context) {
    Widget cell(IconData icon, String meta, String title) {
      return Material(
        color: AlfawzColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title — bientôt')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: AlfawzColors.primary, size: 28),
                    Text(
                      meta,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AlfawzColors.primary.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.notoSerif(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AlfawzColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        if (w > 520) {
          return SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(child: cell(Icons.bookmark_rounded, 'Signets', 'Versets sauvegardés')),
                const SizedBox(width: 12),
                Expanded(child: cell(Icons.history_rounded, 'Récent', 'Historique')),
                const SizedBox(width: 12),
                Expanded(child: cell(Icons.trending_up_rounded, 'Tendances', 'Recherches')),
              ],
            ),
          );
        }
        return Column(
          children: [
            SizedBox(height: 130, child: cell(Icons.bookmark_rounded, 'Signets', 'Versets sauvegardés')),
            const SizedBox(height: 12),
            SizedBox(height: 130, child: cell(Icons.history_rounded, 'Récent', 'Historique')),
            const SizedBox(height: 12),
            SizedBox(height: 130, child: cell(Icons.trending_up_rounded, 'Tendances', 'Recherches')),
          ],
        );
      },
    );
  }
}
