import 'package:flutter/material.dart';
import 'package:mini_project/controllers/auth_session_controller.dart';
import 'package:mini_project/theme/zen_colors.dart';
import 'package:mini_project/widgets/auth/auth_form_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthSessionController _authController = AuthSessionController();

  @override
  void initState() {
    super.initState();
    _authController.addListener(_onAuthControllerChanged);
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthControllerChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAuthControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _navigateRegister() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'register');
  }

  void _navigateHome() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'home');
  }

  Future<void> _login() async {
    final success = await _authController.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted || !success) return;
    _navigateHome();
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      middleGradientColor: const Color(0xFFF2EFE8),
      child: Column(
        children: [
          const AuthBrandHeader(fontSize: 32, letterSpacing: 0.6),
          const SizedBox(height: 24),
          AuthCardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: zenInputDecoration(
                    label: 'Email',
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: zenInputDecoration(
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                  ),
                ),
                const SizedBox(height: 20),
                if (_authController.errorMessage.isNotEmpty) ...[
                  Text(
                    _authController.errorMessage,
                    style: const TextStyle(
                      color: Color(0xFFB4533C),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                ],
                FilledButton(
                  onPressed: _authController.isLoading ? null : _login,
                  style: FilledButton.styleFrom(
                    backgroundColor: ZenColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _authController.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Masuk'),
                ),
                const SizedBox(height: 10),
                AuthSwitchText(
                  prompt: 'Belum punya akun? ',
                  actionText: 'Daftar di sini',
                  onPressed: _navigateRegister,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
