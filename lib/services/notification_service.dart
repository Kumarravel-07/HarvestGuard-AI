import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class ReminderDetails {
  const ReminderDetails({
    required this.notificationId,
    required this.scheduledAt,
    required this.selectedDays,
  });

  final int notificationId;
  final DateTime scheduledAt;
  final int selectedDays;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _notifications.initialize(settings);
    _isInitialized = true;
  }

  Future<bool> requestAndroidPermission() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<ReminderDetails?> loadReminder(String batchKey) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey(batchKey));
    if (encoded == null) return null;

    try {
      final data = jsonDecode(encoded) as Map<String, dynamic>;
      return ReminderDetails(
        notificationId: data['notificationId'] as int,
        scheduledAt: DateTime.parse(data['scheduledAt'] as String),
        selectedDays: data['selectedDays'] as int,
      );
    } catch (_) {
      await preferences.remove(_storageKey(batchKey));
      return null;
    }
  }

  Future<ReminderDetails> scheduleReminder({
    required String batchKey,
    required int selectedDays,
    required String shelfLife,
  }) async {
    await initialize();
    final existing = await loadReminder(batchKey);
    final notificationId = _notificationId(batchKey);
    if (existing != null) await _notifications.cancel(existing.notificationId);

    final scheduledAt = DateTime.now().add(Duration(days: selectedDays));
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'shelf_life_reminders',
        'Shelf-Life Reminders',
        channelDescription: 'Reminders to check tomato batch condition',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

    await _notifications.zonedSchedule(
      notificationId,
      'HarvestGuard AI',
      'Time to check your tomato batch. Its estimated shelf-life is approaching. Estimated shelf life: $shelfLife.',
      tz.TZDateTime.from(scheduledAt, tz.UTC),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    final reminder = ReminderDetails(
      notificationId: notificationId,
      scheduledAt: scheduledAt,
      selectedDays: selectedDays,
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey(batchKey),
      jsonEncode({
        'notificationId': notificationId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'selectedDays': selectedDays,
        'batchKey': batchKey,
        'enabled': true,
      }),
    );
    return reminder;
  }

  Future<void> cancelReminder(String batchKey) async {
    final reminder = await loadReminder(batchKey);
    if (reminder != null) await _notifications.cancel(reminder.notificationId);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey(batchKey));
  }

  String _storageKey(String batchKey) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'signed_out';
    return 'shelf_life_reminder_${userId}_$batchKey';
  }

  int _notificationId(String value) {
    var hash = 2166136261;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }
}
