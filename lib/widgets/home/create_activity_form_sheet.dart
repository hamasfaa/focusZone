import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mini_project/services/firestore.dart';
import 'package:mini_project/theme/zen_colors.dart';
import 'package:mini_project/widgets/auth/auth_form_widgets.dart';
import 'package:mini_project/widgets/home/time_adjust_box.dart';

typedef CreateActivitySubmit =
    Future<void> Function(
      String name,
      String description,
      int durationInSeconds,
      String? categoryId,
    );

class CreateActivityFormSheet extends StatefulWidget {
  const CreateActivityFormSheet({
    super.key,
    required this.onSubmit,
    required this.fireStoreService,
    required this.userId,
  });

  final CreateActivitySubmit onSubmit;
  final FireStoreService fireStoreService;
  final String userId;

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
  String? _selectedCategoryId;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _latestCategories = [];

  static const List<int> _categoryColors = [
    0xFFA3B18A,
    0xFFD4A373,
    0xFFCCD5AE,
    0xFFB7B7A4,
    0xFFE09F3E,
    0xFFCB997E,
  ];

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

  Future<void> _confirmDeleteCategory(
    String categoryId,
    String categoryName,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Kategori?'),
          content: Text(
            'Kategori "$categoryName" akan dihapus. Aktivitas yang sudah ada tetap tersimpan.',
          ),
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

    await widget.fireStoreService.deleteCategory(categoryId);

    if (!mounted) return;
    if (_selectedCategoryId == categoryId) {
      setState(() {
        _selectedCategoryId = null;
      });
    }
  }

  Future<void> _showCreateCategoryDialog() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _CreateCategoryDialog(
          fireStoreService: widget.fireStoreService,
          userId: widget.userId,
          categoryColors: _categoryColors,
        );
      },
    );
  }

  Future<void> _showCategoryPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _CategoryPickerSheet(
          fireStoreService: widget.fireStoreService,
          userId: widget.userId,
          selectedCategoryId: _selectedCategoryId,
          onSelect: (categoryId) {
            setState(() {
              _selectedCategoryId = categoryId;
            });
          },
          onDelete: _confirmDeleteCategory,
        );
      },
    );
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

    if (_selectedCategoryId == null) {
      if (_latestCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih atau buat kategori terlebih dahulu.'),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final categoryId = _selectedCategoryId ?? _latestCategories.first.id;

      await widget.onSubmit(name, description, durationInSeconds, categoryId);

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
              const Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ZenColors.text,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                stream: widget.fireStoreService.streamCategoriesForUser(
                  widget.userId,
                ),
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? [];
                  _latestCategories = categories;
                  final hasSelected =
                      _selectedCategoryId != null &&
                      categories.any((doc) => doc.id == _selectedCategoryId);
                  final effectiveSelectedId = hasSelected
                      ? _selectedCategoryId
                      : (categories.isNotEmpty ? categories.first.id : null);
                  final selectedDoc = categories.isEmpty
                      ? null
                      : categories.firstWhere(
                          (doc) => doc.id == effectiveSelectedId,
                          orElse: () => categories.first,
                        );
                  final selectedName = selectedDoc == null
                      ? 'Belum ada kategori'
                      : (selectedDoc.data()['name'] ?? '').toString();
                  final selectedColor = selectedDoc == null
                      ? ZenColors.accent.value
                      : (selectedDoc.data()['colorValue'] ??
                                ZenColors.accent.value)
                            as int;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        onTap: categories.isEmpty ? null : _showCategoryPicker,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: zenInputDecoration(
                            label: 'Pilih Kategori',
                            icon: Icons.category_rounded,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 6,
                                backgroundColor: Color(selectedColor),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: categories.isEmpty
                                        ? ZenColors.text.withValues(alpha: 0.6)
                                        : ZenColors.text,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.expand_more_rounded,
                                color: ZenColors.text,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showCreateCategoryDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tambah Kategori Baru'),
                        style: TextButton.styleFrom(
                          foregroundColor: ZenColors.secondary,
                        ),
                      ),
                    ],
                  );
                },
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

class _WeekdayOption {
  const _WeekdayOption({required this.day, required this.label});

  final int day;
  final String label;
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({
    required this.fireStoreService,
    required this.userId,
    required this.selectedCategoryId,
    required this.onSelect,
    required this.onDelete,
  });

  final FireStoreService fireStoreService;
  final String userId;
  final String? selectedCategoryId;
  final ValueChanged<String> onSelect;
  final Future<void> Function(String categoryId, String name) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: fireStoreService.streamCategoriesForUser(userId),
          builder: (context, snapshot) {
            final categories = snapshot.data ?? [];

            return Column(
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
                const SizedBox(height: 12),
                const Text(
                  'Pilih Kategori',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ZenColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                if (categories.isEmpty)
                  Text(
                    'Belum ada kategori.',
                    style: TextStyle(
                      color: ZenColors.text.withValues(alpha: 0.6),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final doc = categories[index];
                        final name = (doc.data()['name'] ?? '').toString();
                        final colorValue =
                            (doc.data()['colorValue'] ?? ZenColors.accent.value)
                                as int;
                        final isSelected = doc.id == selectedCategoryId;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              onSelect(doc.id);
                              Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ZenColors.primary.withValues(alpha: 0.08)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ZenColors.accent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 6,
                                    backgroundColor: Color(colorValue),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: ZenColors.text,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Hapus',
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Color(0xFFB4533C),
                                    ),
                                    onPressed: () async {
                                      await onDelete(doc.id, name);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CreateCategoryDialog extends StatefulWidget {
  const _CreateCategoryDialog({
    required this.fireStoreService,
    required this.userId,
    required this.categoryColors,
  });

  final FireStoreService fireStoreService;
  final String userId;
  final List<int> categoryColors;

  @override
  State<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedColor = 0xFFA3B18A;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryColors.isNotEmpty) {
      _selectedColor = widget.categoryColors.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.fireStoreService.addCategory(
        name: name,
        colorValue: _selectedColor,
        userId: widget.userId,
      );
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Kategori'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: zenInputDecoration(
                label: 'Nama Kategori',
                icon: Icons.category_rounded,
              ),
            ),
            const SizedBox(height: 12),
            const Text('Warna', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.categoryColors.map((colorValue) {
                final isSelected = _selectedColor == colorValue;
                return ChoiceChip(
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedColor = colorValue;
                    });
                  },
                  label: const Text(''),
                  avatar: CircleAvatar(
                    backgroundColor: Color(colorValue),
                    radius: 10,
                  ),
                  selectedColor: ZenColors.primary.withValues(alpha: 0.2),
                  backgroundColor: ZenColors.background,
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: _isSaving ? null : _save,
          child: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
        ),
      ],
    );
  }
}
