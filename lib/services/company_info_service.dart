import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Company info model
class CompanyInfo {
  final String name;
  final String subtitle;
  final String contactNumber;

  CompanyInfo({
    required this.name,
    required this.subtitle,
    required this.contactNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'subtitle': subtitle,
      'contactNumber': contactNumber,
    };
  }

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      name: json['name'] ?? '',
      subtitle: json['subtitle'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
    );
  }
}

class CompanyInfoService {
  static const String _prefKey = 'company_info';

  /// Save company info to shared preferences
  static Future<bool> saveCompanyInfo(CompanyInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(info.toJson());
      return await prefs.setString(_prefKey, jsonString);
    } catch (e) {
      print('Error saving company info: $e');
      return false;
    }
  }

  static Future<CompanyInfo?> getCompanyInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_prefKey);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return CompanyInfo.fromJson(jsonMap);
    } catch (e) {
      print('Error loading company info: $e');
      return null;
    }
  }

  static Future<bool> clearCompanyInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_prefKey);
    } catch (e) {
      print('Error clearing company info: $e');
      return false;
    }
  }
}
