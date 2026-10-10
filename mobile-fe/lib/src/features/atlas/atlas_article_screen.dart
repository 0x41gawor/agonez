import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../api/atlas_models.dart';
import '../../atlas/widgets/anatomy_heatmap.dart';
import '../../data/mobile_repository.dart';
import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';
import 'atlas_data_source.dart';
import 'atlas_workspace_controller.dart';

class AtlasArticleScreen extends StatefulWidget {
  const AtlasArticleScreen({
    required this.dataSource,
    required this.workspace,
    required this.workspaceCount,
    required this.hasActiveWorkout,
    required this.onBack,
    required this.onOpenWorkspaces,
    required this.onSaveScroll,
    this.todayExerciseSlugs = const <String>{},
    super.key,
  });

  final AtlasDataSource dataSource;
  final AtlasWorkspaceEntry workspace;
  final int workspaceCount;
  final bool hasActiveWorkout;
  final Set<String> todayExerciseSlugs;
  final VoidCallback onBack;
  final VoidCallback onOpenWorkspaces;
  final ValueChanged<double> onSaveScroll;

  @override
  State<AtlasArticleScreen> createState() => _AtlasArticleScreenState();
}

class _AtlasArticleScreenState extends State<AtlasArticleScreen> {
  late ScrollController _scrollController;
  late Future<_ArticleBundle> _future;
  final _sectionKeys = List.generate(5, (_) => GlobalKey());
  int _selectedSection = 0;
  Timer? _saveDebounce;
  bool _showRecovery = false;
  String? _selectedMuscle;

