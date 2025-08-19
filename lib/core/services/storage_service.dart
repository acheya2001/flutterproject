import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  // Upload file to Firebase Storage (STUB)
  Future<String> uploadFile(File file, String path) async {
    try {
      debugPrint('StorageService STUB: Uploading file ${file.path} to $path');
      // Simulate upload delay
      await Future.delayed(const Duration(milliseconds: 500));
      return 'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/${Uri.encodeComponent(path)}?alt=media';
    } catch (e) {
      debugPrint('StorageService (uploadFile) Error: $e');
      rethrow;
    }
  }

  // Upload bytes to Firebase Storage (STUB)
  Future<String> uploadBytes(List<int> bytes, String path) async {
    try {
      debugPrint('StorageService STUB: Uploading bytes to $path');
      // Simulate upload delay
      await Future.delayed(const Duration(milliseconds: 500));
      return 'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/${Uri.encodeComponent(path)}?alt=media';
    } catch (e) {
      debugPrint('StorageService (uploadBytes) Error: $e');
      rethrow;
    }
  }

  // SharedPreferences helpers
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      debugPrint('StorageService (getBool) Error: $e');
      return defaultValue;
    }
  }

  Future<bool> setBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('StorageService (setBool) Error: $e');
      return false;
    }
  }

  Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('StorageService (getString) Error: $e');
      return null;
    }
  }

  Future<bool> setString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(key, value);
    } catch (e) {
      debugPrint('StorageService (setString) Error: $e');
      return false;
    }
  }
}