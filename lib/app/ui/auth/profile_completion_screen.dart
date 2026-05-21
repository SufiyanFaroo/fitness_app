import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/data/services/auth_service.dart';
import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:fitness_app/core/utils/app_assets.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/core/widgets/custom_button.dart';
import 'package:fitness_app/app/ui/auth/goal_selection_screen.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});
  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final AuthService _authService = AuthService(); // Service instance

  String? _selectedGender;
  final _dateController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _weightUnit = "KG";
  String _heightUnit = "CM";
  bool _isLoading = false;

  @override
  void dispose() {
    _dateController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // --- Logic call via AuthService ---
  Future<void> _updateProfile() async {
    if (_selectedGender == null ||
        _dateController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _heightController.text.isEmpty) {
      _showErrorSnackBar("Please fill all the details!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // Preparing data map
      // _updateProfile function ke andar
      Map<String, dynamic> profileData = {
        'gender': _selectedGender,
        'dob': _dateController.text.trim(),
        'weight': "${_weightController.text} $_weightUnit",
        'height': "${_heightController.text} $_heightUnit",
        'profile_completed': true,
        'updated_at': FieldValue.serverTimestamp(), // 🔥 Best for Firestore
      };

      // Service call
      await _authService.updateProfileData(
        uid: user.uid,
        profileData: profileData,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GoalSelectionScreen()),
        );
      }
    } catch (e) {
      _showErrorSnackBar("Sync Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String msg) {
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
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1D1B20) : AppColors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Image.asset(
                            AppAssets.Complete_your_profile,
                            width: 380,
                            height: 280,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Let’s complete your profile",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const Text(
                            "It will help us to know more about you!",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 25),

                          _buildGenderDropdown(isDark),
                          const SizedBox(height: 15),
                          _buildDatePicker(isDark),
                          const SizedBox(height: 15),
                          _buildWeightField(isDark),
                          const SizedBox(height: 15),
                          _buildHeightField(isDark),

                          const Spacer(),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 30, top: 20),
                            child: CustomButton(
                              text: "Next >",
                              onPressed: _updateProfile,
                              isLoading: _isLoading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- UI Helpers (Design Mehfooz Hai) ---
  Widget _buildGenderDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      initialValue: _selectedGender,
      items: [
        "Male",
        "Female",
      ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      onChanged: (val) => setState(() => _selectedGender = val),
      decoration: _inputDecoration(
        "Choose Gender",
        Icons.person_outline,
        isDark,
      ),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        if (picked != null)
          setState(
            () => _dateController.text =
                "${picked.day}-${picked.month}-${picked.year}",
          );
      },
      decoration: _inputDecoration(
        "Date of Birth",
        Icons.calendar_month_outlined,
        isDark,
      ),
    );
  }

  // Widget _buildWeightField(bool isDark) {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: TextFormField(
  //           controller: _weightController,
  //           keyboardType: const TextInputType.numberWithOptions(decimal: true),
  //           style: TextStyle(color: isDark ? Colors.white : Colors.black),
  //           decoration: _inputDecoration(
  //             "Your Weight",
  //             Icons.monitor_weight_outlined,
  //             isDark,
  //           ),
  //         ),
  //       ),
  //       const SizedBox(width: 10),
  //       GestureDetector(
  //         onTap: _toggleWeightUnit,
  //         child: _buildUnitBox(_weightUnit),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildHeightField(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: _inputDecoration("Your Height", Icons.height, isDark),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _toggleHeightUnit,
          child: _buildUnitBox(_heightUnit),
        ),
      ],
    );
  }

  void _toggleWeightUnit() {
    setState(() {
      double? currentVal = double.tryParse(_weightController.text);
      if (_weightUnit == "KG") {
        _weightUnit = "LBS";
        if (currentVal != null)
          _weightController.text = (currentVal * 2.20462).toStringAsFixed(1);
      } else {
        _weightUnit = "KG";
        if (currentVal != null)
          _weightController.text = (currentVal / 2.20462).toStringAsFixed(1);
      }
    });
  }

  void _toggleHeightUnit() {
    setState(() {
      double? currentVal = double.tryParse(_heightController.text);
      if (_heightUnit == "CM") {
        _heightUnit = "FT";
        if (currentVal != null)
          _heightController.text = (currentVal / 30.48).toStringAsFixed(1);
      } else {
        _heightUnit = "CM";
        if (currentVal != null)
          _heightController.text = (currentVal * 30.48).toStringAsFixed(0);
      }
    });
  }

  // --- 1. Border Logic inside Decoration ---
  InputDecoration _inputDecoration(String hint, IconData icon, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFFC58BF2),
        size: 20,
      ), // Purple Icon
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFF7F8F8),

      // ✅ Professional Borders added
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
    );
  }

  // --- 2. Improved Weight Field with Validation ---
  Widget _buildWeightField(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autovalidateMode:
                AutovalidateMode.onUserInteraction, // 🔥 Real-time validation
            validator: (val) {
              if (val == null || val.isEmpty) return "Weight is required";
              if (double.tryParse(val) == null) return "Enter a valid number";
              return null;
            },
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: _inputDecoration(
              "Your Weight",
              Icons.monitor_weight_outlined,
              isDark,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _toggleWeightUnit,
          child: _buildUnitBox(_weightUnit),
        ),
      ],
    );
  }

  Widget _buildUnitBox(String unit) {
    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC58BF2), Color(0xFFEEA4CE)],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        unit,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
