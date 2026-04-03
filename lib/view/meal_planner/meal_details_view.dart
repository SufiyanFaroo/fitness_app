import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
// 🔥 Service aur Firebase Imports
import 'package:fitness_app/data/services/MealService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MealDetailsView extends StatefulWidget {
  final String mealName;
  final String mealImage;

  const MealDetailsView({
    super.key,
    required this.mealName,
    required this.mealImage,
  });

  @override
  State<MealDetailsView> createState() => _MealDetailsViewState();
}

class _MealDetailsViewState extends State<MealDetailsView> {
  final MealService _mealService = MealService(); // 🔥 Service Instance
  bool isFavorite = false;
  bool isReadMore = false;
  bool _isLoading = false; // 🔥 Button loading state

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // --- 1. Initial Data Load (Favorite Status) ---
  Future<void> _loadInitialData() async {
    // Local storage se status check karein
    bool favStatus = await _mealService.getNotifyStatus(
      "fav_${widget.mealName}",
    );
    if (mounted) {
      setState(() {
        isFavorite = favStatus;
      });
    }
  }

  // --- 2. Favorite Toggle Logic ---
  void _handleFavoriteToggle() async {
    bool newStatus = !isFavorite;
    setState(() => isFavorite = newStatus);

    // Service ke zariye save karein (Local + Firebase)
    await _mealService.saveNotifyStatus("fav_${widget.mealName}", newStatus);
  }

  // --- 3. Add to Schedule Logic ---
  Future<void> _handleAddToMeal() async {
    setState(() => _isLoading = true);

    // Meal data preparation
    Map<String, dynamic> mealData = {
      'mealName': widget.mealName,
      'image': widget.mealImage,
      'category': 'Breakfast',
      'timestamp': FieldValue.serverTimestamp(),
      'calories': '180kCal',
    };

    // Service call to save in Firebase
    await _mealService.updateNutritionGoals(mealData);

    setState(() => _isLoading = false);

    if (mounted) {
      _showSuccessDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
      body: Stack(
        children: [
          _buildHeader(media),
          _buildMainContent(media, isDark),
          _buildAppBarButtons(isDark),
          _buildBottomButton(media), // 🔥 Updated with loading
        ],
      ),
    );
  }

