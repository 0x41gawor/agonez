import 'package:flutter/material.dart';

import '../design/design.dart';

enum WorkoutSyncStatus { saved, saving, offline, failed, conflict, superseded }

/// Quiet, text-labelled workout sync status.
///
/// The caller supplies localized copy, including any pending operation count.
class SyncStatusPill extends StatelessWidget {
  const SyncStatusPill({
    required this.status,
    required this.label,
    this.semanticLabel,
    this.onPressed,
    this.liveRegion = true,
    super.key,
  });

  final WorkoutSyncStatus status;
  final String label;
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    final visual = switch (status) {
      WorkoutSyncStatus.saved => _SyncVisual(
        foreground: colors.textMuted,
        marker: colors.success,
      ),
      WorkoutSyncStatus.saving => _SyncVisual(
        foreground: colors.textMuted,
        marker: colors.textMuted,
      ),
      WorkoutSyncStatus.offline => _SyncVisual(
        foreground: colors.caution,
        marker: colors.caution,
        outlinedMarker: true,
        border: colors.caution.withValues(alpha: 0.42),
      ),
      WorkoutSyncStatus.failed || WorkoutSyncStatus.conflict => _SyncVisual(
        foreground: colors.error,
        marker: colors.error,
        border: colors.error.withValues(alpha: 0.42),
      ),
      WorkoutSyncStatus.superseded => _SyncVisual(
        foreground: colors.caution,
        marker: colors.caution,
        border: colors.caution.withValues(alpha: 0.42),
      ),
    };

    final visualPill = Container(
      constraints: const BoxConstraints(
        minHeight: AgonezSizes.syncPillHeight,
        minWidth: AgonezSizes.minimumTouchTarget,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: visual.border ?? colors.line),
        borderRadius: BorderRadius.circular(AgonezRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: visual.outlinedMarker ? 7 : 6,
            height: visual.outlinedMarker ? 7 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: visual.outlinedMarker ? Colors.transparent : visual.marker,
              border: visual.outlinedMarker
                  ? Border.all(color: visual.marker, width: 1.5)
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AgonezTypography.monoSmall.copyWith(
              color: visual.foreground,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );

    final contents = onPressed == null
        ? visualPill
        : SizedBox(
            height: AgonezSizes.minimumTouchTarget,
            child: Center(child: visualPill),
          );

    return Semantics(
      container: true,
      liveRegion: liveRegion,
      button: onPressed != null,
      enabled: onPressed != null,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AgonezRadii.pill),
          child: contents,
        ),
      ),
    );
  }
}

class _SyncVisual {
  const _SyncVisual({
    required this.foreground,
    required this.marker,
    this.outlinedMarker = false,
    this.border,
  });

  final Color foreground;
  final Color marker;
  final bool outlinedMarker;
  final Color? border;
}
