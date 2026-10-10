import 'dart:io';

import 'package:agonez/src/features/atlas/atlas_workspace_controller.dart';
import 'package:agonez/src/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDirectory;
  late File databaseFile;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'agonez-atlas-workspaces-',
    );
    databaseFile = File('${tempDirectory.path}/atlas.sqlite');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'workspaces, current article, back stack and scroll survive reopen',
    () async {
      var database = AppDatabase(NativeDatabase(databaseFile));
      var controller = AtlasWorkspaceController(database: database);
      await controller.restore();

      final bench = await controller.openArticle(
        exerciseId: 41,
        slug: 'barbell_bench_press',
        title: 'Barbell Bench Press',
      );
      await controller.pushArticle(
        workspaceId: bench.workspace.id,
        exerciseId: 12,
        slug: 'pectoralis_major',
        title: 'Pectoralis major',
      );
      await controller.saveScroll(bench.workspace.id, 318.5);
      await database.close();

      database = AppDatabase(NativeDatabase(databaseFile));
      controller = AtlasWorkspaceController(database: database);
      await controller.restore();

      expect(controller.count, 1);
      expect(controller.currentId, bench.workspace.id);
      expect(controller.current!.pages, hasLength(2));
      expect(controller.current!.page.slug, 'pectoralis_major');
      expect(controller.current!.scrollOffset, 318.5);

      expect(await controller.popPage(controller.current!.id), isTrue);
      expect(controller.current!.page.slug, 'barbell_bench_press');
      await database.close();
    },
  );

  test('ninth article evicts the oldest non-current workspace', () async {
    final database = AppDatabase(NativeDatabase(databaseFile));
    final controller = AtlasWorkspaceController(
      database: database,
      maximumWorkspaces: 2,
    );
    await controller.restore();
    final first = await controller.openArticle(
      exerciseId: 1,
      slug: 'first',
      title: 'First',
    );
    final second = await controller.openArticle(
      exerciseId: 2,
      slug: 'second',
      title: 'Second',
    );
    await controller.activate(first.workspace.id);

    final third = await controller.openArticle(
      exerciseId: 3,
      slug: 'third',
      title: 'Third',
    );

    expect(third.evictedOldest, isTrue);
    expect(controller.workspaces.map((workspace) => workspace.page.slug), [
      'first',
      'third',
    ]);
    expect(
      controller.workspaces.any(
        (workspace) => workspace.id == second.workspace.id,
      ),
      isFalse,
    );
    await database.close();
  });

  test(
    'opening an existing slug focuses it instead of duplicating it',
    () async {
      final database = AppDatabase(NativeDatabase(databaseFile));
      final controller = AtlasWorkspaceController(database: database);
      await controller.restore();
      final original = await controller.openArticle(
        exerciseId: 8,
        slug: 'lat_pulldown',
        title: 'Lat Pulldown',
      );
      await controller.showIndex();

      final reopened = await controller.openArticle(
        exerciseId: 8,
        slug: 'lat_pulldown',
        title: 'Lat Pulldown',
      );

      expect(controller.count, 1);
      expect(reopened.workspace.id, original.workspace.id);
      expect(controller.currentId, original.workspace.id);
      await database.close();
    },
  );
}
