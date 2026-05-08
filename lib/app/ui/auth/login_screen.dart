// ignore_for_file: avoid_print
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/data/services/auth_service.dart';
import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:fitness_app/core/utils/app_assets.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Service & Screens

import 'package:fitness_app/app/ui/auth/forgot_password_screen.dart';
import 'package:fitness_app/app/ui/auth/signup_screen.dart';
import 'package:fitness_app/app/ui/auth/profile_completion_screen.dart';
//import 'package:fitness_app/utils/theme_provider.dart';
//import 'package:fitness_app/utils/app_assets.dart';
import 'package:fitness_app/view/main_tab/main_tab_view.dart';
//import 'package:fitness_app/utils/app_colors.dart';
//import 'package:fitness_app/commons/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService(); // Service instance

  bool _isPasswordHidden = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Common Navigation Handler ---
  Future<void> _handleNavigation(User user) async {
    try {
      // Syncing with service
      bool isComplete = await _authService.syncUserStatus(user);

      if (!mounted) return;

      // Conditional Redirection
      Widget target = isComplete
          ? const MainTabView()
          : const ProfileCompletionScreen();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => target),
        (route) => false,
      );
    } catch (e) {
      _showError("Sync Error: ${e.toString()}");
    }
  }

  // --- Auth Handlers using Service ---
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        UserCredential creds = await _authService.loginWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (creds.user != null) {
          // 🔥 Real-time App Logic: Check if Email is Verified
          if (creds.user!.emailVerified) {
            await _handleNavigation(creds.user!);
          } else {
            // Agar verify nahi hai toh logout kar dein aur msg dikhayen
            await FirebaseAuth.instance.signOut();
            _showError("Please verify your email first. Check your inbox.");
          }
        }
      } on FirebaseAuthException catch (e) {
        _showError(e.message ?? "Login failed");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      UserCredential? creds = await _authService.signInWithGoogle();
      if (creds?.user != null) await _handleNavigation(creds!.user!);
    } catch (e) {
      _showError("Google Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFacebookLogin() async {
    setState(() => _isLoading = true);
    try {
      UserCredential? creds = await _authService.signInWithFacebook();
      if (creds?.user != null) await _handleNavigation(creds!.user!);
    } catch (e) {
      _showError("Facebook Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1D1B20) : AppColors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            // 🔥 Premium Feel
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              // 🔥 Real-time validation
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text(
                    "Hey there,",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black,
                    ),
                  ),
                  Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 1. Email Field
                  _buildTextField(
                    controller: _emailController,
                    hint: "Email",
                    icon: Icons.email_outlined,
                    isDark: isDark,
                    validator: (val) {
                      if (val == null || val.isEmpty)
                        return "Email is required";
                      final bool emailValid = RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                      ).hasMatch(val);
                      if (!emailValid)
                        return "Please enter a valid email address";
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // 2. Password Field
                  _buildTextField(
                    controller: _passwordController,
                    hint: "Password",
                    icon: Icons.lock_outline,
                    isDark: isDark,
                    isPass: true,
                    validator: (val) {
                      if (val == null || val.isEmpty)
                        return "Password is required";
                      if (val.length < 8)
                        return "Password must be at least 8 characters";
                      return null;
                    },
                  ),

                  _buildForgotPasswordLink(),

                  // 🔥 Improved Spacing (Responsive feel)
                  const SizedBox(height: 40),

                  // 3. Login Button
                  CustomButton(
                    text: "Login",
                    icon: Icons.login,
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),

                  const SizedBox(height: 30),
                  _buildDivider(),
                  const SizedBox(height: 30),

                  // 4. Social Login Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialTile(AppAssets.Google, isDark, _handleGoogleLogin),
                      const SizedBox(width: 30),
                      _socialTile(
                        AppAssets.Facebook,
                        isDark,
                        _handleFacebookLogin,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  _buildRegisterLink(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // UI Helper functions bilkul same raheingi jo aapne pehle share ki theen...
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool isPass = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPass ? _isPasswordHidden : false,
      validator: validator,
      autofillHints: isPass
          ? [AutofillHints.password]
          : [AutofillHints.email, AutofillHints.username],

      keyboardType: isPass
          ? TextInputType.visiblePassword
          : TextInputType.emailAddress,

      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF7F8F8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            // Isko transparent rakhne se modern look aata hai
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFC58BF2), width: 1.5),
        ),
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(
                  _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _isPasswordHidden = !_isPasswordHidden),
              )
            : null,
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
        ),
        child: const Text(
          "Forgot your password?",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() => const Row(
    children: [
      Expanded(child: Divider()),
      Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("Or")),
      Expanded(child: Divider()),
    ],
  );

  Widget _socialTile(String path, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Image.asset(path, width: 25, height: 25),
      ),
    );
  }

  Widget _buildRegisterLink(bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignupScreen()),
      ),
      child: RichText(
        text: TextSpan(
          text: "Don’t have an account yet? ",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black),
          children: const [
            TextSpan(
              text: "Register",
              style: TextStyle(
                color: Color(0xFFC58BF2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
