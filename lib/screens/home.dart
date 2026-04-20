import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mini_project/services/firestore.dart';
import 'package:mini_project/theme/zen_colors.dart';
import 'package:mini_project/widgets/home/create_activity_form_sheet.dart';
import 'package:mini_project/widgets/home/home_history_placeholder_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FireStoreService _fireStoreService = FireStoreService();

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'login');
  }

  Future<void> _saveActivity(
    String name,
    String description,
    int durationInSeconds,
  ) async {
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

  Future<void> _showCreateActivityForm() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CreateActivityFormSheet(onSubmit: _saveActivity);
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
        child: const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Riwayat Aktivitas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: ZenColors.text,
                  ),
                ),
                SizedBox(height: 18),
                Expanded(child: HomeHistoryPlaceholderCard()),
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
