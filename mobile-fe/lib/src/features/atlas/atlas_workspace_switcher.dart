import 'dart:convert';

import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../storage/app_database.dart';
import 'atlas_workspace_controller.dart';

class AtlasWorkspaceSwitcher extends StatelessWidget {
  const AtlasWorkspaceSwitcher({
    required this.controller,
    required this.activeWorkout,
    required this.onOpenWorkout,
    super.key,
  });

  final AtlasWorkspaceController controller;
  final LocalWorkout? activeWorkout;
  final VoidCallback onOpenWorkout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.agonezColors.ground,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      l10n.workspaceTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.commonDone),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            if (activeWorkout != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
                child: Text(
                  l10n.workspacePinnedHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.agonezColors.textMuted,
                  ),
                ),
              ),
            Expanded(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final cardCount =
                      controller.count + 1 + (activeWorkout == null ? 0 : 1);
                  return GridView.builder(
                    key: const Key('atlas-workspace-grid'),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: .83,
                        ),
                    itemCount: cardCount,
                    itemBuilder: (context, index) {
                      if (activeWorkout != null && index == 0) {
                        return _WorkoutWorkspaceCard(
                          workout: activeWorkout!,
                          onTap: onOpenWorkout,
                        );
                      }
                      final workspaceIndex =
                          index - (activeWorkout == null ? 0 : 1);
                      if (workspaceIndex == controller.count) {
                        return _NewWorkspaceCard(
                          onTap: () async {
                            await controller.showIndex();
                            if (context.mounted) Navigator.of(context).pop();
                          },
                        );
                      }
                      final workspace = controller.workspaces[workspaceIndex];
                      return _AtlasWorkspaceCard(
                        workspace: workspace,
                        isCurrent: workspace.id == controller.currentId,
                        onTap: () async {
                          await controller.activate(workspace.id);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        onClose: () => controller.close(workspace.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutWorkspaceCard extends StatelessWidget {
  const _WorkoutWorkspaceCard({required this.workout, required this.onTap});

  final LocalWorkout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final exerciseTotal = _exerciseCount(workout.prescriptionJson);
    return Semantics(
      button: true,
      label: '${workout.workoutUnitName}, ${l10n.workspaceActive}',
      child: InkWell(
        key: const Key('workspace-active-workout'),
        onTap: onTap,
        borderRadius: AgonezRadii.cardBorder,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.agonezColors.goldSoft,
            border: Border.all(color: context.agonezColors.gold),
            borderRadius: AgonezRadii.cardBorder,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 17,
                    color: context.agonezColors.goldText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AgonezEyebrow(
                      l10n.workspaceActive,
                      color: context.agonezColors.goldText,
                    ),
                  ),
                  Icon(
                    Icons.push_pin_outlined,
                    size: 16,
                    color: context.agonezColors.goldText,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                workout.workoutUnitName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.workoutExerciseCounter(workout.currentExercise + 1, exerciseTotal)} · '
                '${l10n.workoutSetLabel(workout.currentSet + 1)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.agonezColors.goldText,
                  fontFamily: 'Geist Mono',
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.workspaceCannotClose,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.agonezColors.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _exerciseCount(String prescriptionJson) {
  try {
    final decoded = jsonDecode(prescriptionJson);
    if (decoded is Map && decoded['exercises'] is List) {
      final count = (decoded['exercises'] as List).length;
      return count > 0 ? count : 1;
    }
  } on FormatException {
    // A damaged display-only summary must not hide the durable workout card.
  }
  return 1;
}

class _AtlasWorkspaceCard extends StatelessWidget {
  const _AtlasWorkspaceCard({
    required this.workspace,
    required this.isCurrent,
    required this.onTap,
    required this.onClose,
  });

  final AtlasWorkspaceEntry workspace;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final page = workspace.page;
    return Container(
      key: Key('workspace-${workspace.id}'),
      decoration: BoxDecoration(
        color: context.agonezColors.panel,
        border: Border.all(
          color: isCurrent
              ? context.agonezColors.gold
              : context.agonezColors.line,
        ),
        borderRadius: AgonezRadii.cardBorder,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
            child: Row(
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 17,
                  color: isCurrent
                      ? context.agonezColors.goldText
                      : context.agonezColors.textMuted,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: AgonezEyebrow(
                    l10n.atlasTitle,
                    color: isCurrent ? context.agonezColors.goldText : null,
                  ),
                ),
                IconButton(
                  tooltip: l10n.workspaceCloseA11y(page.title),
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      page.slug,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.agonezColors.textDim,
                        fontFamily: 'Geist Mono',
                      ),
                    ),
                    const Spacer(),
                    if (isCurrent)
                      AgonezTag(
                        label: l10n.workspaceActive,
                        color: context.agonezColors.goldText,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewWorkspaceCard extends StatelessWidget {
  const _NewWorkspaceCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      key: const Key('workspace-new-atlas'),
      onTap: onTap,
      borderRadius: AgonezRadii.cardBorder,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: context.agonezColors.control,
            style: BorderStyle.solid,
          ),
          borderRadius: AgonezRadii.cardBorder,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 30, color: context.agonezColors.textMuted),
            const SizedBox(height: 8),
            Text(
              l10n.workspaceNewTab,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
