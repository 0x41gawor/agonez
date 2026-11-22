import 'package:flutter/foundation.dart';

/// One movement of a plan's warm-up or stretch note.
@immutable
class RoutineItem {
  const RoutineItem({required this.name, this.detail, this.dose});

  final String name;

  /// What the note put in brackets, such as "na czworaka".
  final String? detail;

  /// How much, as written at the end of the line: "10× / strona", "3–5 min".
  final String? dose;
}

/// Movements the note kept together. [title] is the label the lines shared,
/// such as "Ramp-up"; null for lines without one.
@immutable
class RoutineGroup {
  const RoutineGroup({required this.items, this.title});

  final String? title;
  final List<RoutineItem> items;
}

/// Reads a warm-up or stretch note as a list. The note is free text, but
/// plans keep one movement per line, usually ending in a dose ("10x/strona",
/// "2x30s", "3–5 min"), with a blank line between groups and sometimes a
/// label in front ("Ramp-up: …", "Reset - …"). A line that does not fit is
/// still one movement, named by the whole line.
List<RoutineGroup> parseRoutineNotes(String? text) {
  if (text == null || text.trim().isEmpty) return const [];
  final groups = <RoutineGroup>[];
  var items = <RoutineItem>[];
  String? title;

  void close() {
    if (items.isNotEmpty) groups.add(RoutineGroup(title: title, items: items));
    items = <RoutineItem>[];
    title = null;
  }

  for (final raw in text.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty) {
      close();
      continue;
    }
    String? label;
    var item = _item(line);
    final labelled = _label.firstMatch(line);
    if (labelled != null) {
      final rest = _item(labelled.group(2)!);
      // "Plank - 30s" is a movement and its dose, not a label.
      if (rest.name.isNotEmpty) {
        label = labelled.group(1);
        item = rest;
      }
    }
    if (items.isNotEmpty && label != title) close();
    title = label;
    items.add(
      item.name.isEmpty
          ? RoutineItem(name: line.replaceAll(_spaces, ' '))
          : item,
    );
  }
  close();

  // A lone group needs no title: the screen already says what it is.
  if (groups.length == 1 && groups.single.title != null) {
    return [RoutineGroup(items: groups.single.items)];
  }
  return groups;
}

/// A one-word label and a colon or a spaced dash: "Ramp-up: …", "Reset - …".
final _label = RegExp(
  r'^(\p{L}[\p{L}-]{1,19})\s*(?::|\s+[-–—])\s+(\S.*)$',
  unicode: true,
);

/// A dose at the end of the line, an optional "/side" after it, and an
/// optional bracketed note after that.
final _dose = RegExp(
  r'^(.*?)[\s:–—-]*'
  r'(\d+(?:[.,]\d+)?(?:\s*[–-]\s*\d+)?\s*'
  r'(?:[x×]\s*(?:\d+(?:\s*[–-]\s*\d+)?\s*(?:s|sek|min)?)?'
  r'|s|sek|min|serie|series|sets?|reps?|powt\.?))'
  r'(?:\s*/\s*(\p{L}+))?'
  r'(?:\s*\(([^)]*)\))?$',
  unicode: true,
  caseSensitive: false,
);

final _brackets = RegExp(r'\s*\(([^)]*)\)');
final _spaces = RegExp(r'\s+');
final _trailing = RegExp(r'[\s,;:–—-]+$');

RoutineItem _item(String line) {
  var name = line;
  String? dose;
  final details = <String>[];
  final match = _dose.firstMatch(line);
  if (match != null) {
    name = match.group(1)!;
    dose = _formatDose(match.group(2)!, match.group(3));
    final after = match.group(4)?.trim();
    if (after != null && after.isNotEmpty) details.add(after);
  }
  final inside = [
    for (final bracket in _brackets.allMatches(name))
      if (bracket.group(1)!.trim().isNotEmpty) bracket.group(1)!.trim(),
  ];
  name = name
      .replaceAll(_brackets, '')
      .replaceAll(_spaces, ' ')
      .replaceAll(_trailing, '')
      .trim();
  return RoutineItem(
    name: _capitalised(name),
    detail: [...inside, ...details].isEmpty
        ? null
        : [...inside, ...details].join(', '),
    dose: dose,
  );
}

String _formatDose(String dose, String? perSide) {
  final value = dose
      .trim()
      .replaceAllMapped(
        RegExp(r'(\d)\s*[x×](?!\s*\d)'),
        (match) => '${match[1]}×',
      )
      .replaceAllMapped(
        RegExp(r'(\d)\s*[x×]\s*(\d)'),
        (match) => '${match[1]} × ${match[2]}',
      )
      .replaceAllMapped(
        RegExp(r'(\d)\s*[–-]\s*(\d)'),
        (match) => '${match[1]}–${match[2]}',
      )
      .replaceAllMapped(
        RegExp(r'(\d)(min|sek|serie|series|sets?|reps?)', caseSensitive: false),
        (match) => '${match[1]} ${match[2]}',
      );
  return perSide == null ? value : '$value / $perSide';
}

String _capitalised(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
