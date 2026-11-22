import 'package:agonez/src/workout/routine_notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  (String, String?, String?) read(RoutineItem item) =>
      (item.name, item.detail, item.dose);

  test('each line is a movement with its dose', () {
    final groups = parseRoutineNotes(
      'Cardio 3–5 min\n'
      'Cat Cow 10x\n'
      'Thoracic Rotation (na czworaka) 10x/strona\n'
      'Band Pull-Aparts 1x15\n'
      'Arm Circles 10x (przód/tył)\n'
      'Plank (core napięty, miednica neutralna) 1x20s\n'
      'Wall Thoracic Lat Stretch 2x30s/strona\n'
      '90/90 Belly Breathing 2 min',
    );

    expect(groups, hasLength(1));
    expect(groups.single.title, isNull);
    expect(groups.single.items.map(read).toList(), [
      ('Cardio', null, '3–5 min'),
      ('Cat Cow', null, '10×'),
      ('Thoracic Rotation', 'na czworaka', '10× / strona'),
      ('Band Pull-Aparts', null, '1 × 15'),
      ('Arm Circles', 'przód/tył', '10×'),
      ('Plank', 'core napięty, miednica neutralna', '1 × 20s'),
      ('Wall Thoracic Lat Stretch', null, '2 × 30s / strona'),
      ('90/90 Belly Breathing', null, '2 min'),
    ]);
  });

  test('a blank line and a shared label start a new group', () {
    final groups = parseRoutineNotes(
      'Cardio 3–5 min\n'
      'Cat Cow 10x\n'
      '\n'
      'Ramp-up: Barbell Bench Press 3–4 serie\n'
      'Ramp-up: Bent-Over Row 1–2 serie',
    );

    expect(groups.map((group) => group.title).toList(), [null, 'Ramp-up']);
    expect(groups.last.items.map(read).toList(), [
      ('Barbell Bench Press', null, '3–4 serie'),
      ('Bent-Over Row', null, '1–2 serie'),
    ]);
  });

  test('a label every line repeats is dropped', () {
    // Copied from a spreadsheet: tabs at the end and the section in front.
    final groups = parseRoutineNotes(
      'Warmup - Cardio 3-5min\t\t\t\t\n'
      'Warmup - world’s greatest stretch 10x\t\t\t\t\n'
      'Warmup -  glute bridge 2x12\t\t\t\t',
    );

    expect(groups.single.title, isNull);
    expect(groups.single.items.map(read).toList(), [
      ('Cardio', null, '3–5 min'),
      ('World’s greatest stretch', null, '10×'),
      ('Glute bridge', null, '2 × 12'),
    ]);
  });

  test('different labels make different groups', () {
    final groups = parseRoutineNotes(
      'Stretch - Standing quadricep 2x30s\n'
      'Stretch - Wall calf 2x30s\n'
      'Reset - “V” leżenie na wałku - 5 min\n'
      'Reset - Oddech przeponowy (lying 90-90 belly breathing) 3-5min',
    );

    expect(groups.map((group) => group.title).toList(), ['Stretch', 'Reset']);
    expect(groups.last.items.map(read).toList(), [
      ('“V” leżenie na wałku', null, '5 min'),
      ('Oddech przeponowy', 'lying 90-90 belly breathing', '3–5 min'),
    ]);
  });

  test('names with a dash or a slash are kept whole', () {
    final groups = parseRoutineNotes(
      'Foam Roller — Thoracic Extension 1 min\n'
      'Donkey Kicks / Fire Hydrant 1x10/strona\n'
      'Plank - 30s',
    );

    expect(groups.single.items.map(read).toList(), [
      ('Foam Roller — Thoracic Extension', null, '1 min'),
      ('Donkey Kicks / Fire Hydrant', null, '1 × 10 / strona'),
      ('Plank', null, '30s'),
    ]);
  });

  test('a line without a dose is the movement as written', () {
    final groups = parseRoutineNotes('Easy walk on the treadmill\n  \n');

    expect(groups.single.items.map(read).toList(), [
      ('Easy walk on the treadmill', null, null),
    ]);
  });

  test('an empty note is no list', () {
    expect(parseRoutineNotes(null), isEmpty);
    expect(parseRoutineNotes('  \n\t\n'), isEmpty);
  });
}
