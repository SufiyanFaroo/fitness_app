// ignore_for_file: avoid_print
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/data/services/auth_service.dart';
import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:fitness_app/core/utils/app_assets.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Screens & Utils
import 'package:fitness_app/app/ui/auth/login_screen.dart';
import 'package:fitness_app/app/ui/auth/profile_completion_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Service instance initialize karein
  final AuthService _authService = AuthService();

  bool _isPasswordHidden = true;
  bool _isAccepted = false;
  bool _isLoading = false;
  bool _isFieldsFilled = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateInputs);
    _emailController.addListener(_validateInputs);
    _phoneController.addListener(_validateInputs);
    _passwordController.addListener(_validateInputs);
  }

  void _validateInputs() {
    final bool allFilled =
        _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;

    if (allFilled != _isFieldsFilled) {
      setState(() {
        _isFieldsFilled = allFilled;
        if (!allFilled) _isAccepted = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Auth Handlers using AuthService ---
  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate() && _isAccepted) {
      setState(() => _isLoading = true);
      try {
        // Service se user create kiya
        UserCredential userCredential = await _authService.registerWithEmail(
          _emailController.text.trim().toLowerCase(),
          _passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          // Data save karne ke liye service call ki
          await _authService.saveInitialUserData(
            user: userCredential.user!,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileCompletionScreen(),
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        _showErrorSnackBar(
          e.code == 'email-already-in-use'
              ? "This email is already registered. Please Login."
              : e.message ?? "Registration Failed",
        );
      } catch (e) {
        _showErrorSnackBar("An unexpected error occurred: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Google & Facebook handlers bhi service use kareinge
  // Facebook Signup Handler
  Future<void> _handleFacebookSignup() async {
    setState(() => _isLoading = true);
    try {
      // 1. Service se Facebook login call kiya
      UserCredential? creds = await _authService.signInWithFacebook();

      if (creds?.user != null) {
        // 2. Initial data save karein (display name ke saath)
        await _authService.saveInitialUserData(
          user: creds!.user!,
          name: creds.user!.displayName ?? "Fitness User",
          phone: "",
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileCompletionScreen(),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar("Facebook Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignup() async {
    setState(() => _isLoading = true);
    try {
      UserCredential? creds = await _authService.signInWithGoogle();
      if (creds?.user != null) {
        await _authService.saveInitialUserData(
          user: creds!.user!,
          name: creds.user!.displayName ?? "Fitness User",
          phone: "",
        );
        if (mounted)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileCompletionScreen(),
            ),
          );
      }
    } catch (e) {
      _showErrorSnackBar("Google Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
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
                  const Text(
                    "Create an Account",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  // 1. Full Name Field
                  _buildField(
                    isDark,
                    _nameController,
                    "Full Name",
                    Icons.person_outline,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty)
                        return "Full Name is required";
                      if (val.trim().length < 3)
                        return "Name must be at least 3 characters";
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // 2. Phone Number Field
                  _buildField(
                    isDark,
                    _phoneController,
                    "Phone Number",
                    Icons.phone_outlined,
                    type: TextInputType.phone,
                    validator: (val) {
                      if (val == null || val.isEmpty)
                        return "Phone number is required";
                      if (!RegExp(r'^[0-9]+$').hasMatch(val))
                        return "Enter numbers only";
                      if (val.length < 10)
                        return "Enter a valid 10-11 digit number";
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // 3. Email Field
                  _buildField(
                    isDark,
                    _emailController,
                    "Email",
                    Icons.email_outlined,
                    type: TextInputType.emailAddress,
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

                  // 4. Password Field
                  _buildField(
                    isDark,
                    _passwordController,
                    "Password",
                    Icons.lock_outline,
                    isPass: true,
                    validator: (val) {
                      if (val == null || val.isEmpty)
                        return "Password is required";
                      if (val.length < 8)
                        return "Password must be at least 8 characters";
                      if (!RegExp(r'[A-Z]').hasMatch(val))
                        return "Add at least one uppercase letter";
                      if (!RegExp(r'[0-9]').hasMatch(val))
                        return "Add at least one number";
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),
                  _buildCheckboxSection(),
                  const SizedBox(height: 40),

                  // 5. Register Button
                  CustomButton(
                    text: "Register",
                    isLoading: _isLoading,
                    onPressed: () {
                      if (_isAccepted) {
                        _handleRegister();
                      } else {
                        String msg = !_isFieldsFilled
                            ? "Please fill all details first"
                            : "Please accept the Privacy Policy";
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 20),
                  _buildSocialSection(isDark),
                  const SizedBox(height: 25),
                  _buildLoginLink(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // UI Helper functions bilkul same raheingi jo aapne share ki theen...
  Widget _buildField(
    bool isDark,
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPass = false,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPass ? _isPasswordHidden : false,
      keyboardType: type,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        // Background color ko thora light rakhein
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF7F8F8),

        // ✅ 1. Enabled Border (Jab field active na ho)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            // Light mode mein halka grey aur Dark mode mein white opacity
            color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),

        // ✅ 2. Focused Border (Jab user type kar raha ho)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFC58BF2), // FitQuest Purple Theme
            width: 1.5,
          ),
        ),

        // ✅ 3. Error Border (Jab validation fail ho jaye)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),

        // ✅ 4. Focused Error Border
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCheckboxSection() {
    return Row(
      children: [
        Checkbox(
          value: _isAccepted,
          activeColor: const Color(0xFFC58BF2),
          onChanged: (val) => _isFieldsFilled
              ? setState(() => _isAccepted = val!)
              : _showErrorSnackBar("Please fill all fields first!"),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _isFieldsFilled
                ? setState(() => _isAccepted = !_isAccepted)
                : _showErrorSnackBar("Please fill all fields first!"),
            child: Text(
              "By continuing you accept our Privacy Policy and Term of Use",
              style: TextStyle(
                fontSize: 12,
                color: _isFieldsFilled
                    ? Colors.grey
                    : Colors.grey.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialSection(bool isDark) => Column(
    children: [
      Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "Or",
              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _socialTile(AppAssets.Google, isDark, _handleGoogleSignup),
          const SizedBox(width: 30),
          // --- YAHAN UPDATE KIYA ---
          _socialTile(AppAssets.Facebook, isDark, _handleFacebookSignup),
        ],
      ),
    ],
  );

  Widget _socialTile(String path, bool isDark, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Image.asset(path, width: 25, height: 25),
    ),
  );

  Widget _buildLoginLink(bool isDark) => GestureDetector(
    onTap: () => Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    ),
    child: RichText(
      text: TextSpan(
        text: "Already have an account? ",
        style: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
        children: const [
          TextSpan(
            text: "Login",
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
