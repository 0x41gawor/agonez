import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/atlas_models.dart';
import '../../api/json_support.dart';
import '../../api/prescription_models.dart';
import '../../app/app_providers.dart';
import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../storage/app_database.dart';
import 'atlas_article_screen.dart';
import 'atlas_data_source.dart';
import 'atlas_workspace_controller.dart';
import 'atlas_workspace_switcher.dart';

/// Atlas tab root. It reads the production runtime itself, while narrow
/// injection points keep the catalogue and workspace behaviour widget-testable.
class AtlasScreen extends ConsumerStatefulWidget {
  const AtlasScreen({
    super.key,
    this.initialSlug,
    this.initialExerciseId,
    this.initialTitle,
    this.dataSource,
    this.workspaceController,
  });

  final String? initialSlug;
  final int? initialExerciseId;
  final String? initialTitle;
  final AtlasDataSource? dataSource;
  final AtlasWorkspaceController? workspaceController;

  @override
  ConsumerState<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends ConsumerState<AtlasScreen> {
  late final AtlasDataSource _dataSource;
  late final AtlasWorkspaceController _workspaces;
  late Future<void> _restoring;
  bool _openingInitial = false;

  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  int _searchGeneration = 0;
  List<AtlasSearchItem> _results = const [];
  Object? _searchError;
  bool _searching = true;
  bool _showMuscles = false;

  @override
  void initState() {
    super.initState();
    final runtime = ref.read(appRuntimeProvider);
    _dataSource =
        widget.dataSource ?? MobileAtlasDataSource(runtime.mobileRepository);
    _workspaces =
        widget.workspaceController ??
        AtlasWorkspaceController(database: runtime.database);
    _workspaces.addListener(_workspaceChanged);
    _restoring = _restoreAndOpenInitial();
    unawaited(_search());
  }

  Future<void> _restoreAndOpenInitial() async {
    await _workspaces.restore();
    final slug = widget.initialSlug;
    if (slug != null && slug.isNotEmpty && !_openingInitial) {
      _openingInitial = true;
      await _workspaces.openArticle(
        exerciseId: widget.initialExerciseId ?? 0,
        slug: slug,
        title: widget.initialTitle ?? _titleFromSlug(slug),
      );
    }
  }

  void _workspaceChanged() {
    if (mounted) setState(() {});
  }

  Future<int?> _planRunId() async {
    return ref.read(appRuntimeProvider).mobileRepository.selectedPlanRunId();
  }

  Future<void> _search() async {
    final generation = ++_searchGeneration;
    if (mounted) {
      setState(() {
        _searching = true;
        _searchError = null;
      });
    }
    try {
      final response = await _dataSource.search(
        query: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        planRunId: await _planRunId(),
      );
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = response.items;
        _searching = false;
      });
    } on Object catch (error) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _searchError = error;
        _searching = false;
      });
    }
  }

  void _queryChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), _search);
  }

  Future<void> _open(AtlasSearchItem item) async {
    final result = await _workspaces.openArticle(
      exerciseId: item.id,
      slug: item.slug,
      title: item.name,
    );
    if (result.evictedOldest && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).workspaceLimitReached),
        ),
      );
    }
  }

  Future<void> _backFromArticle() async {
    final current = _workspaces.current;
    if (current == null) return;
    if (!await _workspaces.popPage(current.id)) {
      await _workspaces.showIndex();
    }
  }

  Future<void> _showWorkspaceSwitcher(LocalWorkout? activeWorkout) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (switcherContext) => AtlasWorkspaceSwitcher(
          controller: _workspaces,
          activeWorkout: activeWorkout,
          onOpenWorkout: () {
            Navigator.of(switcherContext).pop();
            context.go('/focus');
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _workspaces.removeListener(_workspaceChanged);
    if (widget.workspaceController == null) _workspaces.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeWorkout = ref.watch(activeWorkoutProvider).value;
    return FutureBuilder<void>(
      future: _restoring,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SafeArea(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _RestoreFailure(
            onRetry: () =>
                setState(() => _restoring = _restoreAndOpenInitial()),
          );
        }
        final current = _workspaces.current;
        if (current != null) {
          return AtlasArticleScreen(
            key: ValueKey('${current.id}:${current.page.slug}'),
            dataSource: _dataSource,
            workspace: current,
            workspaceCount: _workspaces.count,
            hasActiveWorkout: activeWorkout != null,
            todayExerciseSlugs: _activeExerciseSlugs(activeWorkout),
            onBack: _backFromArticle,
            onOpenWorkspaces: () => _showWorkspaceSwitcher(activeWorkout),
            onSaveScroll: (offset) =>
                unawaited(_workspaces.saveScroll(current.id, offset)),
          );
        }
        return _buildIndex(context, activeWorkout);
      },
    );
  }

  Widget _buildIndex(BuildContext context, LocalWorkout? activeWorkout) {
    final l10n = AppLocalizations.of(context);
    final totalWorkspaces = _workspaces.count + (activeWorkout == null ? 0 : 1);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    l10n.atlasTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Semantics(
                  button: true,
                  label: l10n.workspaceCounterA11y(totalWorkspaces),
                  child: IconButton(
                    key: const Key('atlas-workspace-button'),
                    onPressed: () => _showWorkspaceSwitcher(activeWorkout),
                    icon: _IndexWorkspaceCount(count: totalWorkspaces),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _search,
              child: ListView(
                key: const Key('atlas-index'),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  TextField(
                    key: const Key('atlas-search'),
                    controller: _searchController,
                    onChanged: _queryChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: l10n.atlasSearchPlaceholder,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l10n.commonClose,
                              onPressed: () {
                                _searchController.clear();
                                _queryChanged('');
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  if (_workspaces.workspaces.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    AgonezEyebrow(l10n.atlasOpenArticles),
                    const SizedBox(height: 9),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _workspaces.count,
                        separatorBuilder: (_, _) => const SizedBox(width: 7),
                        itemBuilder: (context, index) {
                          final workspace = _workspaces.workspaces[index];
                          return ActionChip(
                            label: Text(workspace.page.title),
                            onPressed: () => _workspaces.activate(workspace.id),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: <ButtonSegment<bool>>[
                          ButtonSegment(
                            value: false,
                            label: Text(l10n.atlasExercises),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(l10n.atlasMuscles),
                          ),
                        ],
                        selected: <bool>{_showMuscles},
                        onSelectionChanged: (selection) =>
                            setState(() => _showMuscles = selection.first),
                      ),
                      const Spacer(),
                      if (!_showMuscles && !_searching)
                        Text(
                          '${_results.length}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: context.agonezColors.textDim,
                                fontFamily: 'Geist Mono',
                              ),
                        ),
                    ],
                  ),
                  if (_searchError != null) ...[
                    const SizedBox(height: 12),
                    _OfflineSearchNotice(onRetry: _search),
                  ],
                  if (_searching && _results.isEmpty) ...[
                    const SizedBox(height: 50),
                    const Center(child: CircularProgressIndicator()),
                  ] else if (_showMuscles) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        l10n.commonNotAvailableYet,
                        style: TextStyle(color: context.agonezColors.textMuted),
                      ),
                    ),
                  ] else if (_results.isEmpty) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        l10n.commonNotAvailableYet,
                        style: TextStyle(color: context.agonezColors.textMuted),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    for (final item in _results)
                      _SearchResultRow(
                        item: item,
                        isOpen: _workspaces.workspaces.any(
                          (workspace) => workspace.page.slug == item.slug,
                        ),
                        onTap: () => _open(item),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestoreFailure extends StatelessWidget {
  const _RestoreFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Center(
        child: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.commonRetry),
        ),
      ),
    );
  }
}

