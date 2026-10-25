import 'package:agonez/src/settings/app_settings_controller.dart';
import 'package:agonez/src/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('set numbering starts at 1 and remembers a change to 0', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final first = await AppSettingsController.load(database);
    expect(first.setNumberingStart, 1);

    await first.setSetNumberingStart(0);
    final reloaded = await AppSettingsController.load(database);

    expect(reloaded.setNumberingStart, 0);
  });
}
