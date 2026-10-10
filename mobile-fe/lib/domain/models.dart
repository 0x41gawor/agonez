import 'dart:convert';

typedef Json = Map<String, dynamic>;

class MobileContext {
  const MobileContext({
    this.contextVersion,
    this.planRun,
    this.today,
    this.expectedSession,
    this.activeWorkout,
    this.days = const [],
    this.recent = const [],
  });
  final String? contextVersion;
  final Json? planRun, today, expectedSession, activeWorkout;
  final List<Json> days, recent;
  factory MobileContext.fromJson(Json j) => MobileContext(
    contextVersion: j['context_version'] as String?,
    planRun: j['plan_run'] as Json?,
    today: j['today'] as Json?,
    expectedSession: j['expected_session'] as Json?,
    activeWorkout: j['active_workout'] as Json?,
    days: _maps(j['microcycle_days']),
    recent: _maps(j['recent']),
  );
}

class Prescription {
  const Prescription(this.raw);
  final Json raw;
  int get sessionId => raw['session_id'] as int;
  String get version => raw['prescription_version'] as String;
  String get name => raw['workout_unit_name'] as String;
  List<Json> get exercises => _maps(raw['exercises']);
  String encode() => jsonEncode(raw);
  factory Prescription.decode(String value) =>
      Prescription(jsonDecode(value) as Json);
}

class ApiFailure implements Exception {
  const ApiFailure(this.code, {this.details = const {}});
  final String code;
  final Json details;
  @override
  String toString() => 'ApiFailure($code)';
}

List<Json> _maps(Object? value) => (value as List? ?? const [])
    .whereType<Map>()
    .map((e) => Map<String, dynamic>.from(e))
    .toList();
