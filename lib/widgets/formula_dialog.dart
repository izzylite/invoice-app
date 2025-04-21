import 'package:flutter/material.dart';
import '../models/formula_calculation.dart';

class FormulaDialog extends StatefulWidget {
  final Formula? initialFormula;
  final List<String> numericColumns;

  const FormulaDialog({
    super.key,
    this.initialFormula,
    required this.numericColumns,
  });

  @override
  State<FormulaDialog> createState() => _FormulaDialogState();
}

class _FormulaDialogState extends State<FormulaDialog> {
  late List<FormulaComponent> _components;

  @override
  void initState() {
    super.initState();
    _components = widget.initialFormula?.components ?? [];
  }

  // Helper method to get available columns for formula components
  List<String> _getAvailableColumns(List<String> allColumns,
      List<FormulaComponent> components, int currentIndex) {
    // If there's only one column available, we have to allow it for all components
    if (allColumns.length <= 1) {
      return allColumns;
    }

    // Get list of columns that are already used in other components
    final usedColumns = <String>{};
    for (int i = 0; i < components.length; i++) {
      if (i != currentIndex) {
        // Skip the current component
        usedColumns.add(components[i].columnName);
      }
    }

    // Filter out used columns
    return allColumns.where((column) => !usedColumns.contains(column)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Amount Formula'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formula is always enabled
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Amount will be calculated automatically using the formula below.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const Divider(),
            const Text(
              'Create Formula:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // Formula components
            for (int index = 0; index < _components.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    // First component doesn't need operation
                    if (index == 0)
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Column',
                            border: OutlineInputBorder(),
                          ),
                          value: _components[index].columnName,
                          items: _getAvailableColumns(
                                  widget.numericColumns, _components, index)
                              .map((column) => DropdownMenuItem(
                                    value: column,
                                    child: Text(column),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _components[index] = FormulaComponent(
                                  columnName: value,
                                  operation: _components[index].operation,
                                );
                              });
                            }
                          },
                        ),
                      )
                    else ...[
                      // Operation dropdown
                      SizedBox(
                        width: 60,
                        child: DropdownButtonFormField<OperationType>(
                          decoration: const InputDecoration(
                            labelText: 'Op',
                            border: OutlineInputBorder(),
                          ),
                          value: _components[index].operation,
                          items: OperationType.values
                              .map((op) => DropdownMenuItem(
                                    value: op,
                                    child: Text({
                                      OperationType.add: '+',
                                      OperationType.subtract: '-',
                                      OperationType.multiply: '×',
                                      OperationType.divide: '÷',
                                    }[op]!),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _components[index] = FormulaComponent(
                                  columnName: _components[index].columnName,
                                  operation: value,
                                );
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Column dropdown
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Column',
                            border: OutlineInputBorder(),
                          ),
                          value: _components[index].columnName,
                          items: _getAvailableColumns(
                                  widget.numericColumns, _components, index)
                              .map((column) => DropdownMenuItem(
                                    value: column,
                                    child: Text(column),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _components[index] = FormulaComponent(
                                  columnName: value,
                                  operation: _components[index].operation,
                                );
                              });
                            }
                          },
                        ),
                      ),
                    ],

                    // Remove button (except for first component)
                    if (index > 0)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _components.removeAt(index);
                          });
                        },
                      ),
                  ],
                ),
              ),

            // Add component button
            if (widget.numericColumns.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    // Get available columns for the new component
                    final availableColumns = _getAvailableColumns(
                        widget.numericColumns,
                        _components,
                        _components.length // Index of the new component
                        );

                    if (availableColumns.isNotEmpty) {
                      _components.add(FormulaComponent(
                        columnName: availableColumns.first,
                        operation: OperationType.add,
                      ));
                    } else {
                      // Show a message if no columns are available
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'All numeric columns are already used in the formula.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Component'),
              ),

            const SizedBox(height: 16),

            // Preview of the formula
            if (_components.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Formula Preview:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  Formula(components: _components).getFormulaString(),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            Formula? formula;
            // Always use formula if components exist
            if (_components.isNotEmpty) {
              formula = Formula(components: List.from(_components));
            }

            Navigator.pop(context, {
              'useFormula': true, // Always true
              'formula': formula,
            });
          },
          child: const Text('APPLY'),
        ),
      ],
    );
  }
}

// Helper function to show the formula dialog
Future<Map<String, dynamic>?> showFormulaDialog(
  BuildContext context, {
  bool initialUseFormula = true,
  Formula? initialFormula,
  required List<String> numericColumns,
}) async {
  if (numericColumns.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No numeric columns available for formula calculation.'),
        backgroundColor: Colors.red,
      ),
    );
    return null;
  }

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => FormulaDialog(
      initialFormula: initialFormula,
      numericColumns: numericColumns,
    ),
  );
}
