import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage column options persistence
class ColumnOptionsService {
  static const String _prefKey = 'column_options';

  /// Save column options to shared preferences
  static Future<bool> saveColumnOptions(Map<String, List<String>> columnOptions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert the map to a JSON-compatible format
      final Map<String, dynamic> jsonMap = {};
      columnOptions.forEach((key, value) {
        jsonMap[key] = value;
      });
      
      final String jsonString = jsonEncode(jsonMap);
      return await prefs.setString(_prefKey, jsonString);
    } catch (e) {
      print('Error saving column options: $e');
      return false;
    }
  }

  /// Load column options from shared preferences
  static Future<Map<String, List<String>>> getColumnOptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_prefKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }
      
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      final Map<String, List<String>> columnOptions = {};
      
      jsonMap.forEach((key, value) {
        if (value is List) {
          columnOptions[key] = List<String>.from(value);
        }
      });
      
      return columnOptions;
    } catch (e) {
      print('Error loading column options: $e');
      return {};
    }
  }

  /// Add or update options for a specific column
  static Future<bool> updateColumnOptions(String columnName, List<String> options) async {
    try {
      final Map<String, List<String>> allOptions = await getColumnOptions();
      allOptions[columnName] = options;
      return await saveColumnOptions(allOptions);
    } catch (e) {
      print('Error updating column options: $e');
      return false;
    }
  }

  /// Get options for a specific column
  static Future<List<String>> getOptionsForColumn(String columnName) async {
    try {
      final Map<String, List<String>> allOptions = await getColumnOptions();
      return allOptions[columnName] ?? [];
    } catch (e) {
      print('Error getting options for column: $e');
      return [];
    }
  }

  /// Clear all saved column options
  static Future<bool> clearAllOptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_prefKey);
    } catch (e) {
      print('Error clearing column options: $e');
      return false;
    }
  }
}