  AtlasWorkspacePage get _page => widget.workspace.page;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.workspace.scrollOffset,
    )..addListener(_onScroll);
    _load();
  }

  @override
  void didUpdateWidget(covariant AtlasArticleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspace.id != widget.workspace.id ||
        oldWidget.workspace.page.slug != widget.workspace.page.slug) {
      _saveDebounce?.cancel();
      oldWidget.onSaveScroll(_scrollController.offset);
      _scrollController
        ..removeListener(_onScroll)
        ..dispose();
      _scrollController = ScrollController(
        initialScrollOffset: widget.workspace.scrollOffset,
      )..addListener(_onScroll);
      _selectedSection = 0;
      _selectedMuscle = null;
      _showRecovery = false;
      _load();
    }
  }

  void _load() {
    _future = _loadBundle();
  }

  Future<_ArticleBundle> _loadBundle() async {
    final article = await widget.dataSource.loadArticle(_page.slug);
    LoadedValue<AtlasPeek>? peek;
    if (_page.exerciseId > 0) {
      try {
        peek = await widget.dataSource.loadPeek(_page.exerciseId);
      } on Object {
        // The full desktop route can remain useful when the compact mobile
        // peek is unavailable. Its engine vectors still drive the article.
      }
    }
    return _ArticleBundle(article: article, peek: peek);
  }

  void _retry() => setState(_load);

  void _onScroll() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(
      const Duration(milliseconds: 300),
      () => widget.onSaveScroll(_scrollController.offset),
    );
    _updateScrollSpy();
  }

  void _updateScrollSpy() {
    var selected = 0;
    for (var index = 0; index < _sectionKeys.length; index++) {
      final context = _sectionKeys[index].currentContext;
      final box = context?.findRenderObject() as RenderBox?;
      if (box != null &&
          box.attached &&
          box.localToGlobal(Offset.zero).dy < 155) {
        selected = index;
      }
    }
    if (selected != _selectedSection && mounted) {
      setState(() => _selectedSection = selected);
    }
  }

  void _scrollTo(int section) {
    setState(() => _selectedSection = section);
    final target = _sectionKeys[section].currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: .08,
      );
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    widget.onSaveScroll(
      _scrollController.hasClients ? _scrollController.offset : 0,
    );
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      bottom: false,
      child: FutureBuilder<_ArticleBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Column(
              children: [
                _AtlasArticleTopBar(
                  title: _page.title,
                  workspaceCount:
                      widget.workspaceCount + (widget.hasActiveWorkout ? 1 : 0),
                  onBack: widget.onBack,
                  onOpenWorkspaces: widget.onOpenWorkspaces,
                ),
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Column(
              children: [
                _AtlasArticleTopBar(
                  title: _page.title,
                  workspaceCount:
                      widget.workspaceCount + (widget.hasActiveWorkout ? 1 : 0),
                  onBack: widget.onBack,
                  onOpenWorkspaces: widget.onOpenWorkspaces,
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: AgonezInsets.card,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 34,
                            color: context.agonezColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.atlasOfflineUnavailable,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.commonRetry),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return _buildArticle(context, snapshot.requireData);
        },
      ),
    );
  }

  Widget _buildArticle(BuildContext context, _ArticleBundle bundle) {
    final l10n = AppLocalizations.of(context);
    final detail = bundle.article.value;
    final peek = bundle.peek?.value;
    final sectionLabels = <String>[
      l10n.atlasSectionTechnique,
      l10n.atlasSectionAnatomy,
      l10n.atlasSectionMuscles,
      l10n.atlasSectionData,
      l10n.atlasSectionVideo,
    ];
    final exposure = _exposureMap(detail, peek, recovery: _showRecovery);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: _AtlasArticleTopBar(
            title: detail.name,
            workspaceCount:
                widget.workspaceCount + (widget.hasActiveWorkout ? 1 : 0),
            onBack: widget.onBack,
            onOpenWorkspaces: widget.onOpenWorkspaces,
          ),
        ),
        SliverToBoxAdapter(
          child: _ArticleHero(
            detail: detail,
            peek: peek,
            offline: bundle.article.offline,
            inWorkout: widget.todayExerciseSlugs.contains(detail.slug),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _SectionHeaderDelegate(
            labels: sectionLabels,
            selected: _selectedSection,
            onSelected: _scrollTo,
          ),
        ),
        SliverToBoxAdapter(
          child: _ArticleSection(
            key: _sectionKeys[0],
            title: l10n.atlasSectionTechnique,
            child: _TechniqueSection(detail: detail, peek: peek),
          ),
        ),
        SliverToBoxAdapter(
          child: _ArticleSection(
            key: _sectionKeys[1],
            title: l10n.atlasSectionAnatomy,
            child: Column(
              children: [
                AnatomyHeatmap(
                  regionIntensities: exposure,
                  height: 320,
                  semanticsLabel: l10n.atlasSectionAnatomy,
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: <ButtonSegment<bool>>[
                    ButtonSegment(value: false, label: Text(l10n.atlasEtu)),
                    ButtonSegment(value: true, label: Text(l10n.atlasRecovery)),
                  ],
                  selected: <bool>{_showRecovery},
                  onSelectionChanged: (selection) {
                    setState(() => _showRecovery = selection.first);
                  },
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _ArticleSection(
            key: _sectionKeys[2],
            title: l10n.atlasMuscleExposure,
            child: _MuscleSection(
              detail: detail,
              peek: peek,
              selected: _selectedMuscle,
              onSelected: (value) => setState(
                () => _selectedMuscle = _selectedMuscle == value ? null : value,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _ArticleSection(
            key: _sectionKeys[3],
            title: l10n.atlasSectionData,
            child: _DataSection(detail: detail),
          ),
        ),
        SliverToBoxAdapter(
          child: _ArticleSection(
            key: _sectionKeys[4],
            title: l10n.atlasVideos,
            child: _VideoSection(urls: detail.videoLinks),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _ArticleBundle {
  const _ArticleBundle({required this.article, required this.peek});

  final LoadedValue<ExerciseDetail> article;
  final LoadedValue<AtlasPeek>? peek;
}

class _AtlasArticleTopBar extends StatelessWidget {
  const _AtlasArticleTopBar({
    required this.title,
    required this.workspaceCount,
    required this.onBack,
    required this.onOpenWorkspaces,
  });

  final String title;
  final int workspaceCount;
  final VoidCallback onBack;
  final VoidCallback onOpenWorkspaces;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.commonBack,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Semantics(
            button: true,
            label: l10n.workspaceCounterA11y(workspaceCount),
            child: IconButton(
              onPressed: onOpenWorkspaces,
              icon: _WorkspaceCount(count: workspaceCount),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceCount extends StatelessWidget {
  const _WorkspaceCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 25, minHeight: 25),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        border: Border.all(color: context.agonezColors.gold, width: 1.5),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontFamily: 'Geist Mono',
          color: context.agonezColors.goldText,
        ),
      ),
    );
  }
}

class _ArticleHero extends StatelessWidget {
  const _ArticleHero({
    required this.detail,
    required this.peek,
    required this.offline,
    required this.inWorkout,
  });

  final ExerciseDetail detail;
  final AtlasPeek? peek;
  final bool offline;
  final bool inWorkout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalEtu = _totalEtu(detail, peek);
    final peakJoint = _peakJoint(detail);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AgonezEyebrow(
                  '${l10n.atlasTitle} · ${l10n.atlasExercises}',
                  color: context.agonezColors.goldText,
                ),
              ),
              if (offline)
                AgonezTag(
                  label: l10n.syncOfflineTitle,
                  color: context.agonezColors.caution,
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(detail.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            detail.nameFull,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.agonezColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AgonezTag(label: detail.slug),
              ...?peek?.tags.map((tag) => AgonezTag(label: tag)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value: detail.loadCapacity?.toStringAsFixed(0) ?? '—',
                  unit: detail.loadCapacity == null ? '' : 'kg',
                  label: l10n.atlasLoadCapacity,
                ),
              ),
              Expanded(
                child: _Stat(
                  value: totalEtu?.toStringAsFixed(1) ?? '—',
                  unit: totalEtu == null ? '' : 'cm²',
                  label: l10n.atlasTotalEtu,
                ),
              ),
              Expanded(
                child: _Stat(
                  value: peakJoint ?? '—',
                  unit: '',
                  label: l10n.atlasPeakJoint,
                ),
              ),
            ],
          ),
          if (inWorkout) ...[
            const SizedBox(height: 14),
            AgonezPanel(
              backgroundColor: context.agonezColors.prescriptionBackground,
              borderColor: context.agonezColors.prescription,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 18,
                    color: context.agonezColors.prescriptionText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l10n.atlasInTodayWorkout)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.unit, required this.label});

  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: context.agonezColors.lineSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: value,
                children: [
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(fontSize: 10),
                    ),
                ],
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Geist Mono',
                color: context.agonezColors.goldText,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.agonezColors.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SectionHeaderDelegate({
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.agonezColors.ground,
        border: Border.symmetric(
          horizontal: BorderSide(color: context.agonezColors.lineSubtle),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, index) => TextButton(
          onPressed: () => onSelected(index),
          style: TextButton.styleFrom(
            foregroundColor: index == selected
                ? context.agonezColors.goldText
                : context.agonezColors.textDim,
            shape: const RoundedRectangleBorder(),
            side: BorderSide(
              color: index == selected
                  ? context.agonezColors.gold
                  : Colors.transparent,
              width: 0,
            ),
          ),
          child: Text(labels[index].toUpperCase()),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) =>
      selected != oldDelegate.selected || labels != oldDelegate.labels;
}

class _ArticleSection extends StatelessWidget {
  const _ArticleSection({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TechniqueSection extends StatelessWidget {
  const _TechniqueSection({required this.detail, required this.peek});

  final ExerciseDetail detail;
  final AtlasPeek? peek;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cues = peek == null
        ? detail.technique.entries
              .map(
                (entry) => (_prettyKey(entry.key), _displayValue(entry.value)),
              )
              .where((entry) => entry.$2.isNotEmpty)
              .toList(growable: false)
        : <(String, String)>[
            if (peek!.techniqueTldr.setup?.isNotEmpty ?? false)
              (l10n.atlasTechniqueSetup, peek!.techniqueTldr.setup!),
            if (peek!.techniqueTldr.execution?.isNotEmpty ?? false)
              (l10n.atlasTechniqueExecution, peek!.techniqueTldr.execution!),
            if (peek!.techniqueTldr.focus?.isNotEmpty ?? false)
              (l10n.atlasTechniqueFocus, peek!.techniqueTldr.focus!),
            if (peek!.techniqueTldr.stopWhen?.isNotEmpty ?? false)
              (l10n.atlasTechniqueStopWhen, peek!.techniqueTldr.stopWhen!),
          ];
    final comments = detail.comments.entries
        .map((entry) => _displayValue(entry.value))
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    return Column(
      children: [
        for (final cue in cues)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: AgonezPanel(
              padding: const EdgeInsets.all(13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    margin: const EdgeInsets.only(right: 10, top: 1),
                    color: context.agonezColors.gold,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AgonezEyebrow(
                          cue.$1,
                          color: context.agonezColors.goldText,
                        ),
                        const SizedBox(height: 5),
                        Text(cue.$2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        for (final comment in comments)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              comment,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.agonezColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

class _MuscleSection extends StatelessWidget {
  const _MuscleSection({
    required this.detail,
    required this.peek,
    required this.selected,
    required this.onSelected,
  });

  final ExerciseDetail detail;
  final AtlasPeek? peek;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final muscles = peek?.musclesTop;
    if (muscles != null && muscles.isNotEmpty) {
      return Column(
        children: muscles
            .map(
              (muscle) => _MuscleRow(
                id: muscle.slug,
                name: muscle.name,
                value: muscle.etuCm2,
                share: muscle.capacityShare,
                selected: selected == muscle.slug,
                onTap: onSelected,
              ),
            )
            .toList(growable: false),
      );
    }
    final values = detail.engine?.etuVector ?? const <String, double>{};
    final max = values.values.fold<double>(0, math.max);
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: entries
          .map(
            (entry) => _MuscleRow(
              id: entry.key,
              name: _prettyKey(entry.key),
              value: entry.value,
              share: max <= 0 ? null : entry.value / max,
              selected: selected == entry.key,
              onTap: onSelected,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MuscleRow extends StatelessWidget {
  const _MuscleRow({
    required this.id,
    required this.name,
    required this.value,
    required this.share,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String name;
  final double value;
  final double? share;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: () => onTap(id),
        borderRadius: AgonezRadii.controlBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? context.agonezColors.goldSoft
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: context.agonezColors.lineSubtle),
            ),
          ),
          child: Row(
            children: [
              Expanded(child: Text(name)),
              Text(
                value.toStringAsFixed(1),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontFamily: 'Geist Mono',
                  color: context.agonezColors.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 78,
                child: LinearProgressIndicator(
                  value: (share ?? 0).clamp(0.0, 1.0),
                  minHeight: 5,
                  color: context.agonezColors.muscleHeat,
                  backgroundColor: context.agonezColors.control,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataSection extends StatelessWidget {
  const _DataSection({required this.detail});

  final ExerciseDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgonezEyebrow(l10n.atlasClassification),
        const SizedBox(height: 6),
        _KeyValue(label: 'Body part', value: detail.bodyPart),
        _KeyValue(label: 'Target', value: detail.targetCategory),
        _KeyValue(label: 'Mechanics', value: detail.mechanicsTier),
        _KeyValue(label: 'Resistance', value: detail.resistanceSource),
        _KeyValue(label: 'Pattern', value: detail.executionPattern),
        const SizedBox(height: 20),
        AgonezEyebrow(l10n.atlasRepRanges),
        const SizedBox(height: 6),
        _KeyValue(
          label: 'High load',
          value: _range(detail.recommendedRepProfile.highLoad),
        ),
        _KeyValue(
          label: 'Moderate load',
          value: _range(detail.recommendedRepProfile.moderateLoad),
        ),
        _KeyValue(
          label: 'Low load',
          value: _range(detail.recommendedRepProfile.lowLoad),
        ),
      ],
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.agonezColors.lineSubtle),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: context.agonezColors.textMuted),
            ),
          ),
          Text(value, style: const TextStyle(fontFamily: 'Geist Mono')),
        ],
      ),
    );
  }
}

class _VideoSection extends StatelessWidget {
  const _VideoSection({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (urls.isEmpty) {
      return Text(
        l10n.commonNotAvailableYet,
        style: TextStyle(color: context.agonezColors.textMuted),
      );
    }
    return Column(
      children: urls
          .map(
            (url) => AgonezPanel(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    color: context.agonezColors.goldText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      url,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

Map<String, double> _exposureMap(
  ExerciseDetail detail,
  AtlasPeek? peek, {
  required bool recovery,
}) {
  if (!recovery && peek != null) {
    return <String, double>{
      for (final region in peek.bodyMap.regions)
        region.regionId: region.intensity,
    };
  }
  final values = recovery
      ? detail.engine?.muscleRecoveryCostModifierVector
      : detail.engine?.etuVector;
  if (values == null || values.isEmpty) return const <String, double>{};
  final maxValue = values.values
      .where((value) => value.isFinite)
      .fold<double>(0, math.max);
  if (maxValue <= 0) return const <String, double>{};
  return values.map(
    (key, value) => MapEntry(key, (value / maxValue).clamp(0.0, 1.0)),
  );
}

double? _totalEtu(ExerciseDetail detail, AtlasPeek? peek) {
  final values = detail.engine?.etuVector?.values;
  if (values != null && values.isNotEmpty) {
    return values.fold<double>(0, (sum, value) => sum + value);
  }
  if (peek != null && peek.musclesTop.isNotEmpty) {
    return peek.musclesTop.fold<double>(
      0,
      (sum, muscle) => sum + muscle.etuCm2,
    );
  }
  return null;
}

String? _peakJoint(ExerciseDetail detail) {
  final values = detail.engine?.jointLoadExposureVector;
  if (values == null || values.isEmpty) return null;
  return _prettyKey(
    values.entries.reduce((a, b) => a.value >= b.value ? a : b).key,
  );
}

String _range(RecommendedRepRange? range) =>
    range == null ? '—' : '${range.min}–${range.max}';

String _prettyKey(String value) {
  if (value.isEmpty) return value;
  final words = value.replaceAll('_', ' ').split(RegExp(r'\s+'));
  return words
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

String _displayValue(Object? value) {
  return switch (value) {
    null => '',
    final String text => text.trim(),
    final List<Object?> values =>
      values.map(_displayValue).where((part) => part.isNotEmpty).join('\n'),
    final Map<Object?, Object?> values =>
      values.values
          .map(_displayValue)
          .where((part) => part.isNotEmpty)
          .join('\n'),
    _ => value.toString(),
  };
}