  // --- Bottom Button with Service Connection ---
  Widget _buildBottomButton(Size media) {
    return Positioned(
      bottom: 20,
      left: 30,
      right: 30,
      child: InkWell(
        onTap: _isLoading ? null : _handleAddToMeal,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 55,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF92A3FD).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Add to Breakfast Meal",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // --- Title Section with Favorite Sync ---
  Widget _buildTitleSection(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.mealName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const Text(
              "by Arash Ranjbaran",
              style: TextStyle(color: Color(0xFF1AD2A4), fontSize: 13),
            ),
          ],
        ),
        IconButton(
          onPressed: _handleFavoriteToggle, // 🔥 Service call
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: Colors.red,
            size: 28,
          ),
        ),
      ],
    );
  }

  // ... [Baqi sare UI widgets (_buildHeader, _buildMainContent, etc.) wahi rahenge jo aapne diye thay] ...
  Widget _buildHeader(Size media) {
    return Container(
      height: media.height * 0.50,
      width: media.width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEA4CE), Color(0xFFC150F6)],
        ),
      ),
      child: Center(
        child: Hero(
          tag: widget.mealName,
          child: Image.asset(
            widget.mealImage,
            height: media.height * 0.35,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // --- 2. Scrollable Body Content ---
  Widget _buildMainContent(Size media, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Header ke niche tak khali jagah taake content niche se shuru ho
          SizedBox(height: media.height * 0.42),

          Container(
            width: media.width,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1D1B20) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(35),
                topRight: Radius.circular(35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle icon at top
                Center(
                  child: Container(
                    width: 45,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                _buildTitleSection(isDark),
                const SizedBox(height: 25),
                _buildNutritionSection(isDark),
                const SizedBox(height: 25),
                _buildDescriptionSection(isDark),
                const SizedBox(height: 25),
                _buildIngredientsSection(isDark),
                const SizedBox(height: 25),
                _buildStepByStepSection(isDark),
                const SizedBox(height: 100), // Space for start button
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Fixed AppBar Buttons ---
  // --- 3. Fixed AppBar Buttons ---
  Widget _buildAppBarButtons(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button
            _actionButton(
              Icons.arrow_back_ios_new,
              () => Navigator.pop(context),
              isDark,
            ),

            // Three Dots with Professional Popup Logic
            _popupMenuButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _popupMenuButton(bool isDark) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_horiz,
          color: isDark ? Colors.white : Colors.black,
          size: 16,
        ),
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

        // 🔥 Real-Time Actions Connected with Service
        onSelected: (value) async {
          if (value.contains('Share')) {
            // Contains use kiya hai kyunki title change ho sakta hai
            _handleShare();
          } else if (value.contains('Favorite')) {
            _handleFavoriteToggle();
          } else if (value == 'Report') {
            _handleReport();
          }
        },

        itemBuilder: (context) => [
          _buildPopupItem(
            "Share",
            Icons.share_outlined,
            const Color(0xFF92A3FD),
          ),
          _buildPopupItem(
            isFavorite ? "Unfavorite" : "Favorite",
            isFavorite ? Icons.favorite : Icons.favorite_border,
            Colors.redAccent,
          ),
          _buildPopupItem("Report", Icons.report_gmailerrorred, Colors.orange),
        ],
      ),
    );
  }

  // --- 1. Share Logic ---
  void _handleShare() async {
    _showSnackBar("Opening share menu...");

    // 1. Firebase tracking (Done)
    await _mealService.shareDietPlan(widget.mealName);

    // 2. 🔥 Asli sharing trigger (Native Share Sheet)
    await Share.share(
      "Check out this delicious ${widget.mealName} recipe on FitQuest! 🥗",
    );

    debugPrint("Share triggered for ${widget.mealName}");
  }

  // --- 2. Report Logic ---
  void _handleReport() {
    // 🔥 Direct Firebase mein add karne ke bajaye Dialog open karein
    var themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    _showReportDetailsDialog(isDark);
  }

  // --- Helper to show messages (SnackBar) ---
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating, // Premium look ke liye
        backgroundColor: const Color(0xFF92A3FD), // Theme match karne ke liye
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- Helpers ---

  PopupMenuItem<String> _buildPopupItem(
    String title,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: title, // Title ko value banaya taake onSelected pe detect ho sake
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black,
          size: 16,
        ),
      ),
    );
  }

  // Naya Function: Success Confirmation Dialog
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF1AD2A4),
                  size: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Success!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Your Blueberry Pancake has been added to your breakfast schedule.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 25),
                InkWell(
                  onTap: () {
                    Navigator.pop(context); // 1. Dialog band karega
                    Navigator.pop(
                      context,
                    ); // 2. Meal Details screen se wapas Breakfast View par le jayega
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF92A3FD),
                          Color(0xFF9DCEFF),
                        ], // Premium Gradient
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Done",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNutritionSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nutrition",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _nutritionCard(
                "180kCal",
                Icons.local_fire_department,
                const Color(0xFFD1FFEA),
                isDark,
              ),
              _nutritionCard(
                "30g fats",
                Icons.egg_outlined,
                const Color(0xFFF2E6FF),
                isDark,
              ),
              _nutritionCard(
                "20g proteins",
                Icons.kebab_dining,
                const Color(0xFFD1FFEA),
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nutritionCard(String val, IconData icon, Color col, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : col.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            val,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // 1. Pehle apne State class mein ye variable define karein
  // bool isReadMore = false;

  Widget _buildDescriptionSection(bool isDark) {
    // Pura text jo aap dikhana chahte hain
    const String fullDescription =
        "Pancakes are some people's favorite breakfast, who doesn't like pancakes? Especially with the real honey splash on top of the pancakes, of course everyone loves that! Besides being delicious, it is also easy to make at home with basic ingredients.";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Descriptions",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black, // Theme based color
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              height: 1.5,
            ),
            children: [
              TextSpan(
                // Agar isReadMore true hai to pura text, warna sirf shuru ka hissa
                text: isReadMore
                    ? fullDescription
                    : "${fullDescription.substring(0, 85)}... ",
              ),
              WidgetSpan(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      isReadMore = !isReadMore; // Toggle state on click
                    });
                  },
                  child: Text(
                    isReadMore ? " Read Less" : "Read More...",
                    style: const TextStyle(
                      color: Color(
                        0xFF1AD2A4,
                      ), // image_6ded66.png ke mutabiq green color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection(bool isDark) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Ingredients That You Will Need",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text("6 items", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(), // Smooth scrolling ke liye
          child: Row(
            children: [
              _ingredientItem(
                "Wheat Flour",
                "100gr",
                "assets/images/flour.png",
                isDark,
              ),
              _ingredientItem(
                "Sugar",
                "3 tbsp",
                "assets/images/sugar.png",
                isDark,
              ),
              _ingredientItem(
                "Baking Soda",
                "2 tsp",
                "assets/images/soda.png",
                isDark,
              ),
              _ingredientItem(
                "Eggs",
                "2 items",
                "assets/images/Eggs.png", // Path check kar lein
                isDark,
              ),
              // --- Naye 2 Items Add kiye gaye hain ---
              _ingredientItem(
                "Honey",
                "2 tbsp",
                "assets/images/honey.png", // Pancake ke liye zaroori hai
                isDark,
              ),
              _ingredientItem(
                "Milk",
                "250ml",
                "assets/images/glassmilk.png", // Structure consistency ke liye
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ingredientItem(String name, String qty, String img, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF7F8F8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Image.asset(
              img,
              height: 45,
              width: 45,
              errorBuilder: (c, e, s) => const Icon(Icons.fastfood),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(qty, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStepByStepSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Step by Step",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const Text(
              "8 Steps",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Step 1
        _stepItem(
          "01",
          "Step 1",
          "Prepare all of the ingredients that needed",
          isDark,
          isLast: false,
        ),
        // Step 2
        _stepItem(
          "02",
          "Step 2",
          "Mix flour, sugar, salt, and baking powder",
          isDark,
          isLast: false,
        ),
        // Step 3
        _stepItem(
          "03",
          "Step 3",
          "In a seperate place, mix the eggs and liquid milk until blended",
          isDark,
          isLast: false,
        ),
        // Step 4 (Naya Add kiya)
        _stepItem(
          "04",
          "Step 4",
          "Pour the liquid mixture into the dry mixture slowly",
          isDark,
          isLast: false,
        ),
        // Step 5 (Naya Add kiya)
        _stepItem(
          "05",
          "Step 5",
          "Heat a non-stick pan and pour a ladle of batter",
          isDark,
          isLast: true, // Last step par line khatam ho jayegi
        ),
      ],
    );
  }

  Widget _stepItem(
    String no,
    String title,
    String desc,
    bool isDark, {
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                no,
                style: const TextStyle(color: Color(0xFFC58BF2), fontSize: 12),
              ),
              const SizedBox(height: 5),
              // Step Indicator Circle
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC58BF2), width: 1),
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC58BF2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              // Vertical Line logic (Last item par hide ho jayegi)
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      // Dotted line effect ke liye isay behtar kiya ja sakta hai
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18), // Alignment fix karne ke liye
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.4, // Line spacing behtar ki
                  ),
                ),
                const SizedBox(height: 25), // Step ke darmiyan gap
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDetailsDialog(bool isDark) {
    final TextEditingController _reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Report ${widget.mealName}",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Please provide a reason for reporting this recipe.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _reportController,
              maxLines: 3,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Enter reason here...",
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
                  final uid = FirebaseAuth.instance.currentUser?.uid;

                  // 🔥 Firebase Firestore Detailed Entry
                  await FirebaseFirestore.instance.collection('reports').add({
                    'meal_name': widget.mealName,
                    'reason': reason,
                    'reporter_id': uid ?? "anonymous",
                    'view_source': 'Meal_Details_View',
                    'timestamp': FieldValue.serverTimestamp(),
                    'status': 'pending',
                  });

                  _showSnackBar("Report submitted! We will review it.");
                } catch (e) {
                  _showSnackBar("Error submitting report: ${e.toString()}");
                }
              } else {
                _showSnackBar("Please provide a reason.");
              }
            },
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
