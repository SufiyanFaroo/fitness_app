// ignore_for_file: avoid_print
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/data/services/auth_service.dart';
import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService(); // Service instance call
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // --- Reset Password Logic (Service Integrated) ---
  Future<void> _resetPassword() async {
    String email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      _showSnackBar("Please enter your email address", Colors.orange);
      return;
    }

    bool isValidEmail = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);

    if (!isValidEmail) {
      _showSnackBar("Please enter a valid email format", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Service call to send reset email
      await _authService.sendPasswordReset(email);

      if (mounted) {
        _showSnackBar(
          "Reset link sent! Please check your inbox.",
          Colors.green,
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred. Please try again.";
      if (e.code == 'user-not-found') {
        message = "No account found with this email.";
      } else if (e.code == 'too-many-requests') {
        message = "Too many attempts. Please try again later.";
      }
      _showSnackBar(message, Colors.redAccent);
    } catch (e) {
      _showSnackBar(
        "Something went wrong. Check connection.",
        Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1D1B20) : AppColors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            "Reset Password",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDark ? Colors.white : Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC58BF2).withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 60,
                    color: Color(0xFFC58BF2),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "Forgot Password?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "Enter your email address below. We will send you a secure link to reset your password.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                _buildEmailField(isDark),
                const SizedBox(height: 40),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFC58BF2),
                        ),
                      )
                    : CustomButton(
                        text: "Send Reset Link",
                        onPressed: _resetPassword,
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Remember Password? Login",
                    style: TextStyle(
                      color: Color(0xFFC58BF2),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField(bool isDark) {
    return TextFormField(
      // TextField ko TextFormField se replace kiya
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [
        AutofillHints.email,
      ], // Keyboard email suggest karega
      style: TextStyle(color: isDark ? Colors.white : Colors.black),

      // 🔥 Real-time validation trigger
      autovalidateMode: AutovalidateMode.onUserInteraction,

      validator: (val) {
        if (val == null || val.isEmpty) return "Email is required";
        final bool emailValid = RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
        ).hasMatch(val);
        if (!emailValid) return "Please enter a valid email address";
        return null;
      },

      decoration: InputDecoration(
        hintText: 'Enter your email',
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: Color(0xFFC58BF2),
          size: 22,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF7F8F8),

        // ✅ Professional Borders (Same as your other screens)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFC58BF2), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
