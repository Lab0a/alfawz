import 'package:flutter/material.dart';

import '../theme/alfawz_colors.dart';

enum AlfawzTab { home, search, library, settings }

class AlfawzBottomNav extends StatelessWidget {
  const AlfawzBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final AlfawzTab current;
  final ValueChanged<AlfawzTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        decoration: BoxDecoration(
          color: AlfawzColors.surface.withValues(alpha: 0.92),
          boxShadow: [
            BoxShadow(
              color: AlfawzColors.primary.withValues(alpha: 0.06),
              blurRadius: 40,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Item(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: current == AlfawzTab.home,
                  onTap: () => onSelect(AlfawzTab.home),
                ),
                _Item(
                  icon: Icons.search_rounded,
                  label: 'Search',
                  selected: current == AlfawzTab.search,
                  onTap: () => onSelect(AlfawzTab.search),
                ),
                _Item(
                  icon: Icons.auto_stories_rounded,
                  label: 'Library',
                  selected: current == AlfawzTab.library,
                  onTap: () => onSelect(AlfawzTab.library),
                ),
                _Item(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  selected: current == AlfawzTab.settings,
                  onTap: () => onSelect(AlfawzTab.settings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AlfawzColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? AlfawzColors.onPrimary
                  : AlfawzColors.primary.withValues(alpha: 0.62),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: style?.copyWith(
                fontSize: 10,
                letterSpacing: 0.6,
                color: selected
                    ? AlfawzColors.onPrimary
                    : AlfawzColors.primary.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
