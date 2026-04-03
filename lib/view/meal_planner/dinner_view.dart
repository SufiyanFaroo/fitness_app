import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/data/services/MealService.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/view/meal_planner/meal_details_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DinnerView extends StatefulWidget {
  const DinnerView({super.key});

  @override
  State<DinnerView> createState() => _DinnerViewState();
}

class _DinnerViewState extends State<DinnerView> {
  final TextEditingController _searchController = TextEditingController();
  final MealService _mealService = MealService();
  String selectedCategory = "Light"; // Default Category for Dinner

  // --- Keyboard Auto-Hide ---
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

  // --- 1. Search Bar (Dinner Style) ---
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
        onSubmitted: (val) => _trackActivity("Search: $val"),
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: "Search Light Dinner",
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.tune,
              color: Color(0xFFEEA4CE),
            ), // Pinkish Accent
            onPressed: () => _trackActivity("Filter Open"),
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
                "Light",
                "assets/images/salad.png",
                const Color(0xFFF2E6FF),
                isDark,
              ),
              _categoryItem(
                "Soup",
                "assets/images/Soup.png",
                const Color(0xFFD1FFEA),
                isDark,
              ),
              _categoryItem(
                "Kebab",
                "assets/images/Kebab.png",
                const Color(0xFFF2E6FF),
                isDark,
              ),
              _categoryItem(
                "Fish",
                "assets/images/Fish.png",
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
              ? const Color(0xFFEEA4CE).withValues(alpha: 0.2)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(15),
          border: isSelected
              ? Border.all(color: const Color(0xFFEEA4CE), width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              height: 40,
              errorBuilder: (c, e, s) => const Icon(Icons.nightlight_round),
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
          "Recommended for\nGood Sleep",
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
                "Vegetable Soup",
                "Very Light | 150kCal",
                "assets/images/Soup.png",
                const Color(0xFFD1FFEA),
                isDark,
                () => _handleMealClick(
                  "Vegetable Soup",
                  "assets/images/Soup.png",
                ),
              ),
              _dietCard(
                "Grilled Fish",
                "Omega-3 | 320kCal",
                "assets/images/Grilled-Fish.png",
                const Color(0xFFF2E6FF),
                isDark,
                () => _handleMealClick(
                  "Grilled Fish",
                  "assets/images/Grilled-Fish.png",
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
          "Popular Dinner",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        _popularItem(
          "Chicken Salad",
          "Low Carb | 20mins | 280kCal",
          "assets/images/chickensalad.png",
          isDark,
          () => _handleMealClick(
            "Chicken Salad",
            "assets/images/chickensalad.png",
          ),
        ),
        _popularItem(
          "Turkey Sandwich",
          "Protein | 10mins | 350kCal",
          "assets/images/Turkey-Sandwish.png",
          isDark,
          () => _handleMealClick(
            "Turkey Sandwich",
            "assets/images/Turkey-Sandwish.png",
          ),
        ),
      ],
    );
  }

  // --- Logics & Sync ---

  void _handleMealClick(String name, String img) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_dinner_viewed', name);

    await _mealService.updateNutritionGoals({
      "last_dinner_interaction": name,
      "dinner_timestamp": FieldValue.serverTimestamp(),
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

  void _trackActivity(String activity) async {
    await _mealService.updateNutritionGoals({"dinner_log": activity});
  }

  // --- UI Components ---

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
            colors: [Color(0xFFEEA4CE), Color(0xFFC58BF2)],
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
        "Dinner",
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
                  // 🔥 Dinner context ke sath share call
                  await _mealService.shareDietPlan("Dinner Diet Plan");
                } else if (value == 'Report') {
                  // 🔥 Workable Report Dialog
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

  // 1. --- Helper to show messages (SnackBar) ---
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF92A3FD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 2. --- Popup Item Helper (UI design) ---
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

  // 3. --- Report Dialog Logic (Firebase Integrated) ---
  void _showReportDialog(bool isDark) {
    final TextEditingController _reportController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Report Recipe",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _reportController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Reason for reporting...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              if (_reportController.text.isNotEmpty) {
                Navigator.pop(context);
                await FirebaseFirestore.instance.collection('reports').add({
                  'recipe': 'Dinner Plan',
                  'reason': _reportController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                _showSnackBar("Report submitted!");
              }
            },
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