class _IndexWorkspaceCount extends StatelessWidget {
  const _IndexWorkspaceCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 25, minHeight: 25),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: count > 0
              ? context.agonezColors.gold
              : context.agonezColors.textMuted,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontFamily: 'Geist Mono',
          color: count > 0
              ? context.agonezColors.goldText
              : context.agonezColors.textMuted,
        ),
      ),
    );
  }
}

class _OfflineSearchNotice extends StatelessWidget {
  const _OfflineSearchNotice({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AgonezPanel(
      padding: const EdgeInsets.all(12),
      borderColor: context.agonezColors.caution,
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: context.agonezColors.caution,
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(l10n.errorNetworkUnavailable)),
          TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.item,
    required this.isOpen,
    required this.onTap,
  });

  final AtlasSearchItem item;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final last = item.lastPerformedInRun;
    final lastSet = last?.sets.isEmpty ?? true ? null : last!.sets.first;
    return InkWell(
      key: Key('atlas-result-${item.slug}'),
      onTap: onTap,
      borderRadius: AgonezRadii.controlBorder,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.agonezColors.lineSubtle),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.agonezColors.raised,
                borderRadius: AgonezRadii.controlBorder,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 20,
                color: context.agonezColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.mechanicsTier} · ${item.fullName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.agonezColors.textMuted,
                    ),
                  ),
                  if (last != null && lastSet != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'MC${last.microcycleOrdinal} · ${_formatLastSet(lastSet)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.agonezColors.prescriptionText,
                        fontFamily: 'Geist Mono',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isOpen)
              AgonezTag(
                label: l10n.workspaceActive,
                color: context.agonezColors.goldText,
              )
            else
              Icon(Icons.chevron_right, color: context.agonezColors.textDim),
          ],
        ),
      ),
    );
  }
}

Set<String> _activeExerciseSlugs(LocalWorkout? workout) {
  if (workout == null) return const <String>{};
  try {
    final prescription = WorkoutPrescription.fromJson(
      asJsonMap(jsonDecode(workout.prescriptionJson), 'prescription'),
    );
    return prescription.exercises
        .map((exercise) => exercise.exercise.slug)
        .toSet();
  } on Object {
    return const <String>{};
  }
}

String _formatLastSet(LastPerformedSet set) {
  final load = set.loadKg == null
      ? '—'
      : '${set.loadKg!.toStringAsFixed(1)} kg';
  final rir = set.rir == null ? '' : ' @ ${set.rir} RIR';
  return '$load × ${set.repetitions}$rir';
}

String _titleFromSlug(String slug) => slug
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');
