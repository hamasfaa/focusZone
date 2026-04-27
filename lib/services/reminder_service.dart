import 'package:awesome_notifications/awesome_notifications.dart';

class ReminderService {
  Future<List<int>> scheduleWeeklyReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    required List<int> weekdays,
  }) async {
    if (weekdays.isEmpty) {
      return [];
    }

    final bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    final bool isNowAllowed = await AwesomeNotifications()
        .isNotificationAllowed();
    if (!isNowAllowed) {
      throw Exception('Izin notifikasi ditolak.');
    }

    final int baseId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final List<int> notificationIds = [];

    for (int index = 0; index < weekdays.length; index++) {
      final int day = weekdays[index];
      final int notificationId = baseId + index;
      notificationIds.add(notificationId);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'timer_channel',
          title: title,
          body: body,
        ),
        schedule: NotificationCalendar(
          weekday: day,
          hour: hour,
          minute: minute,
          second: 0,
          millisecond: 0,
          repeats: true,
        ),
      );
    }

    return notificationIds;
  }

  Future<void> cancelNotifications(List<int> notificationIds) async {
    for (final id in notificationIds) {
      await AwesomeNotifications().cancel(id);
    }
  }
}
