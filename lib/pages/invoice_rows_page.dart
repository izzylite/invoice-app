import 'package:flutter/material.dart';
import 'package:invoice_app/utils/currency.dart';
import '../models/invoice_item.dart';
import '../models/column_definition.dart';

enum Currency { naira, dollar, rupee }

class InvoiceRowsPage extends StatefulWidget {
  final List<String> columns;
  final Map<String, FieldType> columnTypes;
  final List<InvoiceItem> existingItems;
  final Currency selectedCurrency;

  const InvoiceRowsPage({
    super.key,
    required this.columns,
    required this.columnTypes,
    this.existingItems = const [],
    this.selectedCurrency = Currency.naira,
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

  @override
  void initState() {
    super.initState();

    widget.columns.remove("Amount");
    widget.columns.add("Amount");
    _items = List.from(widget.existingItems);

    for (var column in widget.columns) {
      _controllers[column] = TextEditingController();
      _columnTypes[column] = widget.columnTypes[column]!;
    }

    currencySymbol = getCurrencySymbol(_selectedCurrency);
  }

  void _addRow() {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> values = {};

      for (var column in widget.columns) {
        final fieldType = _columnTypes[column] ?? FieldType.text;
        final textValue = _controllers[column]!.text;

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

      setState(() {
        final item =
            InvoiceItem(values: values, amount: values['Amount'] ?? 0.0);
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
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, {
                'items': _items,
              });
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
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: TextFormField(
                              controller: _controllers[column],
                              decoration: InputDecoration(
                                labelText: column,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 16),
                                hintText: 'Enter ${column.toLowerCase()}',
                                prefixText: currencySymbol,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter $column';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: TextFormField(
                              controller: _controllers[column],
                              decoration: InputDecoration(
                                labelText: column,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 16),
                                hintText: 'Enter ${column.toLowerCase()}',
                              ),
                              keyboardType: fieldType == FieldType.text
                                  ? TextInputType.text
                                  : TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter $column';
                                }

                                // Validate
                                if (fieldType == FieldType.integer) {
                                  if (int.tryParse(value) == null) {
                                    return 'Please enter a valid whole number';
                                  }
                                } else if (fieldType == FieldType.decimal) {
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
                            .take(3)
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
