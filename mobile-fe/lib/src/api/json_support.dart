typedef JsonMap = Map<String, Object?>;

JsonMap asJsonMap(Object? value, [String name = 'value']) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, child) => MapEntry(key.toString(), child));
  }
  throw FormatException('$name must be a JSON object');
}

List<Object?> asJsonList(Object? value, [String name = 'value']) {
  if (value is List<Object?>) {
    return value;
  }
  if (value is List) {
    return value.cast<Object?>();
  }
  throw FormatException('$name must be a JSON array');
}

Object? requiredJson(JsonMap json, String key) {
  if (!json.containsKey(key)) {
    throw FormatException('Missing required JSON field "$key"');
  }
  return json[key];
}

String asString(Object? value, [String name = 'value']) {
  if (value is String) {
    return value;
  }
  throw FormatException('$name must be a string');
}

String? asNullableString(Object? value, [String name = 'value']) =>
    value == null ? null : asString(value, name);

int asInt(Object? value, [String name = 'value']) {
  if (value is int) {
    return value;
  }
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw FormatException('$name must be an integer');
}

int? asNullableInt(Object? value, [String name = 'value']) =>
    value == null ? null : asInt(value, name);

double asDouble(Object? value, [String name = 'value']) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }
  throw FormatException('$name must be a number');
}

double? asNullableDouble(Object? value, [String name = 'value']) =>
    value == null ? null : asDouble(value, name);

bool asBool(Object? value, [String name = 'value']) {
  if (value is bool) {
    return value;
  }
  throw FormatException('$name must be a boolean');
}

DateTime asDateTime(Object? value, [String name = 'value']) {
  final text = asString(value, name);
  final parsed = DateTime.tryParse(text);
  if (parsed == null) {
    throw FormatException('$name must be an RFC 3339 date-time');
  }
  return parsed;
}

DateTime? asNullableDateTime(Object? value, [String name = 'value']) =>
    value == null ? null : asDateTime(value, name);

List<T> decodeList<T>(
  Object? value,
  T Function(Object? value) decode, [
  String name = 'value',
]) => asJsonList(value, name).map(decode).toList(growable: false);

String encodeDateTime(DateTime value) {
  if (value.isUtc) {
    return value.toIso8601String();
  }
  final offset = value.timeZoneOffset;
  final negative = offset.isNegative;
  final absoluteMinutes = offset.inMinutes.abs();
  final hours = (absoluteMinutes ~/ 60).toString().padLeft(2, '0');
  final minutes = (absoluteMinutes % 60).toString().padLeft(2, '0');
  return '${value.toIso8601String()}${negative ? '-' : '+'}$hours:$minutes';
}

void putIfNotNull(JsonMap json, String key, Object? value) {
  if (value != null) {
    json[key] = value;
  }
}
