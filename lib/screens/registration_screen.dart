import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/api_config.dart';
import '../data/signup_options.dart';
import '../models/user_registration.dart';
import '../theme/alfawz_colors.dart';

/// Inscription multi-étapes puis envoi au backend.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({
    super.key,
    required this.onComplete,
  });

  final Future<void> Function(UserRegistration data) onComplete;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _page = PageController();
  final _firstNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  var _step = 0;
  String? _hearAboutId;
  String? _ageRangeId;
  var _acceptTerms = false;
  var _submitting = false;

  static const _totalSteps = 4;
  static final _emailRe = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  @override
  void dispose() {
    _page.dispose();
    _firstNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    if (i < 0 || i >= _totalSteps) return;
    setState(() => _step = i);
    _page.animateToPage(
      i,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_step == 0 && _hearAboutId == null) {
      _toast('Choisis une option pour continuer.');
      return;
    }
    if (_step == 1 && _ageRangeId == null) {
      _toast('Indique ta tranche d’âge.');
      return;
    }
    if (_step == 2) {
      final name = _firstNameCtrl.text.trim();
      final mail = _emailCtrl.text.trim();
      if (name.isEmpty) {
        _toast('Ton prénom est obligatoire.');
        return;
      }
      if (mail.isEmpty || !_emailRe.hasMatch(mail)) {
        _toast('Une adresse e-mail valide est obligatoire.');
        return;
      }
    }
    _goTo(_step + 1);
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _submit() async {
    if (!_acceptTerms) {
      _toast('Merci d’accepter les conditions.');
      return;
    }
    final name = _firstNameCtrl.text.trim();
    final mail = _emailCtrl.text.trim();
    if (_hearAboutId == null || _ageRangeId == null) return;

    setState(() => _submitting = true);
    try {
      await widget.onComplete(
        UserRegistration(
          hearAboutUs: _hearAboutId!,
          ageRange: _ageRangeId!,
          firstName: name,
          email: mail,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canRegister = ApiConfig.canRegister;
    final localOnly =
        !ApiConfig.isConfigured && ApiConfig.allowLocalRegistration;
    return Scaffold(
      backgroundColor: AlfawzColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: _submitting ? null : () => _goTo(_step - 1),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (_step + 1) / _totalSteps,
                        minHeight: 5,
                        backgroundColor:
                            AlfawzColors.outlineVariant.withValues(alpha: 0.35),
                        color: AlfawzColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_step + 1}/$_totalSteps',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AlfawzColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (localOnly)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Material(
                  color: AlfawzColors.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Mode fichier seul : ton compte est créé sur cet appareil. '
                      'Quand ton API sera prête, définis `ALFAWZ_API_BASE` pour sync serveur.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    ),
                  ),
                ),
              ),
            if (!canRegister)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Material(
                  color: AlfawzColors.errorContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Inscription désactivée : ajoute `ALFAWZ_API_BASE` ou réactive '
                      '`ALFAWZ_ALLOW_LOCAL_ONLY=true`.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _stepHearAbout(),
                  _stepAge(),
                  _stepIdentity(),
                  _stepTerms(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: _step == _totalSteps - 1
                  ? FilledButton(
                      onPressed: _submitting || !canRegister ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AlfawzColors.primary,
                        foregroundColor: AlfawzColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AlfawzColors.onPrimary,
                              ),
                            )
                          : Text(
                              'Créer mon compte',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    )
                  : FilledButton(
                      onPressed: _submitting ? null : _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AlfawzColors.primary,
                        foregroundColor: AlfawzColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Continuer',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alfawz',
            style: GoogleFonts.notoSerif(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AlfawzColors.primary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.notoSerif(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AlfawzColors.primary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              height: 1.45,
              color: AlfawzColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepHearAbout() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _header(
          'Comment nous avez-vous connus ?',
          'Une seule réponse — cela nous aide à améliorer Alfawz.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final o in hearAboutUsOptions)
                ChoiceChip(
                  label: Text(o.label),
                  selected: _hearAboutId == o.id,
                  onSelected: (_) =>
                      setState(() => _hearAboutId = o.id),
                  selectedColor:
                      AlfawzColors.secondaryContainer.withValues(alpha: 0.9),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: _hearAboutId == o.id
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepAge() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _header(
          'Ta tranche d’âge',
          'Les réponses sont anonymisées pour nos statistiques.',
        ),
        for (final o in ageRangeOptions)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Material(
              color: _ageRangeId == o.id
                  ? AlfawzColors.secondaryContainer.withValues(alpha: 0.35)
                  : AlfawzColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _ageRangeId = o.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: _ageRangeId == o.id
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_ageRangeId == o.id)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AlfawzColors.primary,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _stepIdentity() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        _header(
          'Presque fini',
          'Ton prénom et ton e-mail pour enregistrer ton compte sur nos serveurs.',
        ),
        TextFormField(
          controller: _firstNameCtrl,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: _dec('Prénom', Icons.badge_outlined),
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          decoration: _dec('E-mail', Icons.mail_outline_rounded),
        ),
      ],
    );
  }

  Widget _stepTerms() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        _header(
          'Conditions',
          'Dernière étape : nous respectons le RGPD. Tes données sont associées à ton compte sur notre serveur.',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _acceptTerms,
              fillColor: WidgetStateProperty.resolveWith((s) {
                if (s.contains(WidgetState.selected)) {
                  return AlfawzColors.primary;
                }
                return null;
              }),
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _acceptTerms = v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'J’accepte les conditions d’utilisation et la politique de '
                  'confidentialité. Je comprends que mes réponses et mon profil sont '
                  'stockés sur les serveurs Alfawz.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.35,
                    color: AlfawzColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AlfawzColors.primary.withValues(alpha: 0.7)),
      filled: true,
      fillColor: AlfawzColors.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AlfawzColors.primary.withValues(alpha: 0.45),
        ),
      ),
      labelStyle: GoogleFonts.plusJakartaSans(
        color: AlfawzColors.onSurfaceVariant,
      ),
    );
  }
}
