import 'package:flutter/material.dart';
import 'package:elakkaitrack/utils/currency.dart';
import '../models/invoice_item.dart';
import '../models/column_definition.dart';
import '../models/formula_calculation.dart';

enum Currency { naira, dollar, rupee }

class InvoiceRowsPage extends StatefulWidget {
  final List<String> columns;
  final Map<String, FieldType> columnTypes;
  final Map<String, List<String>> columnOptions;
  final List<InvoiceItem> existingItems;
  final Currency selectedCurrency;
  final Formula? amountFormula;

  const InvoiceRowsPage({
    super.key,
    required this.columns,
    required this.columnTypes,
    this.columnOptions = const {},
    this.existingItems = const [],
    this.selectedCurrency = Currency.naira,
    this.amountFormula,
  });

  @override
  State<InvoiceRowsPage> createState() => _InvoiceRowsPageState();
}

class _InvoiceRowsPageState extends State<InvoiceRowsPage> {
  late List<InvoiceItem> _items;
  final Map<String, TextEditingController> _controllers = {};
  late final Map<String, FieldType> _columnTypes = {};
  final _formKey = GlobalKey<FormState>();

  late final Currency _selectedCurrency = widget.selectedCurrency;
  late String currencySymbol;

  // Formula calculation
  Formula? _formula;
  bool _useFormula = true; // Always true by default

  @override
  void initState() {
    super.initState();

    // Initialize formula from widget
    _formula = widget.amountFormula;
    _useFormula = true; // Always use formula by default

    _items = List.from(widget.existingItems);

    for (var column in widget.columns) {
      _controllers[column] = TextEditingController();
      _columnTypes[column] = widget.columnTypes[column]!;
    }

    currencySymbol = getCurrencySymbol(_selectedCurrency);
  }

  double calculateAmount() {
    final Map<String, dynamic> values = {};

    for (var column in widget.columns) {
      final fieldType = _columnTypes[column] ?? FieldType.text;
      final textValue = _controllers[column]!.text;

      // Process value based on field type
      switch (fieldType) {
        case FieldType.integer:
          values[column] = int.tryParse(textValue) ?? 0;
          break;
        case FieldType.decimal:
          values[column] = double.tryParse(textValue) ?? 0.0;
          break;
        case FieldType.text:
          values[column] = textValue;
          break;
      }
    }
    double amount = values['Amount'] ?? 0.0;
    if (_useFormula && _formula != null) {
      amount = _formula!.calculate(values);
      values['Amount'] = amount;
    }
    return amount;
  }

