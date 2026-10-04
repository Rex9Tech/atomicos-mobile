// lib/modules/ai/pages/widgets/molecule_pick_card.dart
import 'package:flutter/material.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/modules/home/data/models/models.dart';

/// Row used by the ask-sheet molecule picker: mirrors [_ContextAtomCard]'s
/// glass style with the molecule identity.
class MoleculePickCard extends StatelessWidget {
  const MoleculePickCard({
    super.key,
    required this.molecule,
    required this.onTap,
    this.selected = false,
  });

  final CategoryModel molecule;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppGlassCard(
      onTap: onTap,
      padding: EdgeInsets.all(Design.spacing.md),
      radius: Design.spacing.radiusLarge,
      // The attached molecule wears the same soft primary glow as the atom
      // picker, so the sheet always reflects what the chat is grounded in.
      shadow: selected
          ? <BoxShadow>[
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.30),
                blurRadius: 16,
              ),
            ]
          : null,
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Design.icons.molecule,
              size: Design.spacing.iconSmall,
              color: colors.primary,
            ),
          ),
          SizedBox(width: Design.spacing.md),
          Expanded(
            child: Text(
              molecule.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.typo.labelMedium.copyWith(
                color: selected ? colors.primary : colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (selected)
            Icon(
              Design.icons.check,
              size: Design.spacing.iconSmall,
              color: colors.primary,
            ),
        ],
      ),
    );
  }
}
