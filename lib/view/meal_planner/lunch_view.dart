import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/data/services/MealService.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/view/meal_planner/meal_details_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LunchView extends StatefulWidget {
  const LunchView({super.key});

  @override
  State<LunchView> createState() => _LunchViewState();
}

class _LunchViewState extends State<LunchView> {
  final TextEditingController _searchController = TextEditingController();
  final MealService _mealService = MealService();
  String selectedCategory = "Protein"; // Default Category for Lunch

  // --- Keyboard Auto-Hide Logic ---
  void _unfocusKeyboard() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;
    var media = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: _unfocusKeyboard,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
        appBar: _buildAppBar(isDark),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildSearchBar(isDark),
              const SizedBox(height: 30),
              _buildCategorySection(isDark),
              const SizedBox(height: 30),
              _buildRecommendationSection(media, isDark),
              const SizedBox(height: 30),
              _buildPopularSection(isDark),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Search Bar with Logic ---
  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (val) => _handleActionTracking("Search: $val"),
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: "Search Lunch Recipes",
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.tune,
              color: Color(0xFFC58BF2),
            ), // Purple for Lunch theme
            onPressed: () => _handleActionTracking("Filter Clicked"),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // --- 2. Category Section ---
  Widget _buildCategorySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Category",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _categoryItem(
                "Protein",
                "assets/images/Protein.png",
                const Color(0xFFF2E6FF),
                isDark,
              ),
              _categoryItem(
                "Rice",
                "assets/images/Rice.png",
                const Color(0xFFD1FFEA),
                isDark,
              ),
              _categoryItem(
                "Pasta",
                "assets/images/Pasta.png",
                const Color(0xFFF2E6FF),
                isDark,
              ),
              _categoryItem(
                "Salad",
                "assets/images/salad.png",
                const Color(0xFFD1FFEA),
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryItem(String name, String iconPath, Color color, bool isDark) {
    bool isSelected = selectedCategory == name;
    return InkWell(
      onTap: () => setState(() => selectedCategory = name),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFC58BF2).withValues(alpha: 0.2)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(15),
          border: isSelected
              ? Border.all(color: const Color(0xFFC58BF2), width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              height: 40,
              errorBuilder: (c, e, s) => const Icon(Icons.fastfood),
            ),
            const SizedBox(height: 5),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isDark ? Colors.white70 : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. Recommendation Section ---
  Widget _buildRecommendationSection(Size media, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Healthy Lunch\nRecommendations",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 250,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _dietCard(
                "Grilled Chicken",
                "High Protein | 450kCal",
                "assets/images/Grilled-chicken.png",
                const Color(0xFFD1FFEA),
                isDark,
                () => _handleMealTap(
                  "Grilled Chicken",
                  "assets/images/Grilled-chicken.png",
                ),
              ),
              _dietCard(
                "Beef Steak",
                "Rich Iron | 600kCal",
                "assets/images/Beef-steak.png",
                const Color(0xFFF2E6FF),
                isDark,
                () => _handleMealTap(
                  "Beef Steak",
                  "assets/images/Beef-steak.png",
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 4. Popular Section ---
  Widget _buildPopularSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Popular Lunch",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        _popularItem(
          "Chicken Biryani",
          "Spicy | 45mins | 750kCal",
          "assets/images/Chicken-biryani.png",
          isDark,
          () => _handleMealTap(
            "Chicken Biryani",
            "assets/images/Chicken-biryani.png",
          ),
        ),
        _popularItem(
          "Pasta Carbonara",
          "Creamy | 25mins | 540kCal",
          "assets/images/Pasta-carbonara.png",
          isDark,
          () => _handleMealTap(
            "Pasta Carbonara",
            "assets/images/Pasta-carbonara.png",
          ),
        ),
      ],
    );
  }

  // --- Helper Logics ---

  void _handleMealTap(String name, String img) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_lunch_viewed', name);

    await _mealService.updateNutritionGoals({
      "last_lunch_interaction": name,
      "lunch_timestamp": FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MealDetailsView(mealName: name, mealImage: img),
        ),
      );
    }
  }

  void _handleActionTracking(String action) async {
    await _mealService.updateNutritionGoals({"lunch_action": action});
    debugPrint("Lunch Activity: $action");
  }

  // --- Common UI Components ---

  Widget _dietCard(
    String title,
    String desc,
    String img,
    Color color,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : color.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            img,
            height: 100,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const Icon(Icons.restaurant, size: 50),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(desc, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 15),
          _viewButton(onTap),
        ],
      ),
    );
  }

  Widget _viewButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC58BF2), Color(0xFFEEA4CE)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "View",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _popularItem(
    String title,
    String desc,
    String img,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                img,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.fastfood),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF7F8F8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black,
              size: 15,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: Text(
        "Lunch", // Dinner View mein yahan "Dinner" likh dein
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF7F8F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz,
                color: isDark ? Colors.white : Colors.black,
              ),
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              onSelected: (value) async {
                if (value == 'Share') {
                  _showSnackBar("Opening Share Menu...");
                  await _mealService.shareDietPlan("Lunch Diet Plan");
                } else if (value == 'Report') {
                  // 🔥 Dialog open hoga reason puchne ke liye
                  _showReportDialog(isDark);
                }
              },
              itemBuilder: (context) => [
                _buildPopupItem(
                  "Share",
                  Icons.share_outlined,
                  const Color(0xFF92A3FD),
                ),
                _buildPopupItem(
                  "Report",
                  Icons.report_gmailerrorred,
                  Colors.orange,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  void _showReportDialog(bool isDark) {
    final TextEditingController _reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Report Recipe",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Please tell us why you are reporting this recipe.",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _reportController,
              maxLines: 3,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Reason for reporting...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF7F8F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (_reportController.text.trim().isNotEmpty) {
                String reason = _reportController.text.trim();
                Navigator.pop(context); // Dialog band karein

                try {
                  // 🔥 Firebase Firestore mein report save karein
                  await FirebaseFirestore.instance.collection('reports').add({
                    'recipe_name': "Lunch/Dinner View",
                    'reason': reason,
                    'timestamp': FieldValue.serverTimestamp(),
                    'status': 'pending',
                  });

                  _showSnackBar("Report submitted successfully!");
                } catch (e) {
                  _showSnackBar("Error: ${e.toString()}");
                }
              } else {
                _showSnackBar("Please enter a reason.");
              }
            },
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Popup Item Helper ---
  PopupMenuItem<String> _buildPopupItem(
    String title,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: title,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // --- Helper to show messages (SnackBar) ---
  void _showSnackBar(String message) {
    if (!mounted) return; // Safety check taake crash na ho
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating, // Premium floating look
        backgroundColor: const Color(
          0xFF92A3FD,
        ), // Aapki app ka primary blue color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
