import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class StorageService {
  // Instance methods for file uploads (if needed by other parts of your app)
  Future<String> uploadFile(String path, File file) async {
    debugPrint('StorageService STUB: Uploading file ${file.path} to $path');
    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/${Uri.encodeComponent(path)}?alt=media';
  }

  Future<String> uploadBytes(String path, Uint8List bytes) async {
    debugPrint('StorageService STUB: Uploading bytes to $path');
    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/${Uri.encodeComponent(path)}?alt=media';
  }

  // Static method to get a boolean value from shared preferences
  static Future<bool?> getBool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key);
    } catch (e) {
      debugPrint('StorageService (getBool) Error: $e');
      return null; // Return null or a default value like false in case of error
    }
  }

  // Static method to set a boolean value in shared preferences
  static Future<bool> setBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('StorageService (setBool) Error: $e');
      return false; // Indicate failure
    }
  }
}
