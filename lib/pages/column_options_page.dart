import 'package:flutter/material.dart';
import '../models/column_definition.dart';
import '../services/column_options_service.dart';

class ColumnOptionsPage extends StatefulWidget {
  final ColumnDefinition column;
  final List<String> initialOptions;

  const ColumnOptionsPage({
    super.key,
    required this.column,
    required this.initialOptions,
  });

  @override
  State<ColumnOptionsPage> createState() => _ColumnOptionsPageState();
}

class _ColumnOptionsPageState extends State<ColumnOptionsPage> {
  late List<String> _options;
  final TextEditingController _optionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isEditing = false;
  int _editingIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    // First, try to load saved options for this column
    List<String> savedOptions =
        await ColumnOptionsService.getOptionsForColumn(widget.column.name);

    // If we have saved options and no initial options were provided, use the saved ones
    setState(() {
      _options = savedOptions.isNotEmpty && widget.initialOptions.isEmpty
          ? List.from(savedOptions)
          : List.from(widget.initialOptions);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _optionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Helper method to add an option to the list
  void _addOption() {
    final option = _optionController.text.trim();
    if (option.isEmpty) return;

    // Validate option based on column type
    String? validationError;
    switch (widget.column.fieldType) {
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

    if (!_options.contains(option)) {
      setState(() {
        if (_isEditing &&
            _editingIndex >= 0 &&
            _editingIndex < _options.length) {
          // Replace the option at the editing index
          _options[_editingIndex] = option;
          _isEditing = false;
          _editingIndex = -1;
        } else {
          // Add a new option
          _options.add(option);
        }
      });
      _optionController.clear();

      // Scroll to the bottom to show the newly added option
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Option already exists')),
      );
    }
  }

  // Helper method to get hint text for option type
  String _getOptionTypeHint() {
    switch (widget.column.fieldType) {
      case FieldType.text:
        return 'You can add any text options.';
      case FieldType.integer:
        return 'Options must be whole numbers (e.g., 1, 2, 3).';
      case FieldType.decimal:
        return 'Options must be numbers (e.g., 1.5, 2.75).';
    }
  }

  Future<void> _saveOptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save options to shared preferences
      await ColumnOptionsService.updateColumnOptions(
          widget.column.name, _options);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Options for ${widget.column.name} saved')),
        );

        // Return the options to the caller
        Navigator.pop(context, _options);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving options: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _editOption(int index) {
    if (index >= 0 && index < _options.length) {
      setState(() {
        _optionController.text = _options[index];
        _isEditing = true;
        _editingIndex = index;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _optionController.clear();
      _isEditing = false;
      _editingIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Options for ${widget.column.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save options',
            onPressed: _saveOptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.3),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Column Type: ${_getFieldTypeLabel(widget.column.fieldType)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getOptionTypeHint(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Add option input field
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _optionController,
                          decoration: InputDecoration(
                            labelText:
                                _isEditing ? 'Edit Option' : 'Add Option',
                            hintText: 'Enter option value',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.add_circle_outline),
                            suffixIcon: _isEditing
                                ? IconButton(
                                    icon: const Icon(Icons.cancel),
                                    onPressed: _cancelEditing,
                                    tooltip: 'Cancel editing',
                                  )
                                : null,
                          ),
                          keyboardType:
                              widget.column.fieldType == FieldType.text
                                  ? TextInputType.text
                                  : TextInputType.number,
                          onSubmitted: (_) => _addOption(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addOption,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        child: Text(_isEditing ? 'Update' : 'Add'),
                      ),
                    ],
                  ),
                ),

                // Options list header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_options.length} items',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1),
                // Options list
                Expanded(
                  child: _options.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.list_alt,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No options added yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Add options above to create dropdown choices',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          itemCount: _options.length,
                          itemBuilder: (context, index) {
                            final isBeingEdited =
                                _isEditing && _editingIndex == index;
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                title: Text(
                                  _options[index],
                                  style: TextStyle(
                                    fontWeight: isBeingEdited
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isBeingEdited
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  foregroundColor: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  radius: 16,
                                  child: Text('${index + 1}'),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: isBeingEdited
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.blue,
                                      ),
                                      tooltip: 'Edit option',
                                      onPressed: () => _editOption(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      tooltip: 'Remove option',
                                      onPressed: () {
                                        setState(() {
                                          _options.removeAt(index);
                                          if (_isEditing &&
                                              _editingIndex == index) {
                                            _cancelEditing();
                                          } else if (_isEditing &&
                                              _editingIndex > index) {
                                            _editingIndex--;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: _isLoading
          ? null
          : BottomAppBar(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_options.length} options',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: _saveOptions,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('Save Options'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getFieldTypeLabel(FieldType type) {
    switch (type) {
      case FieldType.text:
        return 'Text';
      case FieldType.integer:
        return 'Integer (whole numbers)';
      case FieldType.decimal:
        return 'Decimal (numbers with decimals)';
    }
  }
}
