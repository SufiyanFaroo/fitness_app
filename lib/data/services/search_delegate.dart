import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/view/workout_tracker/exercise_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FitQuestSearchDelegate extends SearchDelegate {
  // 1. ELITE UI THEME
  @override
  ThemeData appBarTheme(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? const Color(0xFF1D1B20)
            : const Color(0xFF92A3FD),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 16,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.white,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _searchFirebase(query);

  @override
  Widget buildSuggestions(BuildContext context) {
    // ⬇️ Keyboard Dismiss on side click
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: query.trim().isEmpty
          ? _buildRecentSearches()
          : _searchFirebase(query),
    );
  }

  // 2. 🔥 REAL-TIME FIREBASE SEARCH
  Widget _searchFirebase(String searchText) {
    if (searchText.length < 2) {
      return _buildMessageUI(
        Icons.manage_search,
        "Type at least 2 characters...",
      );
    }

    // Capitalize first letter to match Firestore data naming conventions
    String formattedQuery =
        searchText[0].toUpperCase() + searchText.substring(1);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workouts')
          .where('name', isGreaterThanOrEqualTo: formattedQuery)
          .where('name', isLessThanOrEqualTo: '$formattedQuery\uf8ff')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return _buildMessageUI(
            Icons.error_outline,
            "Index Required. Check Console.",
          );
        if (snapshot.connectionState == ConnectionState.waiting)
          return _buildShimmerEffect();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return _buildMessageUI(Icons.search_off, "No workouts found.");

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            data['id'] = docs[index].id;
            return _buildResultTile(context, data);
          },
        );
      },
    );
  }

  // 3. PREMIUM RESULT TILE
  Widget _buildResultTile(BuildContext context, Map<String, dynamic> data) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 50,
            width: 50,
            color: const Color(0xFF92A3FD).withValues(alpha: 0.1),
            child: data['image'] != null
                ? Image.network(data['image'], fit: BoxFit.cover)
                : const Icon(Icons.fitness_center, color: Color(0xFF92A3FD)),
          ),
        ),
        title: Text(
          data['name'] ?? "Workout",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${data['calories'] ?? 0} kcal | ${data['time'] ?? 0} mins",
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () => _handleNavigation(context, data),
      ),
    );
  }

  // 4. SMART HISTORY MANAGEMENT
  Widget _buildRecentSearches() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        List<String> history =
            snapshot.data!.getStringList('recent_searches') ?? [];
        if (history.isEmpty)
          return _buildMessageUI(Icons.history, "No search history");

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "RECENT SEARCHES",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearAllHistory,
                    child: const Text(
                      "Clear All",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  return ListTile(
                    leading: const Icon(Icons.history, size: 20),
                    title: Text(item),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => _deleteSingleHistory(item),
                    ),
                    onTap: () => query = item,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // 5. NAVIGATION & UTILS
  void _handleNavigation(BuildContext context, Map<String, dynamic> data) {
    HapticFeedback.lightImpact();
    _saveSearchToLocal(data['name'] ?? "");
    FocusScope.of(context).unfocus();

    // Ensure steps are parsed correctly
    final List<Map<String, String>> formattedSteps =
        (data['steps'] as List? ?? [])
            .map((e) => Map<String, String>.from(e as Map))
            .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailView(
          exercise: Exercise(
            title: data['name'] ?? "Workout",
            calories: "${data['calories'] ?? 0} kcal",
            level: data['level'] ?? "Beginner",
            description: data['description'] ?? "No description available.",
            videoPath: data['video'] ?? "assets/videos/default.mp4",
            steps: formattedSteps,
          ),
        ),
      ),
    );
  }

  // UI HELPERS
  Widget _buildShimmerEffect() =>
      const Center(child: CircularProgressIndicator(color: Color(0xFF92A3FD)));

  Widget _buildMessageUI(IconData icon, String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 60, color: Colors.grey[300]),
        const SizedBox(height: 10),
        Text(msg, style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );

  // HISTORY FUNCTIONS
  Future<void> _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    query = query; // Refresh
  }

  Future<void> _deleteSingleHistory(String val) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('recent_searches') ?? [];
    history.remove(val);
    await prefs.setStringList('recent_searches', history);
    query = query; // Refresh
  }

  Future<void> _saveSearchToLocal(String val) async {
    if (val.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('recent_searches') ?? [];
    if (!history.contains(val)) {
      history.insert(0, val);
      if (history.length > 5) history.removeLast();
      await prefs.setStringList('recent_searches', history);
    }
  }
}
