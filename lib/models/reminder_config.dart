class ReminderConfig {
  const ReminderConfig({
    required this.hour,
    required this.minute,
    required this.weekdays,
  });

  final int hour;
  final int minute;
  final List<int> weekdays;
}
