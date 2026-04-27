import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mini_project/services/firestore.dart';
import 'package:mini_project/services/reminder_service.dart';
import 'package:mini_project/theme/zen_colors.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final FireStoreService _fireStoreService = FireStoreService();
  final ReminderService _reminderService = ReminderService();
  final Set<String> _busyReminderIds = {};

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _showCreateReminderSheet() async {
    final userId = _userId;
    if (userId == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CreateReminderSheet(
          onSubmit: (title, time, weekdays) async {
            final notificationIds = await _reminderService
                .scheduleWeeklyReminder(
                  title: title,
                  body: 'Saatnya mulai aktivitasmu.',
                  hour: time.hour,
                  minute: time.minute,
                  weekdays: weekdays,
                );

            await _fireStoreService.addReminder(
              title: title,
              userId: userId,
              hour: time.hour,
              minute: time.minute,
              weekdays: weekdays,
              notificationIds: notificationIds,
              isEnabled: true,
            );
          },
        );
      },
    );
  }

  Future<void> _toggleReminder(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    bool isEnabled,
  ) async {
    if (_busyReminderIds.contains(doc.id)) return;

    setState(() {
      _busyReminderIds.add(doc.id);
    });

    try {
      final data = doc.data();
      final title = (data['title'] ?? 'Reminder').toString();
      final hour = (data['hour'] ?? 0) as int;
      final minute = (data['minute'] ?? 0) as int;
      final weekdays = List<int>.from(data['weekdays'] ?? []);
      final notificationIds = List<int>.from(data['notificationIds'] ?? []);

      if (!isEnabled) {
        await _reminderService.cancelNotifications(notificationIds);
        await _fireStoreService.updateReminder(
          reminderId: doc.id,
          isEnabled: false,
        );
      } else {
        final newNotificationIds = await _reminderService
            .scheduleWeeklyReminder(
              title: title,
              body: 'Saatnya mulai aktivitasmu.',
              hour: hour,
              minute: minute,
              weekdays: weekdays,
            );
        await _fireStoreService.updateReminder(
          reminderId: doc.id,
          notificationIds: newNotificationIds,
          isEnabled: true,
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengubah status reminder.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _busyReminderIds.remove(doc.id);
      });
    }
  }

  Future<void> _deleteReminder(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Reminder?'),
          content: const Text('Reminder ini akan dihapus permanen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final notificationIds = List<int>.from(doc.data()['notificationIds'] ?? []);
    await _reminderService.cancelNotifications(notificationIds);
    await _fireStoreService.deleteReminder(doc.id);
  }

  String _formatTime(int hour, int minute) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(hour)}:${twoDigits(minute)}';
  }

  String _formatWeekdays(List<int> weekdays) {
    const labels = {
      1: 'Sen',
      2: 'Sel',
      3: 'Rab',
      4: 'Kam',
      5: 'Jum',
      6: 'Sab',
      7: 'Min',
    };
    final sorted = [...weekdays]..sort();
    return sorted.map((day) => labels[day] ?? '?').join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;
    if (userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, 'login');
      });
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ZenColors.background,
                Color(0xFFF2EFE8),
                ZenColors.accent,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: ZenColors.primary),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('images/logo.png', height: 40, fit: BoxFit.contain),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ZenColors.background, Color(0xFFF2EFE8), ZenColors.accent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Pengingat Aktivitas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: ZenColors.text,
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child:
                      StreamBuilder<
                        List<QueryDocumentSnapshot<Map<String, dynamic>>>
                      >(
                        stream: _fireStoreService.streamRemindersForUser(
                          userId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: ZenColors.primary,
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Gagal memuat reminder: ${snapshot.error}',
                                style: const TextStyle(color: ZenColors.text),
                              ),
                            );
                          }

                          final reminders = snapshot.data ?? [];
                          if (reminders.isEmpty) {
                            return Center(
                              child: Text(
                                'Belum ada reminder.',
                                style: TextStyle(
                                  color: ZenColors.text.withValues(alpha: 0.7),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: reminders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final doc = reminders[index];
                              final data = doc.data();
                              final title = (data['title'] ?? 'Reminder')
                                  .toString();
                              final hour = (data['hour'] ?? 0) as int;
                              final minute = (data['minute'] ?? 0) as int;
                              final weekdays = List<int>.from(
                                data['weekdays'] ?? [],
                              );
                              final isEnabled =
                                  (data['isEnabled'] ?? true) as bool;
                              final isBusy = _busyReminderIds.contains(doc.id);

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: ZenColors.accent,
                                    width: 1.1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: ZenColors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.alarm_rounded,
                                        color: ZenColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: ZenColors.text,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_formatTime(hour, minute)} · ${_formatWeekdays(weekdays)}',
                                            style: TextStyle(
                                              color: ZenColors.text.withValues(
                                                alpha: 0.7,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: isEnabled,
                                      onChanged: isBusy
                                          ? null
                                          : (value) =>
                                                _toggleReminder(doc, value),
                                      activeColor: ZenColors.primary,
                                    ),
                                    IconButton(
                                      tooltip: 'Hapus',
                                      onPressed: isBusy
                                          ? null
                                          : () => _deleteReminder(doc),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Color(0xFFB4533C),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateReminderSheet,
        backgroundColor: ZenColors.secondary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white.withValues(alpha: 0.95),
        height: 62,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
      ),
    );
  }
}

class _CreateReminderSheet extends StatefulWidget {
  const _CreateReminderSheet({required this.onSubmit});

  final Future<void> Function(String title, TimeOfDay time, List<int> weekdays)
  onSubmit;

  @override
  State<_CreateReminderSheet> createState() => _CreateReminderSheetState();
}

class _CreateReminderSheetState extends State<_CreateReminderSheet> {
  final TextEditingController _titleController = TextEditingController();
  final Set<int> _selectedWeekdays = {};
  TimeOfDay? _time;
  bool _isSaving = false;

  static const List<_WeekdayOption> _weekdayOptions = [
    _WeekdayOption(day: 1, label: 'Sen'),
    _WeekdayOption(day: 2, label: 'Sel'),
    _WeekdayOption(day: 3, label: 'Rab'),
    _WeekdayOption(day: 4, label: 'Kam'),
    _WeekdayOption(day: 5, label: 'Jum'),
    _WeekdayOption(day: 6, label: 'Sab'),
    _WeekdayOption(day: 7, label: 'Min'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final initial = _time ?? const TimeOfDay(hour: 7, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);

    if (picked == null) return;

    setState(() {
      _time = picked;
    });
  }

  void _toggleWeekday(int day) {
    setState(() {
      if (_selectedWeekdays.contains(day)) {
        _selectedWeekdays.remove(day);
      } else {
        _selectedWeekdays.add(day);
      }
    });
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama reminder wajib diisi.')),
      );
      return;
    }

    if (_time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jam reminder terlebih dahulu.')),
      );
      return;
    }

    if (_selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 hari reminder.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSubmit(title, _time!, _selectedWeekdays.toList()..sort());
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder berhasil dibuat.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal membuat reminder.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ZenColors.accent, width: 1.2),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ZenColors.accent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tambah Reminder',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ZenColors.text,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama Reminder',
                  prefixIcon: Icon(Icons.alarm_rounded),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time_rounded),
                label: Text(
                  _time == null
                      ? 'Pilih Jam'
                      : 'Jam: ${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ZenColors.text,
                  side: const BorderSide(color: ZenColors.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pilih Hari',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ZenColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _weekdayOptions.map((option) {
                  final isSelected = _selectedWeekdays.contains(option.day);
                  return FilterChip(
                    label: Text(option.label),
                    selected: isSelected,
                    onSelected: (_) => _toggleWeekday(option.day),
                    selectedColor: ZenColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: ZenColors.primary,
                    backgroundColor: Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: ZenColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.add_task_rounded),
                label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayOption {
  const _WeekdayOption({required this.day, required this.label});

  final int day;
  final String label;
}
