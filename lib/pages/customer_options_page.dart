import 'package:flutter/material.dart';
import '../services/customer_options_service.dart';

class CustomerOptionsPage extends StatefulWidget {
  final List<String> initialOptions;

  const CustomerOptionsPage({
    super.key,
    required this.initialOptions,
  });

  @override
  State<CustomerOptionsPage> createState() => _CustomerOptionsPageState();
}

class _CustomerOptionsPageState extends State<CustomerOptionsPage> {
  final TextEditingController _optionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<String> _options = [];
  bool _isLoading = true;
  bool _isEditing = false;
  int _editingIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    // First, try to load saved options
    List<String> savedOptions = await CustomerOptionsService.getCustomerOptions();

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
        const SnackBar(content: Text('Customer name already exists')),
      );
    }
  }

  Future<void> _saveOptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save options to shared preferences
      await CustomerOptionsService.saveCustomerOptions(_options);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer names saved')),
        );

        // Return the options to the caller
        Navigator.pop(context, _options);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving customer names: $e')),
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
        title: const Text('Customer Names'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save customer names',
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
                          const Expanded(
                            child: Text(
                              'Customer Names',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add customer names to quickly select them when creating invoices.',
                        style: TextStyle(
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
                                _isEditing ? 'Edit Customer' : 'Add Customer',
                            hintText: 'Enter customer name',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.person_add_alt_1),
                            suffixIcon: _isEditing
                                ? IconButton(
                                    icon: const Icon(Icons.cancel),
                                    onPressed: _cancelEditing,
                                    tooltip: 'Cancel editing',
                                  )
                                : null,
                          ),
                          textCapitalization: TextCapitalization.words,
                          onSubmitted: (_) => _addOption(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addOption,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        child: Text(_isEditing ? 'Update' : 'Add'),
                      ),
                    ],
                  ),
                ),

                // Options list
                Expanded(
                  child: _options.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No customer names added yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Add customer names using the field above',
                                style: TextStyle(
                                  fontSize: 14,
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
                                  child: const Icon(Icons.person),
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
                                      tooltip: 'Edit customer',
                                      onPressed: () => _editOption(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      tooltip: 'Remove customer',
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
    );
  }
}
