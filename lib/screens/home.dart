import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mini_project/services/firestore.dart';
import 'package:mini_project/theme/zen_colors.dart';
import 'package:mini_project/widgets/home/create_activity_form_sheet.dart';
import 'package:mini_project/widgets/home/home_activity_history_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final FireStoreService _fireStoreService = FireStoreService();
  bool _isCheckingRunningActivity = true;
  bool _isRedirectingToTimer = false;

  Widget _buildLoadingScaffold() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ZenColors.background, Color(0xFFF2EFE8), ZenColors.accent],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: ZenColors.primary),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _redirectToTimerIfNeeded();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _redirectToTimerIfNeeded();
    }
  }

  Future<void> _redirectToTimerIfNeeded() async {
    if (_isRedirectingToTimer) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      setState(() {
        _isCheckingRunningActivity = false;
      });
      Navigator.pushReplacementNamed(context, 'login');
      return;
    }

    try {
      final runningActivity = await _fireStoreService.getRunningActivityForUser(
        currentUser.uid,
      );
      if (!mounted) return;

      if (runningActivity != null) {
        _isRedirectingToTimer = true;
        Navigator.pushReplacementNamed(context, 'timer');
        return;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memeriksa aktivitas running.')),
      );
    }

    if (!mounted) return;
    setState(() {
      _isCheckingRunningActivity = false;
    });
  }

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
      status: FireStoreService.activityStatusRunning,
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

    if (!mounted) return;
    await _redirectToTimerIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingRunningActivity) {
      return _buildLoadingScaffold();
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, 'login');
      });
      return _buildLoadingScaffold();
    }

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
                  child: HomeActivityHistoryList(
                    userId: currentUser.uid,
                    fireStoreService: _fireStoreService,
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
