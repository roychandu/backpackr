import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static const String _dueRemindersKey = 'due_reminders_enabled';
  static const String _overdueAlertsKey = 'overdue_alerts_enabled';
  static const String _reminderDaysKey = 'reminder_days_before_due';
  static const String _chatNotificationsKey = 'chat_notifications_enabled';

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  // Initialize notifications
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notifications.initialize(initializationSettings);
    _isInitialized = true;
  }

  // Get notification preferences
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'dueReminders': prefs.getBool(_dueRemindersKey) ?? true,
      'overdueAlerts': prefs.getBool(_overdueAlertsKey) ?? false,
      'reminderDays': prefs.getInt(_reminderDaysKey) ?? 2,
      'chatNotifications': prefs.getBool(_chatNotificationsKey) ?? true,
    };
  }

  // Save notification preferences
  Future<bool> saveNotificationPreferences({
    required bool dueReminders,
    int? reminderDays,
    bool? chatNotifications,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dueRemindersKey, dueReminders);
      if (reminderDays != null) {
        await prefs.setInt(_reminderDaysKey, reminderDays);
      }
      if (chatNotifications != null) {
        await prefs.setBool(_chatNotificationsKey, chatNotifications);
      }
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error saving notification preferences: $e');
      return false;
    }
  }

  // Check if due reminders are enabled
  Future<bool> areDueRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dueRemindersKey) ?? true;
  }

  // Check if overdue alerts are enabled
  Future<bool> areOverdueAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_overdueAlertsKey) ?? false;
  }

  // Get reminder days before due date
  Future<int> getReminderDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_reminderDaysKey) ?? 2;
  }

  // Check if chat notifications are enabled
  Future<bool> areChatNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chatNotificationsKey) ?? true;
  }

  // Show immediate notification for testing
  Future<void> showTestNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'general_notifications',
          'General Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Demo method to show how notifications work
  Future<void> demonstrateNotifications() async {
    await initialize();

    // Show immediate notification
    await showTestNotification(
      title: 'Notification Demo',
      body:
          'This is a test notification to demonstrate the notification system',
    );

    // Schedule a notification for 10 seconds from now
    final scheduledTime = DateTime.now().add(const Duration(seconds: 10));

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'general_notifications',
          'General Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.zonedSchedule(
      999999, // Unique ID for demo
      'Scheduled Reminder',
      'This notification was scheduled 10 seconds ago',
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'demo_notification',
    );
  }

  // Test method to schedule a notification for testing
  Future<void> testScheduledNotification() async {
    await initialize();

    print('Testing scheduled notification...');

    // Schedule a notification for 10 seconds from now
    final scheduledTime = DateTime.now().add(const Duration(seconds: 10));
    print('Scheduling test notification for: $scheduledTime');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'general_notifications',
          'General Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      await _notifications.zonedSchedule(
        888888, // Unique ID for test
        'Test Reminder',
        'This is a test notification scheduled for 10 seconds from now',
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'test_notification',
      );
      print('Test notification scheduled successfully');
    } catch (e) {
      print('Error scheduling test notification: $e');
      rethrow;
    }
  }

  // Show chat notification
  Future<void> showChatNotification({
    required String title,
    required String body,
    required String conversationId,
    String? payload,
  }) async {
    await initialize();

    // Check if chat notifications are enabled
    if (!await areChatNotificationsEnabled()) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'chat_notifications',
          'Chat Messages',
          channelDescription: 'Notifications for new chat messages',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload ?? conversationId,
    );
  }

  // Show chat notification with custom icon
  Future<void> showChatNotificationWithIcon({
    required String title,
    required String body,
    required String conversationId,
    String? payload,
  }) async {
    await initialize();

    // Check if chat notifications are enabled
    if (!await areChatNotificationsEnabled()) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'chat_notifications',
          'Chat Messages',
          channelDescription: 'Notifications for new chat messages',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload ?? conversationId,
    );
  }
}
