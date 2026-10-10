import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class RestNotificationService {
  RestNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _notificationId = 9017;
  static const _silentChannelId = 'agonez_rest_timer_silent';
  static const _soundChannelId = 'agonez_rest_timer_sound';
  static const _payload = 'agonez://workout/focus';

  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> initialize({void Function()? onOpenWorkout}) async {
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == _payload) onOpenWorkout?.call();
      },
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final response = launchDetails?.notificationResponse;
      if (response?.payload == _payload) onOpenWorkout?.call();
    }
  }

  Future<bool?> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return null;
    return android.requestNotificationsPermission();
  }

  Future<void> schedule({
    required DateTime endsAt,
    required String exerciseName,
    required int setOrdinal,
    required String prescription,
    String? title,
    String? body,
    bool playSound = false,
  }) async {
    if (!endsAt.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      _notificationId,
      title ?? 'Rest complete',
      body ?? '$exerciseName · set $setOrdinal · $prescription',
      tz.TZDateTime.from(endsAt.toUtc(), tz.UTC),
      NotificationDetails(
        android: AndroidNotificationDetails(
          playSound ? _soundChannelId : _silentChannelId,
          'Rest timer',
          channelDescription: 'Notifies when a workout rest period is complete',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: playSound,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: _payload,
    );
  }

  Future<void> cancel() => _plugin.cancel(_notificationId);
}
