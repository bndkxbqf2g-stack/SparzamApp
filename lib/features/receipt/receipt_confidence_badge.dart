import 'package:flutter/material.dart';

import '../../models/receipt_confidence.dart';

class ReceiptConfidenceBadge extends StatelessWidget {
  const ReceiptConfidenceBadge({
    super.key,
    required this.level,
    this.compact = false,
  });

  final ReceiptConfidenceLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (level) {
      ReceiptConfidenceLevel.manuellBestaetigt => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          Icons.verified_outlined,
        ),
      ReceiptConfidenceLevel.wahrscheinlich => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
          Icons.help_outline,
        ),
      ReceiptConfidenceLevel.belegt => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
          Icons.receipt_long_outlined,
        ),
      ReceiptConfidenceLevel.unsicher => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          Icons.warning_amber_outlined,
        ),
    };

    return Tooltip(
      message: level.description,
      child: Chip(
        avatar: Icon(
          icon,
          size: compact ? 14 : 16,
          color: foreground,
        ),
        label: Text(
          level.label,
          style: TextStyle(
            color: foreground,
            fontSize: compact ? 11 : null,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: background,
        visualDensity: compact ? VisualDensity.compact : null,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
