import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/data/services/MealService.dart'; // 🔥 Service import ki
import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/view/meal_planner/meal_details_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BreakfastView extends StatefulWidget {
  const BreakfastView({super.key});

  @override
  State<BreakfastView> createState() => _BreakfastViewState();
}

bool isVegetarianOnly = false; // Switch ki halat yaad rakhne ke liye
String currentSort = "default"; // Sorting preference ke liye

class _BreakfastViewState extends State<BreakfastView> {
  final TextEditingController _searchController = TextEditingController();
  final MealService _mealService = MealService(); // 🔥 Service Instance
  String selectedCategory = "Salad"; // Default filtering category

  @override
  void initState() {
    super.initState();
    // Local data ya preferences load karne ke liye yahan call kar sakte hain
  }

  // 🔥 Real-time Search/Filter Logic
  void _handleSearch(String query) {
    debugPrint("Searching Firebase for: $query");
    // Service ke zariye search query Firebase par track kar sakte hain
    _mealService.updateNutritionGoals({"last_search": query});
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;
    var media = MediaQuery.of(context).size;

    return GestureDetector(
      // 🔥 Isse poori screen par click detect hoga
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus(); // Keyboard band karne ki logic
        }
      },
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
        onChanged: _handleSearch,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: "Search Pancake",
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF1AD2A4)),
            onPressed: () {
              // 🔥 Yahan "Search Filter" ya koi bhi naam pass kar den
              _mealService.shareDietPlan("Search Filter Activity");
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // --- 2. Category Section with Real-time Filtering ---
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
            physics: const BouncingScrollPhysics(),
            children: [
              _categoryItem(
                "Salad",
                "assets/images/salad.png",
                const Color(0xFFD1FFEA),
                isDark,
              ),
              _categoryItem(
                "Cake",
                "assets/images/cake.png",
                const Color(0xFFF2E6FF),
                isDark,
              ),
              _categoryItem(
                "Pie",
                "assets/images/pie.png",
                const Color(0xFFD1FFEA),
                isDark,
              ),
              _categoryItem(
                "Smoothie",
                "assets/images/orange.png",
                const Color(0xFFF2E6FF),
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🔥 Professional Category Item with Service Integration
  Widget _categoryItem(String name, String iconPath, Color color, bool isDark) {
    bool isSelected = selectedCategory == name;

    return InkWell(
      onTap: () async {
        if (selectedCategory == name)
          return; // Agar pehle se select hai toh kuch na karein

        setState(() {
          selectedCategory = name;
        });

        // 1. 🔥 Local Storage mein preference save karein
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_selected_category', name);

        // 2. 🔥 Firebase par user interest track karein
        await _mealService.updateNutritionGoals({
          "interested_category": name,
          "last_category_click": FieldValue.serverTimestamp(),
        });

        debugPrint("Category synced: $name");
      },
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        // 🔥 Smooth transition ke liye
        duration: const Duration(milliseconds: 200),
        width: 80,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF92A3FD).withValues(alpha: 0.2)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(15),
          border: isSelected
              ? Border.all(color: const Color(0xFF92A3FD), width: 1.5)
              : null,
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: const Color(0xFF92A3FD).withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              height: 40,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.fastfood, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF92A3FD))
                    : (isDark ? Colors.white70 : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. Recommendation Section (Dynamic Data Ready) ---
  Widget _buildRecommendationSection(Size media, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recommendation\nfor Diet",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 250,
          child: StreamBuilder<DocumentSnapshot>(
            // 🔥 Real-time connection with Firebase
            stream: _mealService.getNutritionData(),
            builder: (context, snapshot) {
              return ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _dietCard(
                    "Honey Pancake",
                    "Easy | 30mins | 180kCal",
                    "assets/images/honey-pancake.png",
                    const Color(0xFFD1FFEA),
                    isDark,
                    () => _handleRecommendationTap(
                      "Honey Pancake",
                      "assets/images/honey-pancake.png",
                    ),
                  ),
                  _dietCard(
                    "Canai Bread",
                    "Easy | 20mins | 230kCal",
                    "assets/images/canaibread.png",
                    const Color(0xFFF2E6FF),
                    isDark,
                    () => _handleRecommendationTap(
                      "Canai Bread",
                      "assets/images/canaibread.png",
                    ),
                  ),
                  _dietCard(
                    "Oatmeal Bowl",
                    "Medium | 15mins | 350kCal",
                    "assets/images/oatmeal.png",
                    const Color(0xFFE6EFFF),
                    isDark,
                    () => _handleRecommendationTap(
                      "Oatmeal Bowl",
                      "assets/images/oatmeal.png",
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // 🔥 Firebase aur Local Storage ko handle karne wala naya function
  void _handleRecommendationTap(String name, String image) async {
    // 1. Local Storage (SharedPreferences) mein last viewed save karein
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_viewed_recommendation', name);

    // 2. Firebase tracking (MealService use karte hue)
    await _mealService.updateNutritionGoals({
      "last_viewed_meal": name,
      "viewed_at": FieldValue.serverTimestamp(),
    });

    // 3. Navigation to details
    if (mounted) {
      _navigateToDetails(name, image);
    }
  }

  // --- 4. Popular Section with Interaction ---
  Widget _buildPopularSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Popular",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 15),

        // 1. Blueberry Pancake
        _popularItem(
          "Blueberry Pancake",
          "Medium | 30mins | 230kCal",
          "assets/images/blueberry.png",
          isDark,
          () => _handlePopularTap(
            "Blueberry Pancake",
            "assets/images/blueberry.png",
          ),
        ),

        // 2. Salmon Nigiri
        _popularItem(
          "Salmon Nigiri",
          "Medium | 20mins | 120kCal",
          "assets/images/salmon.png",
          isDark,
          () => _handlePopularTap("Salmon Nigiri", "assets/images/salmon.png"),
        ),

        // 3. Boiled Eggs & Salad
        _popularItem(
          "Boiled Eggs & Salad",
          "Easy | 10mins | 280kCal",
          "assets/images/egg&avocado.png",
          isDark,
          () => _handlePopularTap(
            "Boiled Eggs & Salad",
            "assets/images/egg&avocado.png",
          ),
        ),

        // 4. Berry Smoothie
        _popularItem(
          "Berry Smoothie",
          "Easy | 5mins | 150kCal",
          "assets/images/chickensalad.png",
          isDark,
          () => _handlePopularTap(
            "Berry Smoothie",
            "assets/images/chickensalad.png",
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // 🔥 Functional logic for Popular Items (Firebase + Navigation)
  void _handlePopularTap(String name, String image) async {
    // 1. Local Storage update (Last interacted item)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_popular_clicked', name);

    // 2. Firebase Tracking (Using MealService)
    // Isse track hoga ke konsi meal 'Popular' list se click hui
    await _mealService.updateNutritionGoals({
      "popular_interaction": name,
      "interaction_type": "list_click",
      "timestamp": FieldValue.serverTimestamp(),
    });

    // 3. Smooth Navigation
    if (mounted) {
      _navigateToDetails(name, image);
    }
  }

  // --- Helpers ---
  void _navigateToDetails(String name, String image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealDetailsView(mealName: name, mealImage: image),
      ),
    );
  }

  Widget _dietCard(
    String title,
    String desc,
    String img,
    Color color,
    bool isDark,
    VoidCallback onViewTap,
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
            errorBuilder: (c, e, s) =>
                const Icon(Icons.restaurant, size: 50, color: Colors.grey),
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
          InkWell(
            onTap: onViewTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF92A3FD).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
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
          ),
        ],
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
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
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
                errorBuilder: (c, e, s) => Container(
                  width: 60,
                  height: 60,
                  color: const Color(0xFF92A3FD).withValues(alpha: 0.1),
                  child: const Icon(Icons.fastfood, color: Color(0xFF92A3FD)),
                ),
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
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Icon(
                Icons.chevron_right,
                color: isDark ? const Color(0xFFC58BF2) : Colors.grey.shade400,
                size: 20,
              ),
            ),
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
        "Breakfast",
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

              // 🔥 Professional Actions
              onSelected: (val) {
                if (val == "Filter") {
                  _showFilterBottomSheet(isDark);
                } else if (val == "Sort") {
                  // 🔥 Yeh rahi sahi call!
                  _handleSortLogic();
                }
              },

              itemBuilder: (context) => [
                _buildPopupItem("Filter", Icons.tune, const Color(0xFF1AD2A4)),
                _buildPopupItem("Sort", Icons.sort, const Color(0xFF92A3FD)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  // --- Helper Functions for Backend Integration ---

  // 1. Sort Logic (Firebase Activity Tracking + UI Refresh)
  void _handleSortLogic() async {
    _showSnackBar("Sorting by lowest Calories...");

    // 🔥 Firebase Sync
    await _mealService.updateNutritionGoals({
      "last_sort_preference": "calories_asc",
    });

    setState(() {
      currentSort = "low_calories";
      // Yahan aap apni list ko sort kar sakte hain:
      // mealsList.sort((a, b) => a.calories.compareTo(b.calories));
    });

    debugPrint("List sorted by Calories");
  }

  void _showSnackBar(String message) {
    if (!mounted) return; // Safety check
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF92A3FD),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 2. Filter Bottom Sheet (Professional UI)
  void _showFilterBottomSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        // 🔥 StatefulBuilder zaroori hai taake switch move kare
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Filter Recipes",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: const Text("Only Vegetarian"),
                    trailing: Switch(
                      value: isVegetarianOnly,
                      activeColor: AppColors.primaryActive,
                      onChanged: (bool value) {
                        setSheetState(() {
                          isVegetarianOnly = value; // BottomSheet ka UI update
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF92A3FD),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () async {
                      // 🔥 Apply Button Logic
                      await _mealService.saveNotifyStatus(
                        "veg_filter",
                        isVegetarianOnly,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        _showSnackBar(
                          isVegetarianOnly
                              ? "Vegetarian Filter Applied"
                              : "Filter Removed",
                        );
                        setState(() {}); // Main Screen refresh
                      }
                    },
                    child: const Text(
                      "Apply Filter",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 3. Popup Item Helper (Clean Code)
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
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
