import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Segmented option for [PillSegmentedControl].
class PillSegment<T extends Object> {
  /// Value selected when this segment is tapped.
  final T value;

  /// Visible label of the segment.
  final String label;

  /// Creates a [PillSegment].
  const PillSegment({required this.value, required this.label});
}

/// Animated pill-style segmented selector with accessible semantics.
///
/// Renders options as sliding-pill choices inside a rounded container,
/// announcing the selected value to screen readers as a group.
class PillSegmentedControl<T extends Object> extends StatelessWidget {
  /// Available segments.
  final List<PillSegment<T>> segments;

  /// Currently selected value.
  final T selected;

  /// Callback invoked when a different segment is tapped.
  final ValueChanged<T> onChanged;

  /// Creates a [PillSegmentedControl].
  const PillSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    assert(segments.isNotEmpty, 'PillSegmentedControl needs segments');

    final selectedLabel = AppLocalizations.of(context)!.selectedState;
    return Semantics(
      container: true,
      label: segments
          .map(
            (s) =>
                '${s.label}${s.value == selected ? ' ($selectedLabel)' : ''}',
          )
          .join(', '),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            for (final segment in segments)
              Expanded(
                child: _PillButton<T>(
                  segment: segment,
                  selected: segment.value == selected,
                  onTap: () {
                    if (segment.value != selected) onChanged(segment.value);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PillButton<T extends Object> extends StatelessWidget {
  final PillSegment<T> segment;
  final bool selected;
  final VoidCallback onTap;

  const _PillButton({
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: segment.label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            segment.label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
