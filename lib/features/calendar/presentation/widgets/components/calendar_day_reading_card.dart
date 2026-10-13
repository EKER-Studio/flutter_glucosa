import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/domain/enums/glucose_status.dart';
import '../../../../../core/domain/enums/glucose_unit.dart';
import '../../../../../core/domain/utils/glucose_converter.dart';
import '../../../../../core/presentation/extensions/failure_ui_extension.dart';
import '../../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../glucose/domain/entities/glucose_reading.dart';
import '../../../../glucose/presentation/extensions/glucose_status_ui_extension.dart';
import '../../../../glucose/presentation/providers/glucose_reading_list_notifier.dart';

/// Card tile representing a single glucose reading on the calendar selected day view.
class CalendarDayReadingCard extends ConsumerWidget {
  /// The glucose reading to render.
  final GlucoseReading reading;

  /// The clinical status of this reading relative to the active target range.
  final GlucoseStatus status;

  /// Preferred glucose unit for display formatting.
  final GlucoseUnit preferredUnit;

  /// Creates a [CalendarDayReadingCard].
  const CalendarDayReadingCard({
    super.key,
    required this.reading,
    required this.status,
    required this.preferredUnit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final String displayValue;
    if (preferredUnit == GlucoseUnit.mmolL) {
      displayValue = GlucoseConverter.mgDlToMmolL(
        reading.readingMgDl,
      ).toStringAsFixed(1);
    } else {
      displayValue = reading.readingMgDl.toString();
    }

    final timeStr = DateFormat.jm(
      Localizations.localeOf(context).toString(),
    ).format(reading.createdAt);

    return Card(
      key: ValueKey(reading.id),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          AppRoute.editGlucose.name,
          pathParameters: {'id': '${reading.id}'},
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: status.foregroundColor(context),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  timeStr,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: status.backgroundColor(context),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                status.localizedName(l10n),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: status.foregroundColor(context),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              displayValue,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              preferredUnit.displayName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                        width: 1.0,
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      icon: Icon(
                        Icons.more_vert,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      tooltip: l10n.moreOptions,
                      onSelected: (value) {
                        if (value == 'edit') {
                          context.pushNamed(
                            AppRoute.editGlucose.name,
                            pathParameters: {'id': '${reading.id}'},
                          );
                        } else if (value == 'delete') {
                          _confirmDelete(context, ref, reading.id);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: colorScheme.onSurface,
                              ),
                              const SizedBox(width: 12),
                              Text(l10n.edit),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.delete,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: colorScheme.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.restaurant_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    reading.mealContext.localizedName(l10n),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (reading.notes != null &&
                  reading.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsetsDirectional.only(start: 10),
                  decoration: BoxDecoration(
                    border: BorderDirectional(
                      start: BorderSide(width: 2.5, color: colorScheme.outline),
                    ),
                  ),
                  child: Text(
                    reading.notes!.trim(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int readingId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteReadingConfirmationTitle),
        content: Text(l10n.deleteReadingConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final (success, failure) = await ref
          .read(glucoseReadingListProvider.notifier)
          .deleteReading(readingId);
      if (!success && context.mounted) {
        AppSnackBar.show(
          context,
          message: failure != null
              ? failure.toUserMessage(l10n)
              : l10n.failedToDeleteGlucoseReading,
          type: SnackBarType.error,
        );
      }
    }
  }
}
