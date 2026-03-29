import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/surah_summary.dart';
import '../theme/alfawz_colors.dart';
import '../theme/quran_arabic_text_style.dart';
import '../widgets/glass_sliver_app_bar.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    super.key,
    required this.surahs,
    required this.favoriteNumbers,
    required this.onOpenSurah,
  });

  final List<SurahSummary> surahs;
  final Set<int> favoriteNumbers;
  final void Function(SurahSummary surah) onOpenSurah;

  @override
  Widget build(BuildContext context) {
    final favs = surahs.where((s) => favoriteNumbers.contains(s.number)).toList();

    return CustomScrollView(
      slivers: [
        const GlassSliverAppBar(title: 'Bibliothèque'),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'Sourates favorites',
                style: GoogleFonts.notoSerif(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AlfawzColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Étoilées depuis l’accueil',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              if (favs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Ajoutez des sourates via l’icône étoile sur l’écran d’accueil.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ...favs.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: AlfawzColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AlfawzColors.secondaryContainer,
                        child: Text(
                          '${s.number}',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            color: AlfawzColors.onSecondaryContainer,
                          ),
                        ),
                      ),
                      title: Text(
                        s.nameEn,
                        style: GoogleFonts.notoSerif(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(s.nameTranslationEn ?? ''),
                      trailing: Text(
                        s.nameAr,
                        style: QuranArabicStyle.ayah(20).copyWith(
                          color: AlfawzColors.primaryContainer,
                        ),
                      ),
                      onTap: () => onOpenSurah(s),
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
}
