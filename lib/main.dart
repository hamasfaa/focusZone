import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mini_project/screens/home.dart';
import 'package:mini_project/screens/login.dart';
import 'package:mini_project/screens/register.dart';
import 'package:mini_project/screens/timer.dart';
import 'package:mini_project/theme/zen_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: ZenColors.primary,
          brightness: Brightness.light,
          primary: ZenColors.primary,
          secondary: ZenColors.secondary,
          surface: ZenColors.background,
        ).copyWith(
          tertiary: ZenColors.accent,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: ZenColors.text,
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: ZenColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: ZenColors.text,
          centerTitle: true,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: ZenColors.text,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
          bodyMedium: TextStyle(color: ZenColors.text),
        ),
      ),
      initialRoute: 'login',
      routes: {
        'login': (context) => const LoginScreen(),
        'register': (context) => const RegisterScreen(),
        'home': (context) => const HomeScreen(),
        'timer': (context) => const TimerScreen(),
      },
    );
  }
}