  void _addRow() {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> values = {};

      for (var column in widget.columns) {
        final fieldType = _columnTypes[column] ?? FieldType.text;
        final textValue = _controllers[column]!.text;

        // Check if this column has options
        final hasOptions = widget.columnOptions.containsKey(column) &&
            widget.columnOptions[column]!.isNotEmpty;

        // If it has options, we already validated the input when selecting from dropdown
        if (hasOptions) {
          switch (fieldType) {
            case FieldType.integer:
              values[column] = int.tryParse(textValue) ?? 0;
              break;
            case FieldType.decimal:
              values[column] = double.tryParse(textValue) ?? 0.0;
              break;
            case FieldType.text:
              values[column] = textValue;
              break;
          }
        } else {
          // Regular text input handling
          switch (fieldType) {
            case FieldType.integer:
              values[column] = int.tryParse(textValue) ?? 0;
              break;
            case FieldType.decimal:
              values[column] = double.tryParse(textValue) ?? 0.0;
              break;
            case FieldType.text:
              values[column] = textValue;
              break;
          }
        }
      }

      double amount = values['Amount'] ?? 0.0;
      if (_useFormula && _formula != null) {
        amount = _formula!.calculate(values);
        values['Amount'] = amount;
      }

      setState(() {
        final item = InvoiceItem(values: values, amount: amount);
        _items.add(item);
      });

      for (var controller in _controllers.values) {
        controller.clear();
      }
    }
  }

  void _removeRow(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  bool _hasPendingData() {
    bool hasData = false;

    for (var column in widget.columns) {
      final text = _controllers[column]?.text ?? '';
      if (text.isNotEmpty) {
        hasData = true;
      }
    }

    return hasData;
  }

  bool _addPendingRowIfNeeded() {
    if (_hasPendingData()) {
      if (_formKey.currentState == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internal error: Form state is null'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      final isValid = _formKey.currentState!.validate();
      if (isValid) {
        _addRow();
        return true;
      } else {
        // Check if all controller values are empty
        bool allEmpty = _controllers.values
            .where((controller) => controller != _controllers['Amount'])
            .every((controller) => controller.text.isEmpty);

        if (allEmpty) {
          return true;
        }
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Add Rows'),
        actions: [
          // Save button
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              final canProceed = _addPendingRowIfNeeded();
              if (canProceed) {
                Navigator.pop(context, {
                  'items': _items,
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.only(bottom: 80, left: 8.0, right: 8.0, top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Card(
                margin: const EdgeInsets.all(8.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add New Row',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ...widget.columns.map((column) {
                        final fieldType =
                            _columnTypes[column] ?? FieldType.text;

                        if (column == 'Amount') {
                          // Calculate the amount based on current input values
                          double calculatedAmount = calculateAmount();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Label for the Amount field
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 8),
                                  child: Text(
                                    'Amount',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                // Container to display the calculated amount
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 18),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.grey.shade50,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Display the calculated amount
                                      Text(
                                        '$currencySymbol${formatNumber(calculatedAmount)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      // Show formula information
                                      if (_useFormula && _formula != null)
                                        Tooltip(
                                          message:
                                              'Using formula: ${_formula!.getFormulaString()}',
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.functions,
                                                  color: Colors.blue, size: 20),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formula!.getFormulaString(),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade700,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Store the calculated amount in the controller for later use
                                SizedBox(
                                  height: 0,
                                  width: 0,
                                  child: TextFormField(
                                    controller: _controllers[column]!
                                      ..text = calculatedAmount.toString(),
                                    enabled: false,
                                    style: const TextStyle(height: 0),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Check if this column has options for dropdown
                          final hasOptions =
                              widget.columnOptions.containsKey(column) &&
                                  widget.columnOptions[column]!.isNotEmpty;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: hasOptions
                                // Use dropdown if options are available
                                ? DropdownButtonFormField<String>(
                                    value: _controllers[column]!.text.isNotEmpty
                                        ? _controllers[column]!.text
                                        : null,
                                    decoration: InputDecoration(
                                      labelText: column,
                                      border: const OutlineInputBorder(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 16),
                                    ),
                                    hint:
                                        Text('Select ${column.toLowerCase()}'),
                                    items: widget.columnOptions[column]!
                                        .map((option) {
                                      return DropdownMenuItem<String>(
                                        value: option,
                                        child: Text(option),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        _controllers[column]!.text = value;
                                        // Update UI when input changes to recalculate amount
                                        if (_useFormula && _formula != null) {
                                          setState(() {});
                                        }
                                      }
                                    },
                                    // Format the display value based on field type
                                    selectedItemBuilder: (context) {
                                      return widget.columnOptions[column]!
                                          .map((option) {
                                        return Text(option);
                                      }).toList();
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select $column';
                                      }
                                      return null;
                                    },
                                  )
                                // Use text field if no options are available
                                : TextFormField(
                                    controller: _controllers[column],
                                    decoration: InputDecoration(
                                      labelText: column,
                                      border: const OutlineInputBorder(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 16),
                                      hintText: 'Enter ${column.toLowerCase()}',
                                    ),
                                    keyboardType: fieldType == FieldType.text
                                        ? TextInputType.text
                                        : TextInputType.number,
                                    onChanged: (_) {
                                      // Update UI when input changes to recalculate amount
                                      if (_useFormula && _formula != null) {
                                        setState(() {});
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter $column';
                                      }

                                      // Validate
                                      if (fieldType == FieldType.integer) {
                                        if (int.tryParse(value) == null) {
                                          return 'Please enter a valid whole number';
                                        }
                                      } else if (fieldType ==
                                          FieldType.decimal) {
                                        if (double.tryParse(value) == null) {
                                          return 'Please enter a valid number';
                                        }
                                      }

                                      return null;
                                    },
                                  ),
                          );
                        }
                      }),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addRow,
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                          ),
                          label: const Text('Add Row'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_items.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Added Rows',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_items.length} rows',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  String primaryValue =
                      item.getValue(widget.columns.first).toString();

                  String amountText = '';
                  if (widget.columns.contains('Amount')) {
                    final amount = item.getValue('Amount');
                    if (amount != null) {
                      amountText = '$currencySymbol${formatNumber(amount)}';
                    }
                  }

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    child: ListTile(
                      title: Text(primaryValue),
                      subtitle: Text(
                        widget.columns
                            .map((col) {
                              if (col != primaryValue) {
                                return '$col: ${item.getValue(col)}';
                              }
                              return '';
                            })
                            .where((text) => text.isNotEmpty)
                            .join(', '),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (amountText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Text(
                                amountText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeRow(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
