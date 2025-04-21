import 'package:flutter/material.dart';
import 'formula_calculation.dart';

enum FieldType { text, integer, decimal }

class ColumnDefinition {
  final String name;
  final FieldType fieldType;
  final Formula? formula;

  ColumnDefinition({
    required this.name,
    required this.fieldType,
    this.formula,
  });

  // Helper method to get keyboard type based on field type
  TextInputType get keyboardType {
    switch (fieldType) {
      case FieldType.integer:
      case FieldType.decimal:
        return TextInputType.number;
      case FieldType.text:
        return TextInputType.text;
    }
  }

  // Helper method to validate input based on field type
  String? validateInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter $name';
    }

    switch (fieldType) {
      case FieldType.integer:
        if (int.tryParse(value) == null) {
          return 'Please enter a valid integer';
        }
        break;
      case FieldType.decimal:
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        break;
      case FieldType.text:
        // No additional validation for text
        break;
    }

    return null;
  }

  // Helper method to format value based on field type
  String formatValue(String value) {
    switch (fieldType) {
      case FieldType.integer:
        final intValue = int.tryParse(value);
        return intValue?.toString() ?? value;
      case FieldType.decimal:
        final doubleValue = double.tryParse(value);
        return doubleValue?.toStringAsFixed(2) ?? value;
      case FieldType.text:
        return value;
    }
  }

  // Helper method to convert string to appropriate type
  dynamic parseValue(String value) {
    switch (fieldType) {
      case FieldType.integer:
        return int.tryParse(value) ?? 0;
      case FieldType.decimal:
        return double.tryParse(value) ?? 0.0;
      case FieldType.text:
        return value;
    }
  }

  // Create a copy with updated properties
  ColumnDefinition copyWith({
    String? name,
    FieldType? fieldType,
    bool? useFormula,
    Formula? formula,
  }) {
    return ColumnDefinition(
      name: name ?? this.name,
      fieldType: fieldType ?? this.fieldType,
      formula: formula ?? this.formula,
    );
  }
}
