part of 'focus_mode_screen.dart';

class _AtlasQuickPeekSheet extends StatelessWidget {
  const _AtlasQuickPeekSheet({
    required this.exercise,
    required this.onOpenFull,
  });

  final FocusExerciseViewModel exercise;
  final VoidCallback? onOpenFull;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final peek = exercise.atlasPeek!;
    final regions = <String, double>{
      for (final region in peek.bodyMap.regions)
        region.regionId: region.intensity,
    };
    final technique = <(String, String?)>[
      (l10n.atlasTechniqueSetup, peek.techniqueTldr.setup),
      (l10n.atlasTechniqueExecution, peek.techniqueTldr.execution),
      (l10n.atlasTechniqueFocus, peek.techniqueTldr.focus),
      (l10n.atlasTechniqueStopWhen, peek.techniqueTldr.stopWhen),
    ];
    return _SheetFrame(
      title: exercise.name,
      eyebrow: l10n.atlasQuickView,
      maxHeightFactor: 0.9,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          if ((peek.exercise.fullName ?? '').isNotEmpty)
            Text(
              peek.exercise.fullName!,
              style: AgonezTypography.of(context).bodyMedium,
            ),
          ExerciseImage(
            slug: peek.exercise.slug,
            semanticLabel: exercise.name,
            margin: const EdgeInsets.only(top: 12),
          ),
          const SizedBox(height: 14),
          for (final block in technique)
            if ((block.$2 ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AgonezEyebrow(block.$1),
                    const SizedBox(height: 4),
                    Text(
                      block.$2!,
                      style: AgonezTypography.of(context).bodyLarge,
                    ),
                  ],
                ),
              ),
          const Divider(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 330;
              final map = AnatomyHeatmap(
                regionIntensities: regions,
                height: narrow ? 190 : 220,
                semanticsLabel: l10n.atlasSectionAnatomy,
              );
              final muscles = Column(
                children: [
                  for (final muscle in peek.musclesTop.take(4))
                    _MuscleExposureRow(
                      name: muscle.name,
                      etu: muscle.etuCm2,
                      share: muscle.capacityShare,
                    ),
                ],
              );
              if (narrow) {
                return Column(
                  children: [map, const SizedBox(height: 12), muscles],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: map),
                  const SizedBox(width: 12),
                  Expanded(child: muscles),
                ],
              );
            },
          ),
          if ((exercise.planNote ?? '').isNotEmpty) ...[
            const Divider(height: 24),
            AgonezEyebrow(l10n.atlasPlanNoteThisWorkout),
            const SizedBox(height: 5),
            Text(
              exercise.planNote!,
              style: AgonezTypography.of(context).bodyMedium,
            ),
          ],
        ],
      ),
      footer: onOpenFull == null
          ? null
          : AgonezPrimaryButton(
              label: l10n.atlasOpenFull,
              onPressed: () {
                Navigator.of(context).pop();
                onOpenFull!();
              },
            ),
    );
  }
}

class _MuscleExposureRow extends StatelessWidget {
  const _MuscleExposureRow({
    required this.name,
    required this.etu,
    required this.share,
  });

  final String name;
  final double etu;
  final double? share;

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    final normalized = (share ?? 0).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AgonezTypography.of(context).bodySmall,
                ),
              ),
              Text(
                etu.toStringAsFixed(1),
                style: AgonezTypography.of(context).labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 3,
              color: colors.muscleHeat,
              backgroundColor: colors.line,
            ),
          ),
        ],
      ),
    );
  }
}
