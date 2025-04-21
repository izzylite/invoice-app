import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/formula_calculation.dart';

class PreferencesService {
  static const String _formulaKey = 'default_formula';

  // Save the formula to preferences
  static Future<bool> saveDefaultFormula(Formula formula) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final formulaJson = jsonEncode(formula.toJson());
      return await prefs.setString(_formulaKey, formulaJson);
    } catch (e) {
      print('Error saving formula: $e');
      return false;
    }
  }

  // Get the formula from preferences
  static Future<Formula?> getDefaultFormula() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final formulaJson = prefs.getString(_formulaKey);
      
      if (formulaJson == null) {
        return null;
      }
      
      final Map<String, dynamic> json = jsonDecode(formulaJson);
      return Formula.fromJson(json);
    } catch (e) {
      print('Error getting formula: $e');
      return null;
    }
  }
}
