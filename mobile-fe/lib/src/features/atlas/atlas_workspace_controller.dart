import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../storage/app_database.dart';

const _workspaceUuid = Uuid();

@immutable
class AtlasWorkspacePage {
  const AtlasWorkspacePage({
    required this.exerciseId,
    required this.slug,
    required this.title,
  });

  factory AtlasWorkspacePage.fromJson(Map<String, Object?> json) {
    return AtlasWorkspacePage(
      exerciseId: switch (json['exercise_id']) {
        final int value => value,
        final num value => value.toInt(),
        _ => 0,
      },
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
    );
  }

  final int exerciseId;
  final String slug;
  final String title;

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': 'exercise',
    'exercise_id': exerciseId,
    'slug': slug,
    'title': title,
  };
}

@immutable
class AtlasWorkspaceEntry {
  const AtlasWorkspaceEntry({
    required this.id,
    required this.pages,
    required this.scrollOffset,
    required this.openedAt,
    required this.updatedAt,
  });

  final String id;
  final List<AtlasWorkspacePage> pages;
  final double scrollOffset;
  final DateTime openedAt;
  final DateTime updatedAt;

  AtlasWorkspacePage get page => pages.last;

  AtlasWorkspaceEntry copyWith({
    List<AtlasWorkspacePage>? pages,
    double? scrollOffset,
    DateTime? updatedAt,
  }) {
    return AtlasWorkspaceEntry(
      id: id,
      pages: pages ?? this.pages,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      openedAt: openedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@immutable
class OpenAtlasWorkspaceResult {
  const OpenAtlasWorkspaceResult({
    required this.workspace,
    required this.evictedOldest,
  });

  final AtlasWorkspaceEntry workspace;
  final bool evictedOldest;
}

/// Owns the client-only browser-tab state used by Atlas.
///
/// Every change is mirrored to Drift. An all-false `is_current` set represents
/// the Atlas index, allowing the last page and every article scroll position to
/// survive process death without expanding the server contract.
class AtlasWorkspaceController extends ChangeNotifier {
  AtlasWorkspaceController({
    required AppDatabase database,
    this.maximumWorkspaces = 8,
  }) : assert(maximumWorkspaces > 0),
       _database = database;

  final AppDatabase _database;
  final int maximumWorkspaces;

  List<AtlasWorkspaceEntry> _workspaces = const [];
  String? _currentId;
  bool _loaded = false;
  Future<void>? _restoreFuture;

  List<AtlasWorkspaceEntry> get workspaces => List.unmodifiable(_workspaces);
  int get count => _workspaces.length;
  bool get isLoaded => _loaded;
  String? get currentId => _currentId;

  AtlasWorkspaceEntry? get current {
    final id = _currentId;
    if (id == null) return null;
    for (final workspace in _workspaces) {
      if (workspace.id == id) return workspace;
    }
    return null;
  }

  Future<void> restore() {
    if (_loaded) return Future<void>.value();
    return _restoreFuture ??= _restore();
  }

  Future<void> _restore() async {
    final rows = await (_database.select(
      _database.atlasWorkspaces,
    )..orderBy([(row) => OrderingTerm.asc(row.openedAt)])).get();

    final restored = <AtlasWorkspaceEntry>[];
    String? restoredCurrent;
    for (final row in rows) {
      final pages = _decodePages(row);
      if (pages.isEmpty) continue;
      restored.add(
        AtlasWorkspaceEntry(
          id: row.workspaceId,
          pages: pages,
          scrollOffset: row.scrollOffset < 0 ? 0 : row.scrollOffset,
          openedAt: row.openedAt,
          updatedAt: row.updatedAt,
        ),
      );
      if (row.isCurrent) restoredCurrent = row.workspaceId;
    }

    // A previous version or interrupted write may have exceeded the cap. Keep
    // the most recently used entries, while retaining the selected workspace.
    while (restored.length > maximumWorkspaces) {
      final candidate = restored
          .where((workspace) => workspace.id != restoredCurrent)
          .reduce((a, b) => a.updatedAt.isBefore(b.updatedAt) ? a : b);
      restored.remove(candidate);
    }

    _workspaces = restored;
    _currentId = restored.any((item) => item.id == restoredCurrent)
        ? restoredCurrent
        : null;
    _loaded = true;
    notifyListeners();
    await _persist();
  }

  Future<OpenAtlasWorkspaceResult> openArticle({
    required int exerciseId,
    required String slug,
    required String title,
  }) async {
    _requireLoaded();
    final now = DateTime.now().toUtc();
    final existingIndex = _workspaces.indexWhere(
      (workspace) => workspace.pages.any((page) => page.slug == slug),
    );
    if (existingIndex >= 0) {
      final existing = _workspaces[existingIndex];
      final pageIndex = existing.pages.indexWhere((page) => page.slug == slug);
      final pages = <AtlasWorkspacePage>[...existing.pages.take(pageIndex + 1)];
      pages[pageIndex] = AtlasWorkspacePage(
        exerciseId: exerciseId,
        slug: slug,
        title: title,
      );
      final updated = existing.copyWith(pages: pages, updatedAt: now);
      _replace(existingIndex, updated);
      _currentId = updated.id;
      notifyListeners();
      await _persist();
      return OpenAtlasWorkspaceResult(workspace: updated, evictedOldest: false);
    }

    var evicted = false;
    if (_workspaces.length >= maximumWorkspaces) {
      final candidates = _workspaces
          .where((workspace) => workspace.id != _currentId)
          .toList(growable: false);
      final pool = candidates.isEmpty ? _workspaces : candidates;
      final oldest = pool.reduce(
        (a, b) => a.updatedAt.isBefore(b.updatedAt) ? a : b,
      );
      _workspaces = _workspaces
          .where((workspace) => workspace.id != oldest.id)
          .toList(growable: false);
      evicted = true;
    }

    final workspace = AtlasWorkspaceEntry(
      id: _workspaceUuid.v4(),
      pages: <AtlasWorkspacePage>[
        AtlasWorkspacePage(exerciseId: exerciseId, slug: slug, title: title),
      ],
      scrollOffset: 0,
      openedAt: now,
      updatedAt: now,
    );
    _workspaces = <AtlasWorkspaceEntry>[..._workspaces, workspace];
    _currentId = workspace.id;
    notifyListeners();
    await _persist();
    return OpenAtlasWorkspaceResult(
      workspace: workspace,
      evictedOldest: evicted,
    );
  }

  Future<void> pushArticle({
    required String workspaceId,
    required int exerciseId,
    required String slug,
    required String title,
  }) async {
    _requireLoaded();
    final index = _workspaces.indexWhere((item) => item.id == workspaceId);
    if (index < 0) return;
    final workspace = _workspaces[index];
    _replace(
      index,
      workspace.copyWith(
        pages: <AtlasWorkspacePage>[
          ...workspace.pages,
          AtlasWorkspacePage(exerciseId: exerciseId, slug: slug, title: title),
        ],
        scrollOffset: 0,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    _currentId = workspaceId;
    notifyListeners();
    await _persist();
  }

  Future<bool> popPage(String workspaceId) async {
    _requireLoaded();
    final index = _workspaces.indexWhere((item) => item.id == workspaceId);
    if (index < 0 || _workspaces[index].pages.length < 2) return false;
    final workspace = _workspaces[index];
    _replace(
      index,
      workspace.copyWith(
        pages: workspace.pages.sublist(0, workspace.pages.length - 1),
        scrollOffset: 0,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    notifyListeners();
    await _persist();
    return true;
  }

  Future<void> activate(String workspaceId) async {
    _requireLoaded();
    final index = _workspaces.indexWhere((item) => item.id == workspaceId);
    if (index < 0) return;
    final now = DateTime.now().toUtc();
    _replace(index, _workspaces[index].copyWith(updatedAt: now));
    _currentId = workspaceId;
    notifyListeners();
    await _persist();
  }

  Future<void> showIndex() async {
    _requireLoaded();
    if (_currentId == null) return;
    _currentId = null;
    notifyListeners();
    await _persist();
  }

  Future<void> close(String workspaceId) async {
    _requireLoaded();
    final existed = _workspaces.any((item) => item.id == workspaceId);
    if (!existed) return;
    _workspaces = _workspaces
        .where((workspace) => workspace.id != workspaceId)
        .toList(growable: false);
    if (_currentId == workspaceId) _currentId = null;
    notifyListeners();
    await _persist();
  }

  Future<void> saveScroll(String workspaceId, double offset) async {
    if (!_loaded || !offset.isFinite) return;
    final index = _workspaces.indexWhere((item) => item.id == workspaceId);
    if (index < 0) return;
    final workspace = _workspaces[index];
    final safeOffset = offset < 0 ? 0.0 : offset;
    if ((workspace.scrollOffset - safeOffset).abs() < 1) return;
    _replace(
      index,
      workspace.copyWith(
        scrollOffset: safeOffset,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await _persist();
  }

  void _replace(int index, AtlasWorkspaceEntry value) {
    final updated = [..._workspaces];
    updated[index] = value;
    _workspaces = updated;
  }

  List<AtlasWorkspacePage> _decodePages(AtlasWorkspace row) {
    try {
      final decoded = jsonDecode(row.navigationJson);
      if (decoded is List) {
        final pages = decoded
            .whereType<Map>()
            .map(
              (page) => AtlasWorkspacePage.fromJson(
                page.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .where((page) => page.slug.isNotEmpty)
            .toList(growable: false);
        if (pages.isNotEmpty) return pages;
      }
    } on FormatException {
      // Fall through to the denormalized columns for forward recovery.
    }
    final slug = row.slug;
    if (slug == null || slug.isEmpty) return const [];
    return <AtlasWorkspacePage>[
      AtlasWorkspacePage(exerciseId: 0, slug: slug, title: row.title),
    ];
  }

  Future<void> _persist() {
    return _database.replaceAtlasWorkspaces(
      _workspaces
          .map(
            (workspace) => AtlasWorkspacesCompanion.insert(
              workspaceId: workspace.id,
              kind: 'exercise',
              slug: Value(workspace.page.slug),
              title: workspace.page.title,
              navigationJson: Value(
                jsonEncode(
                  workspace.pages
                      .map((page) => page.toJson())
                      .toList(growable: false),
                ),
              ),
              scrollOffset: Value(workspace.scrollOffset),
              isCurrent: Value(workspace.id == _currentId),
              openedAt: workspace.openedAt,
              updatedAt: workspace.updatedAt,
            ),
          )
          .toList(growable: false),
    );
  }

  void _requireLoaded() {
    if (!_loaded) {
      throw StateError('Call AtlasWorkspaceController.restore() first');
    }
  }
}
