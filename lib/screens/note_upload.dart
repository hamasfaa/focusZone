import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mini_project/services/firestore.dart';
import 'package:mini_project/services/storage_service.dart';
import 'package:mini_project/theme/zen_colors.dart';

class NoteUploadScreen extends StatefulWidget {
  const NoteUploadScreen({super.key, required this.activityId});

  final String activityId;

  @override
  State<NoteUploadScreen> createState() => _NoteUploadScreenState();
}

class _NoteUploadScreenState extends State<NoteUploadScreen> {
  final TextEditingController _noteController = TextEditingController();
  final List<XFile> _selectedImages = [];
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      _showSnackBar('Gagal membuka kamera: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      _showSnackBar('Gagal membuka galeri: $e');
    }
  }

  void _removeImage(XFile image) {
    setState(() {
      _selectedImages.remove(image);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty && _selectedImages.isEmpty) {
      _skip();
      return;
    }

    setState(() => _isUploading = true);

    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User tidak terautentikasi.');
      }

      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        final StorageService storageService = StorageService();
        imageUrls = await storageService.uploadActivityNotesImages(
          userId: userId,
          activityId: widget.activityId,
          imageFiles: _selectedImages,
        );
      }

      final String noteText = _noteController.text.trim();
      final FireStoreService fireStoreService = FireStoreService();
      await fireStoreService.addNoteToActivity(
        activityId: widget.activityId,
        noteText: noteText,
        imageUrls: imageUrls,
      );

      if (!mounted) return;
      _showSnackBar('Catatan berhasil disimpan!');
      Navigator.pushReplacementNamed(context, 'home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      _showSnackBar('Terjadi kesalahan: $e');
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, 'home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
          child: _isUploading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: ZenColors.primary),
                      SizedBox(height: 16),
                      Text(
                        'Menyimpan catatan...',
                        style: TextStyle(
                          color: ZenColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Bagaimana fokusmu tadi?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: ZenColors.text,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _noteController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Tulis sesuatu tentang sesi ini...',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: ZenColors.accent,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: ZenColors.accent,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: ZenColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Lampirkan Gambar (Opsional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ZenColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickFromCamera,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Kamera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ZenColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                foregroundColor: ZenColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickFromGallery,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galeri'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ZenColors.secondary.withValues(
                                  alpha: 0.1,
                                ),
                                foregroundColor: ZenColors.secondary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_selectedImages.isNotEmpty) ...[
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _selectedImages.map((image) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(image.path),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(image),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ZenColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Simpan Catatan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          foregroundColor: ZenColors.text.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        child: const Text('Lewati'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
