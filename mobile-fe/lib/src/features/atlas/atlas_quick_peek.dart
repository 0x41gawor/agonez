import 'package:flutter/material.dart';

import '../../api/atlas_models.dart';
import '../../atlas/widgets/anatomy_heatmap.dart';
import '../../data/mobile_repository.dart';
import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';
import 'atlas_data_source.dart';

Future<void> showAtlasQuickPeek({
  required BuildContext context,
  required AtlasDataSource dataSource,
  required int exerciseId,
  AtlasPeek? embedded,
  String? planNote,
  ValueChanged<AtlasPeek>? onOpenFull,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => AtlasQuickPeekSheet(
      dataSource: dataSource,
      exerciseId: exerciseId,
      embedded: embedded,
      planNote: planNote,
      onOpenFull: onOpenFull,
    ),
  );
}

class AtlasQuickPeekSheet extends StatefulWidget {
  const AtlasQuickPeekSheet({
    required this.dataSource,
    required this.exerciseId,
    this.embedded,
    this.planNote,
    this.onOpenFull,
    super.key,
  });

  final AtlasDataSource dataSource;
  final int exerciseId;
  final AtlasPeek? embedded;
  final String? planNote;
  final ValueChanged<AtlasPeek>? onOpenFull;

  @override
  State<AtlasQuickPeekSheet> createState() => _AtlasQuickPeekSheetState();
}

class _AtlasQuickPeekSheetState extends State<AtlasQuickPeekSheet> {
  late Future<LoadedValue<AtlasPeek>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.dataSource.loadPeek(
      widget.exerciseId,
      embedded: widget.embedded,
    );
  }

  void _retry() => setState(_load);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FractionallySizedBox(
      heightFactor: .88,
      child: Column(
        children: [
          const AgonezSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: AgonezEyebrow(
                    l10n.atlasQuickView,
                    color: context.agonezColors.goldText,
                  ),
                ),
                IconButton(
                  tooltip: l10n.commonClose,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<LoadedValue<AtlasPeek>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return _PeekUnavailable(onRetry: _retry);
                }
                return _PeekBody(
                  loaded: snapshot.requireData,
                  planNote: widget.planNote,
                  onOpenFull: widget.onOpenFull,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PeekUnavailable extends StatelessWidget {
  const _PeekUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: AgonezInsets.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: context.agonezColors.textMuted,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.atlasOfflineUnavailable,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeekBody extends StatelessWidget {
  const _PeekBody({
    required this.loaded,
    required this.planNote,
    required this.onOpenFull,
  });

  final LoadedValue<AtlasPeek> loaded;
  final String? planNote;
  final ValueChanged<AtlasPeek>? onOpenFull;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final peek = loaded.value;
    final tldr = <(String, String?)>[
      (l10n.atlasTechniqueSetup, peek.techniqueTldr.setup),
      (l10n.atlasTechniqueExecution, peek.techniqueTldr.execution),
      (l10n.atlasTechniqueFocus, peek.techniqueTldr.focus),
      (l10n.atlasTechniqueStopWhen, peek.techniqueTldr.stopWhen),
    ].where((item) => item.$2?.trim().isNotEmpty ?? false).toList();
    final regions = <String, double>{
      for (final region in peek.bodyMap.regions)
        region.regionId: region.intensity,
    };

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            peek.exercise.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            peek.exercise.fullName ?? peek.exercise.slug,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: context.agonezColors.textMuted,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (loaded.offline)
                      AgonezTag(
                        label: l10n.syncOfflineTitle,
                        uppercase: false,
                        color: context.agonezColors.caution,
                        icon: Icon(
                          Icons.cloud_off_outlined,
                          size: 12,
                          color: context.agonezColors.caution,
                        ),
                      ),
                  ],
                ),
                if (peek.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: peek.tags
                        .map((tag) => AgonezTag(label: tag))
                        .toList(growable: false),
                  ),
                ],
                const SizedBox(height: 18),
                for (final item in tldr) ...[
                  _TechniqueCue(label: item.$1, body: item.$2!),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: AgonezPanel(
                        padding: const EdgeInsets.all(8),
                        child: AnatomyHeatmap(
                          regionIntensities: regions,
                          height: 210,
                          semanticsLabel: l10n.atlasSectionAnatomy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: peek.musclesTop
                            .map((muscle) => _PeekMuscle(muscle: muscle))
                            .toList(growable: false),
                      ),
                    ),
                  ],
                ),
                if (planNote?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 18),
                  AgonezEyebrow(
                    l10n.atlasPlanNoteThisWorkout,
                    color: context.agonezColors.prescriptionText,
                  ),
                  const SizedBox(height: 6),
                  Text(planNote!),
                ],
              ],
            ),
          ),
        ),
        if (onOpenFull != null)
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: AgonezPrimaryButton(
              label: l10n.atlasOpenFull,
              icon: const Icon(Icons.library_books_outlined),
              onPressed: () {
                Navigator.of(context).pop();
                onOpenFull!(peek);
              },
            ),
          ),
      ],
    );
  }
}

class _TechniqueCue extends StatelessWidget {
  const _TechniqueCue({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AgonezPanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 18,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: BoxDecoration(
              color: context.agonezColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AgonezEyebrow(
                  label,
                  color: context.agonezColors.goldText,
                  uppercase: false,
                ),
                const SizedBox(height: 5),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeekMuscle extends StatelessWidget {
  const _PeekMuscle({required this.muscle});

  final AtlasMuscle muscle;

  @override
  Widget build(BuildContext context) {
    final share = (muscle.capacityShare ?? 0).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            muscle.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 4,
              color: context.agonezColors.muscleHeat,
              backgroundColor: context.agonezColors.control,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${muscle.etuCm2.toStringAsFixed(1)} cm²',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.agonezColors.textDim,
              fontFamily: 'Geist Mono',
            ),
          ),
        ],
      ),
    );
  }
}
