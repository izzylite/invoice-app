import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage customer name options persistence
class CustomerOptionsService {
  static const String _prefKey = 'customer_options';

  /// Save customer options to shared preferences
  static Future<bool> saveCustomerOptions(List<String> options) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(options);
      return await prefs.setString(_prefKey, jsonString);
    } catch (e) {
      print('Error saving customer options: $e');
      return false;
    }
  }

  /// Load customer options from shared preferences
  static Future<List<String>> getCustomerOptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_prefKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return List<String>.from(jsonList);
    } catch (e) {
      print('Error loading customer options: $e');
      return [];
    }
  }

  /// Add a new customer option
  static Future<bool> addCustomerOption(String option) async {
    try {
      final List<String> options = await getCustomerOptions();
      if (!options.contains(option)) {
        options.add(option);
        return await saveCustomerOptions(options);
      }
      return true; // Option already exists
    } catch (e) {
      print('Error adding customer option: $e');
      return false;
    }
  }

  /// Remove a customer option
  static Future<bool> removeCustomerOption(String option) async {
    try {
      final List<String> options = await getCustomerOptions();
      options.remove(option);
      return await saveCustomerOptions(options);
    } catch (e) {
      print('Error removing customer option: $e');
      return false;
    }
  }

  /// Clear all customer options
  static Future<bool> clearAllOptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_prefKey);
    } catch (e) {
      print('Error clearing customer options: $e');
      return false;
    }
  }
}
