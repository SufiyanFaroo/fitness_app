import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _galleryRemindersKey = 'gallery_reminders';
  static const String _hdPreviewKey = 'hd_preview';

  Future<bool> getGalleryReminders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_galleryRemindersKey) ?? true;
  }

  Future<bool> getHdPreview() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hdPreviewKey) ?? true;
  }

  Future<void> updateGalleryReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_galleryRemindersKey, value);
  }

  Future<void> updateHdPreview(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hdPreviewKey, value);
  }

  Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_galleryRemindersKey);
    await prefs.remove(_hdPreviewKey);
  }
}
