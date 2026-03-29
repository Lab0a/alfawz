import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/signup_options.dart';
import '../theme/alfawz_colors.dart';
import '../widgets/glass_sliver_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.displayName,
    this.email,
    this.hearAboutUs,
    this.ageRange,
    required this.onSignOut,
    required this.arabicFontSize,
    required this.onArabicFontSizeChanged,
    required this.dailyReminder,
    required this.onDailyReminderChanged,
  });

  final String? displayName;
  final String? email;
  final String? hearAboutUs;
  final String? ageRange;
  final Future<void> Function() onSignOut;
  final double arabicFontSize;
  final ValueChanged<double> onArabicFontSizeChanged;
  final bool dailyReminder;
  final ValueChanged<bool> onDailyReminderChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const GlassSliverAppBar(title: 'Alfawz'),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'Réglages',
                style: GoogleFonts.notoSerif(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AlfawzColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Personnalisez votre lecture',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  letterSpacing: 1.4,
                  color: AlfawzColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              _sectionTitle('Compte'),
              _panel([
                _accountCard(context),
              ]),
              const SizedBox(height: 22),
              _sectionTitle('Apparence'),
              _panel([
                _tile(
                  Icons.contrast_rounded,
                  'Thème',
                  'Système (auto)',
                  () {},
                ),
                _tile(
                  Icons.font_download_rounded,
                  'Police arabe',
                  'Uthmani (API)',
                  () {},
                ),
                _fontSizeCard(),
              ]),
              const SizedBox(height: 22),
              _sectionTitle('Contenu & audio'),
              _panel([
                _tile(
                  Icons.translate_rounded,
                  'Traduction',
                  'Anglais (Sahih International)',
                  () {},
                ),
                _tile(
                  Icons.mic_rounded,
                  'Récitateur',
                  'Mishary Rashid Alafasy',
                  () {},
                ),
              ]),
              const SizedBox(height: 22),
              _sectionTitle('Engagement'),
              _panel([
                _reminderTile(),
              ]),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AlfawzColors.surfaceContainerHigh.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Synchronisation cloud entre appareils : bientôt. '
                  'Pour l’instant, tout reste stocké localement.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AlfawzColors.onSurfaceVariant,
                      ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _accountCard(BuildContext context) {
    final name = widget.displayName ?? '—';
    final mail = widget.email;
    final meta = <String>[];
    if (widget.hearAboutUs != null && widget.hearAboutUs!.isNotEmpty) {
      meta.add('Découverte : ${labelForHearAbout(widget.hearAboutUs!)}');
    }
    if (widget.ageRange != null && widget.ageRange!.isNotEmpty) {
      meta.add(labelForAgeRange(widget.ageRange!));
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AlfawzColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AlfawzColors.secondaryContainer,
                child: Icon(
                  Icons.person_rounded,
                  color: AlfawzColors.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (mail != null && mail.isNotEmpty)
                      Text(
                        mail,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        meta.join(' · '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: AlfawzColors.outline,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final go = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Se déconnecter ?'),
                  content: const Text(
                    'Votre profil local sera effacé. Vous devrez vous réinscrire sur cet appareil.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Déconnecter'),
                    ),
                  ],
                ),
              );
              if (go == true && context.mounted) {
                await widget.onSignOut();
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Se déconnecter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AlfawzColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        t.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
          color: AlfawzColors.secondary,
        ),
      ),
    );
  }

  Widget _panel(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AlfawzColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(children: _spaced(children)),
    );
  }

  List<Widget> _spaced(List<Widget> w) {
    final out = <Widget>[];
    for (var i = 0; i < w.length; i++) {
      out.add(w[i]);
      if (i < w.length - 1) out.add(const SizedBox(height: 4));
    }
    return out;
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: AlfawzColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AlfawzColors.surfaceContainerHigh,
                child: Icon(icon, color: AlfawzColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AlfawzColors.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fontSizeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AlfawzColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AlfawzColors.surfaceContainerHigh,
                child: Icon(
                  Icons.format_size_rounded,
                  color: AlfawzColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Taille du texte arabe',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Slider(
            value: widget.arabicFontSize,
            min: 20,
            max: 36,
            divisions: 16,
            onChanged: widget.onArabicFontSizeChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PETIT',
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  color: AlfawzColors.onSurfaceVariant,
                ),
              ),
              Text(
                'GRAND',
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  color: AlfawzColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reminderTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AlfawzColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AlfawzColors.surfaceContainerHigh,
            child: Icon(
              Icons.notifications_active_rounded,
              color: AlfawzColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rappel quotidien',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
                Text(
                  '08:30 (exemple)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: widget.dailyReminder,
            onChanged: widget.onDailyReminderChanged,
          ),
        ],
      ),
    );
  }
}
