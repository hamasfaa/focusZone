import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mini_project/services/firestore.dart';
import 'package:mini_project/theme/zen_colors.dart';
import 'package:mini_project/widgets/auth/auth_form_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final FireStoreService _fireStoreService = FireStoreService();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'login');
  }

  Future<void> _saveActivity({
    required String name,
    required String description,
    required int durationInSeconds,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Sesi login tidak ditemukan.');
    }

    await _fireStoreService.addActivity(
      name: name,
      description: description,
      durationInSeconds: durationInSeconds,
      userId: currentUser.uid,
      status: FireStoreService.activityStatusCompleted,
    );
  }

  String _formatDuration(int hours, int minutes) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(hours)}:${twoDigits(minutes)}';
  }

  Future<void> _showCreateActivityForm() async {
    _nameController.clear();
    _descriptionController.clear();

    int selectedHours = 0;
    int selectedMinutes = 0;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            void changeHours(int delta) {
              setModalState(() {
                selectedHours = (selectedHours + delta).clamp(0, 23);
              });
            }

            void changeMinutes(int delta) {
              setModalState(() {
                selectedMinutes = (selectedMinutes + delta).clamp(0, 59);
              });
            }

            Future<void> submit() async {
              if (isSaving) return;

              final name = _nameController.text.trim();
              final description = _descriptionController.text.trim();

              if (name.isEmpty || description.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nama dan deskripsi wajib diisi.'),
                  ),
                );
                return;
              }

              final durationInSeconds =
                  (selectedHours * 3600) + (selectedMinutes * 60);

              if (durationInSeconds <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Atur durasi minimal 1 menit.')),
                );
                return;
              }

              setModalState(() {
                isSaving = true;
              });

              try {
                await _saveActivity(
                  name: name,
                  description: description,
                  durationInSeconds: durationInSeconds,
                );

                if (!mounted) return;

                Navigator.of(modalContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aktivitas fokus berhasil dibuat.'),
                  ),
                );

                return;
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal membuat aktivitas: $e')),
                );

                setModalState(() {
                  isSaving = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                MediaQuery.of(modalContext).viewInsets.bottom + 16,
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
                        'Tambah Aktivitas Fokus',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: ZenColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Isi nama, deskripsi, lalu atur waktu dengan tombol + dan -.',
                        style: TextStyle(
                          color: ZenColors.text.withValues(alpha: 0.74),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: zenInputDecoration(
                          label: 'Nama Aktivitas',
                          icon: Icons.edit_note_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: zenInputDecoration(
                          label: 'Deskripsi',
                          icon: Icons.subject_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Durasi: ${_formatDuration(selectedHours, selectedMinutes)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ZenColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _TimeAdjustBox(
                              label: 'Jam',
                              value: selectedHours,
                              onIncrement: () => changeHours(1),
                              onDecrement: () => changeHours(-1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TimeAdjustBox(
                              label: 'Menit',
                              value: selectedMinutes,
                              onIncrement: () => changeMinutes(1),
                              onDecrement: () => changeMinutes(-1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: isSaving ? null : submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: ZenColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: isSaving
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
                        label: Text(
                          isSaving ? 'Menyimpan...' : 'Simpan Aktivitas',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusZone'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
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
                  'Riwayat Aktivitas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: ZenColors.text,
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: ZenColors.accent, width: 1.2),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history_edu_rounded,
                              size: 52,
                              color: ZenColors.secondary.withValues(alpha: 0.9),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada history aktivitas',
                              style: TextStyle(
                                color: ZenColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tambahkan aktivitas pertama kamu dari tombol + di bawah.',
                              style: TextStyle(
                                color: ZenColors.text.withValues(alpha: 0.72),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateActivityForm,
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

class _TimeAdjustBox extends StatelessWidget {
  const _TimeAdjustBox({
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String label;
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: ZenColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZenColors.accent, width: 1.1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ZenColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: ZenColors.secondary,
            visualDensity: VisualDensity.compact,
            splashRadius: 20,
          ),
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: ZenColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: ZenColors.secondary,
            visualDensity: VisualDensity.compact,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
