import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

class LocalStorageService {
  // Get the local app directory where we'll store photos
  static Future<Directory> get _localDir async {
    final directory = await getApplicationDocumentsDirectory();
    final progressDir = Directory('${directory.path}/progress_photos');

    // Create directory if it doesn't exist
    if (!await progressDir.exists()) {
      await progressDir.create(recursive: true);
    }

    return progressDir;
  }

  // --- 1. Save Image Locally ---
  static Future<String?> saveProgressPhotoLocally(File imageFile) async {
    try {
      final dir = await _localDir;
      String fileName = "progress_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final File localFile = File('${dir.path}/$fileName');

      // Copy image to local storage
      await imageFile.copy(localFile.path);

      debugPrint("✅ Image saved locally: ${localFile.path}");
      return localFile.path;
    } catch (e) {
      debugPrint("❌ Local Save Error: $e");
      return null;
    }
  }

  // --- 2. Get All Local Progress Photos ---
  static Future<List<File>> getLocalProgressPhotos() async {
    try {
      final dir = await _localDir;

      if (!await dir.exists()) {
        return [];
      }

      final List<FileSystemEntity> files = dir.listSync();
      List<File> jpgFiles = files
          .where((file) => file.path.endsWith('.jpg'))
          .map((file) => File(file.path))
          .toList();

      // Sort by date (newest first)
      jpgFiles.sort((a, b) {
        return b.statSync().modified.compareTo(a.statSync().modified);
      });

      return jpgFiles;
    } catch (e) {
      debugPrint("❌ Error fetching local photos: $e");
      return [];
    }
  }

  // --- 3. Delete Image Locally ---
  static Future<bool> deleteLocalImage(String filePath) async {
    try {
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        debugPrint("✅ Image deleted locally: $filePath");
        return true;
      } else {
        debugPrint("⚠️ File not found for deletion: $filePath");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Local Delete Error: $e");
      return false;
    }
  }

  // --- 4. Get Local Image as File ---
  static Future<File?> getLocalImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error getting local image: $e");
      return null;
    }
  }

  // --- 5. Clear All Local Progress Photos ---
  static Future<bool> clearAllLocalPhotos() async {
    try {
      final dir = await _localDir;

      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
        debugPrint("✅ All local photos cleared");
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Error clearing local photos: $e");
      return false;
    }
  }

  // --- 6. Get Total Size of Local Photos (in MB) ---
  static Future<double> getLocalPhotosSizeInMB() async {
    try {
      final dir = await _localDir;
      int totalBytes = 0;

      if (await dir.exists()) {
        final List<FileSystemEntity> files = dir.listSync();
        for (var file in files) {
          if (file is File) {
            totalBytes += await file.length();
          }
        }
      }

      double sizeInMB = totalBytes / (1024 * 1024);
      return double.parse(sizeInMB.toStringAsFixed(2));
    } catch (e) {
      debugPrint("❌ Error calculating storage size: $e");
      return 0.0;
    }
  }

  // --- 7. Get Local Photo Count ---
  static Future<int> getLocalPhotoCount() async {
    try {
      final photos = await getLocalProgressPhotos();
      return photos.length;
    } catch (e) {
      debugPrint("❌ Error getting photo count: $e");
      return 0;
    }
  }
}
