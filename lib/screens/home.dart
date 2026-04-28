import 'package:flutter/material.dart';
import 'package:mini_project/controllers/home_session_controller.dart';
import 'package:mini_project/services/firestore.dart';
import 'package:mini_project/theme/zen_colors.dart';
import 'package:mini_project/widgets/home/create_activity_form_sheet.dart';
import 'package:mini_project/widgets/home/daily_target_card.dart';
import 'package:mini_project/widgets/home/home_activity_history_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final HomeSessionController _homeController;

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
    _homeController = HomeSessionController(
      fireStoreService: FireStoreService(),
    );
    _homeController.addListener(_onHomeControllerChanged);
    WidgetsBinding.instance.addObserver(this);
    _redirectToTimerIfNeeded();
  }

  @override
  void dispose() {
    _homeController.removeListener(_onHomeControllerChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onHomeControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Widget _buildDailyTargetLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ZenColors.accent, width: 1.1),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: ZenColors.primary),
      ),
    );
  }

  Future<void> _showDailyTargetDialog({
    required int currentTargetMinutes,
  }) async {
    final controller = TextEditingController(
      text: currentTargetMinutes > 0 ? currentTargetMinutes.toString() : '',
    );

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Atur Target Harian'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Menit per hari',
              hintText: 'Contoh: 60',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null || value <= 0 || value > 1440) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Masukkan target 1 - 1440 menit.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    final currentUserId = _homeController.currentUserId;
    if (currentUserId == null) return;

    await _homeController.fireStoreService.upsertDailyTarget(
      userId: currentUserId,
      dailyTargetMinutes: result,
    );
  }

  Widget _buildDailyTargetSection(String userId) {
    return StreamBuilder(
      stream: _homeController.fireStoreService.streamUserProfile(userId),
      builder: (context, userSnapshot) {
        final data = userSnapshot.data?.data() ?? {};
        final targetMinutes = (data['dailyTargetMinutes'] ?? 0) as int;

        return StreamBuilder(
          stream: _homeController.fireStoreService.streamActivitiesForUser(
            userId,
          ),
          builder: (context, activitySnapshot) {
            if (activitySnapshot.connectionState == ConnectionState.waiting &&
                !activitySnapshot.hasData) {
              return _buildDailyTargetLoadingCard();
            }

            final activities = activitySnapshot.data ?? [];

            return DailyTargetCard(
              activities: activities,
              targetMinutes: targetMinutes,
              onEditTarget: () =>
                  _showDailyTargetDialog(currentTargetMinutes: targetMinutes),
            );
          },
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _redirectToTimerIfNeeded();
    }
  }

  Future<void> _redirectToTimerIfNeeded() async {
    final checkResult = await _homeController.checkRouteOnHomeEntry();
    if (!mounted) return;

    if (checkResult.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(checkResult.errorMessage!)));
    }

    if (checkResult.shouldRedirect) {
      Navigator.pushReplacementNamed(context, checkResult.redirectRoute!);
    }
  }

  Future<void> _logout() async {
    await _homeController.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'login');
  }

  Future<void> _saveActivity(
    String name,
    String description,
    int durationInSeconds,
    String? categoryId,
  ) async {
    await _homeController.saveRunningActivity(
      name: name,
      description: description,
      durationInSeconds: durationInSeconds,
      categoryId: categoryId,
    );
  }

  Future<void> _showCreateActivityForm() async {
    final currentUserId = _homeController.currentUserId;
    if (currentUserId == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CreateActivityFormSheet(
          onSubmit: _saveActivity,
          fireStoreService: _homeController.fireStoreService,
          userId: currentUserId,
        );
      },
    );

    if (!mounted) return;
    await _redirectToTimerIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    if (_homeController.isCheckingRunningActivity) {
      return _buildLoadingScaffold();
    }

    final currentUserId = _homeController.currentUserId;
    if (currentUserId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, 'login');
      });
      return _buildLoadingScaffold();
    }

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('images/logo.png', height: 40, fit: BoxFit.contain),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, 'reminders'),
            icon: const Icon(Icons.alarm_rounded),
            tooltip: 'Reminder',
          ),
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
                _buildDailyTargetSection(currentUserId),
                const SizedBox(height: 18),
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
                    userId: currentUserId,
                    fireStoreService: _homeController.fireStoreService,
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
