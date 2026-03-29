import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/alfawz_colors.dart';

class GlassSliverAppBar extends StatelessWidget {
  const GlassSliverAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.leading,
  });

  final String title;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      expandedHeight: 64,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            alignment: Alignment.center,
            color: AlfawzColors.surface.withValues(alpha: 0.82),
          ),
        ),
      ),
      leading: leading,
      title: Text(
        title,
        style: GoogleFonts.notoSerif(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AlfawzColors.primary,
        ),
      ),
      actions: actions,
    );
  }
}
