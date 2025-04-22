import 'package:flutter/material.dart';
import '../models/column_definition.dart';
import '../services/column_options_service.dart';

/// Shows a dialog to create or edit options for a column
Future<List<String>?> showOptionsDialog(
  BuildContext context, {
  required ColumnDefinition column,
  required List<String> initialOptions,
}) async {
  // First, try to load saved options for this column
  List<String> savedOptions =
      await ColumnOptionsService.getOptionsForColumn(column.name);

  // If we have saved options and no initial options were provided, use the saved ones
  final List<String> options = savedOptions.isNotEmpty && initialOptions.isEmpty
      ? List.from(savedOptions)
      : List.from(initialOptions);

  final TextEditingController optionController = TextEditingController();

  return showDialog<List<String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Row(
            children: [
              Icon(
                Icons.list_alt,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text('Options for ${column.name}'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add options that will appear as dropdown choices when entering data.\n${_getOptionTypeHint(column.fieldType)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: optionController,
                        decoration: const InputDecoration(
                          labelText: 'Option',
                          hintText: 'Enter option value',
                          border: OutlineInputBorder(),
                        ),
                        // Set keyboard type based on column type
                        keyboardType: column.fieldType == FieldType.text
                            ? TextInputType.text
                            : TextInputType.number,
                        onSubmitted: (_) {
                          _addOption(context, options, setState, column,
                              optionController);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () => _addOption(
                          context, options, setState, column, optionController),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Current Options:'),
                const SizedBox(height: 8),
                if (options.isEmpty)
                  const Text(
                    'No options added yet',
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                  )
                else
                  Container(
                    constraints: BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(options[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                options.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Save options to shared preferences
                await ColumnOptionsService.updateColumnOptions(
                    column.name, options);

                // Show a snackbar to confirm options were saved
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Options for ${column.name} saved')),
                  );

                  // Return the options to the caller
                  Navigator.pop(context, options);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}

// Helper method to add an option to the list
void _addOption(BuildContext context, List<String> options, Function setState,
    ColumnDefinition column, TextEditingController optionController) {
  final option = optionController.text.trim();
  if (option.isEmpty) return;

  // Validate option based on column type
  String? validationError;
  switch (column.fieldType) {
    case FieldType.integer:
      if (int.tryParse(option) == null) {
        validationError = 'Option must be a valid integer';
      }
      break;
    case FieldType.decimal:
      if (double.tryParse(option) == null) {
        validationError = 'Option must be a valid number';
      }
      break;
    case FieldType.text:
      // No validation needed for text
      break;
  }

  if (validationError != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(validationError)),
    );
    return;
  }

  if (!options.contains(option)) {
    setState(() {
      options.add(option);
    });
    optionController.clear();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Option already exists')),
    );
  }
}

// Helper method to get hint text for option type
String _getOptionTypeHint(FieldType type) {
  switch (type) {
    case FieldType.text:
      return 'You can add any text options.';
    case FieldType.integer:
      return 'Options must be whole numbers (e.g., 1, 2, 3).';
    case FieldType.decimal:
      return 'Options must be numbers (e.g., 1.5, 2.75).';
  }
}
