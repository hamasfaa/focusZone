import 'package:flutter/material.dart';
import 'package:mini_project/theme/zen_colors.dart';
import 'package:mini_project/widgets/auth/auth_form_widgets.dart';
import 'package:mini_project/widgets/home/time_adjust_box.dart';

typedef CreateActivitySubmit =
    Future<void> Function(
      String name,
      String description,
      int durationInSeconds,
    );

class CreateActivityFormSheet extends StatefulWidget {
  const CreateActivityFormSheet({super.key, required this.onSubmit});

  final CreateActivitySubmit onSubmit;

  @override
  State<CreateActivityFormSheet> createState() =>
      _CreateActivityFormSheetState();
}

class _CreateActivityFormSheetState extends State<CreateActivityFormSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedHours = 0;
  int _selectedMinutes = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDuration(int hours, int minutes) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(hours)}:${twoDigits(minutes)}';
  }

  void _changeHours(int delta) {
    setState(() {
      _selectedHours = (_selectedHours + delta).clamp(0, 23);
    });
  }

  void _changeMinutes(int delta) {
    setState(() {
      _selectedMinutes = (_selectedMinutes + delta).clamp(0, 59);
    });
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan deskripsi wajib diisi.')),
      );
      return;
    }

    final durationInSeconds = (_selectedHours * 3600) + (_selectedMinutes * 60);
    if (durationInSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Atur durasi minimal 1 menit.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSubmit(name, description, durationInSeconds);

      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktivitas fokus berhasil dibuat.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuat aktivitas: $e')));

      setState(() {
        _isSaving = false;
      });
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
                style: TextStyle(color: ZenColors.text.withValues(alpha: 0.74)),
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
                'Durasi: ${_formatDuration(_selectedHours, _selectedMinutes)}',
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
                    child: TimeAdjustBox(
                      label: 'Jam',
                      value: _selectedHours,
                      onIncrement: () => _changeHours(1),
                      onDecrement: () => _changeHours(-1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TimeAdjustBox(
                      label: 'Menit',
                      value: _selectedMinutes,
                      onIncrement: () => _changeMinutes(1),
                      onDecrement: () => _changeMinutes(-1),
                    ),
                  ),
                ],
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
                label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Aktivitas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
