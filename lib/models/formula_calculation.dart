enum OperationType {
  add,
  subtract,
  multiply,
  divide,
}

// Helper method to convert operation type to string
String operationTypeToString(OperationType type) {
  return type.toString().split('.').last;
}

// Helper method to convert string to operation type
OperationType operationTypeFromString(String value) {
  return OperationType.values.firstWhere(
    (type) => operationTypeToString(type) == value,
    orElse: () => OperationType.add,
  );
}

class FormulaComponent {
  final String columnName;
  final OperationType operation;

  FormulaComponent({
    required this.columnName,
    required this.operation,
  });

  @override
  String toString() {
    String operationSymbol;
    switch (operation) {
      case OperationType.add:
        operationSymbol = '+';
        break;
      case OperationType.subtract:
        operationSymbol = '-';
        break;
      case OperationType.multiply:
        operationSymbol = '×';
        break;
      case OperationType.divide:
        operationSymbol = '÷';
        break;
    }
    return '$operationSymbol $columnName';
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'columnName': columnName,
      'operation': operationTypeToString(operation),
    };
  }

  // Create from JSON
  factory FormulaComponent.fromJson(Map<String, dynamic> json) {
    return FormulaComponent(
      columnName: json['columnName'],
      operation: operationTypeFromString(json['operation']),
    );
  }
}

class Formula {
  final List<FormulaComponent> components;

  Formula({required this.components});

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'components': components.map((component) => component.toJson()).toList(),
    };
  }

  // Create from JSON
  factory Formula.fromJson(Map<String, dynamic> json) {
    final componentsList = (json['components'] as List)
        .map((item) => FormulaComponent.fromJson(item))
        .toList();

    return Formula(components: componentsList);
  }

  // Calculate the result based on the formula and provided values
  double calculate(Map<String, dynamic> values) {
    if (components.isEmpty) {
      return 0.0;
    }

    // Start with the first component's value
    double result = _getNumericValue(values[components.first.columnName]);

    // Apply operations for the rest of the components
    for (int i = 1; i < components.length; i++) {
      final component = components[i];
      final value = _getNumericValue(values[component.columnName]);

      switch (component.operation) {
        case OperationType.add:
          result += value;
          break;
        case OperationType.subtract:
          result -= value;
          break;
        case OperationType.multiply:
          result *= value;
          break;
        case OperationType.divide:
          // Avoid division by zero
          if (value != 0) {
            result /= value;
          }
          break;
      }
    }

    return result;
  }

  // Helper method to convert any value to a numeric value
  double _getNumericValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Get a string representation of the formula
  String getFormulaString() {
    if (components.isEmpty) {
      return 'No formula';
    }

    String result = components.first.columnName;
    for (int i = 1; i < components.length; i++) {
      result += ' ${components[i].toString()}';
    }
    return result;
  }
}
