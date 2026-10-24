/// Formats a load in kilograms the way the app shows loads everywhere: up to
/// two decimals and no trailing zeros after the point (80, 72.5, 61.25).
String formatLoad(double value) => value
    .toStringAsFixed(2)
    .replaceFirst(RegExp(r'0+$'), '')
    .replaceFirst(RegExp(r'\.$'), '');
