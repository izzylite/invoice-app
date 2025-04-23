import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/column_definition.dart';
import '../models/formula_calculation.dart';
import '../services/column_options_service.dart';
import '../widgets/formula_dialog.dart';
import 'column_options_page.dart';

class InvoiceColumnsPage extends StatefulWidget {
  final List<String> existingColumns;
  final Map<String, List<String>> columnOptions;
  final Map<String, FieldType> existingColumnTypes;
  final Formula? amountFormula;

  const InvoiceColumnsPage(
      {super.key,
      this.existingColumns = const [],
      this.existingColumnTypes = const {},
      this.columnOptions = const {},
      this.amountFormula});

  @override
  State<InvoiceColumnsPage> createState() => _InvoiceColumnsPageState();
}

class _InvoiceColumnsPageState extends State<InvoiceColumnsPage> {
  late List<ColumnDefinition> _columns;
  final TextEditingController _columnController = TextEditingController();
  FieldType _selectedFieldType = FieldType.text;

  // Formula properties
  Formula? _amountFormula;

  @override
  void initState() {
    super.initState();
    // Initialize formula properties
    _amountFormula = widget.amountFormula;

    // Ensure Amount is the last column
    widget.existingColumns.remove("Amount");
    widget.existingColumns.add("Amount");
    // Initialize columns
    _columns = widget.existingColumns.map((name) {
      if (name == 'Amount') {
        return ColumnDefinition(
            name: name,
            fieldType: widget.existingColumnTypes[name] ?? FieldType.decimal,
            formula: _amountFormula,
            options: widget.columnOptions[name] ?? []);
      }
      return ColumnDefinition(
        name: name,
        options: widget.columnOptions[name] ?? [],
        fieldType: widget.existingColumnTypes[name] ?? FieldType.text,
      );
    }).toList();
  }

  @override
  void dispose() {
    _columnController.dispose();
    super.dispose();
  }

  Future<void> _addColumn() async {
    final columnName = _columnController.text.trim();
    if (columnName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a column name')),
      );
      return;
    }

    if (_columns
        .any((col) => col.name.toLowerCase() == columnName.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Column with this name already exists')),
      );
      return;
    }

    // Check if we have saved options for this column
    List<String> savedOptions =
        await ColumnOptionsService.getOptionsForColumn(columnName);

    setState(() {
      final newColumn = ColumnDefinition(
        name: columnName,
        fieldType: _selectedFieldType,
        options: savedOptions, // Use saved options if available
      );

      if (columnName.toLowerCase() == 'amount') {
        int existingAmountIndex =
            _columns.indexWhere((col) => col.name.toLowerCase() == 'amount');

        if (existingAmountIndex != -1) {
          _columns.removeAt(existingAmountIndex);
        }

        _columns.add(newColumn);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Amount column will always be the last column')),
        );
      } else {
        int amountIndex =
            _columns.indexWhere((col) => col.name.toLowerCase() == 'amount');
        if (amountIndex != -1) {
          _columns.insert(amountIndex, newColumn);
        } else {
          _columns.add(newColumn);
        }

        // Show a message if options were loaded
        if (savedOptions.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Loaded ${savedOptions.length} saved options for $columnName')),
          );
        }
      }

      _columnController.clear();
      _selectedFieldType = FieldType.text; // Reset to default
    });

    HapticFeedback.lightImpact();
  }

  void _removeColumn(int index) {
    setState(() {
      _columns.removeAt(index);
    });

    HapticFeedback.mediumImpact();
  }

  bool _isDefaultColumn(String name) {
    return name == 'Amount';
  }

  void _showFormulaDialog(BuildContext context) {
    List<String> numericColumns = _columns
        .where((col) =>
            col.name != 'Amount' &&
            (col.fieldType == FieldType.decimal ||
                col.fieldType == FieldType.integer))
        .map((col) => col.name)
        .toList();

    showFormulaDialog(
      context,
      initialUseFormula: true,
      initialFormula: _amountFormula,
      numericColumns: numericColumns,
    ).then((result) {
      if (result != null) {
        setState(() {
          _amountFormula = result['formula'];

          // Update the Amount column definition
          int amountIndex = _columns.indexWhere((col) => col.name == 'Amount');
          if (amountIndex != -1) {
            _columns[amountIndex] = _columns[amountIndex].copyWith(
              formula: _amountFormula,
            );
          }
        });
      }
    });
  }

  Icon _getFieldTypeIcon(FieldType type) {
    switch (type) {
      case FieldType.text:
        return const Icon(Icons.text_fields);
      case FieldType.integer:
        return const Icon(Icons.numbers);
      case FieldType.decimal:
        return const Icon(Icons.attach_money);
    }
  }

  String _getFieldTypeLabel(FieldType type) {
    switch (type) {
      case FieldType.text:
        return 'Text';
      case FieldType.integer:
        return 'Integer';
      case FieldType.decimal:
        return 'Decimal';
    }
  }

  void _ensureAmountColumnIsLast() {
    int amountIndex =
        _columns.indexWhere((col) => col.name.toLowerCase() == 'amount');

    if (amountIndex != -1 && amountIndex != _columns.length - 1) {
      final amountColumn = _columns.removeAt(amountIndex);
      _columns.add(amountColumn);
    }
  }

  // Show page to create or edit options for a column
  void _showOptionsDialog(BuildContext context, int columnIndex) async {
    final column = _columns[columnIndex];

    final options = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => ColumnOptionsPage(
          column: column,
          initialOptions: column.options,
        ),
      ),
    );

    if (options != null) {
      setState(() {
        _columns[columnIndex] = column.copyWith(options: options);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _columns.length + 1; // +1 for the header

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Define Columns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              _ensureAmountColumnIsLast();

              final List<String> columnNames =
                  _columns.map((col) => col.name).toList();

              final Map<String, FieldType> columnTypes = {};
              for (var col in _columns) {
                columnTypes[col.name] = col.fieldType;
              }

              // Find the Amount column to get its formula
              ColumnDefinition? amountColumn = _columns.firstWhere(
                (col) => col.name == 'Amount',
                orElse: () => ColumnDefinition(
                    name: 'Amount', fieldType: FieldType.decimal),
              );

              // Create a map of column options
              final Map<String, List<String>> columnOptions = {};
              for (var col in _columns) {
                if (col.hasOptions) {
                  columnOptions[col.name] = col.options;
                }
              }

              Navigator.pop(context, {
                'columns': columnNames,
                'columnTypes': columnTypes,
                'amountFormula': amountColumn.formula,
                'columnOptions': columnOptions,
              });
            },
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: totalItems,
        onReorderStart: (index) {
          HapticFeedback.lightImpact();
        },
        onReorderEnd: (index) {
          HapticFeedback.mediumImpact();
        },
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              return Material(
                elevation: 0,
                color: Colors.transparent,
                shadowColor: Colors.black.withAlpha(100),
                child: child,
              );
            },
            child: child,
          );
        },
        onReorder: (oldIndex, newIndex) {
          if (oldIndex == 0 || newIndex == 0) return;

          setState(() {
            final adjustedOldIndex = oldIndex - 1;
            var adjustedNewIndex = newIndex - 1;

            if (adjustedOldIndex < adjustedNewIndex) {
              adjustedNewIndex -= 1;
            }

            final item = _columns.removeAt(adjustedOldIndex);

            if (item.name == 'Amount') {
              _columns.add(item);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Amount column must be the last column')),
              );
            } else if (adjustedNewIndex >= _columns.length ||
                (adjustedNewIndex > 0 &&
                    _columns[adjustedNewIndex - 1].name == 'Amount')) {
              int amountIndex =
                  _columns.indexWhere((col) => col.name == 'Amount');
              if (amountIndex != -1) {
                _columns.insert(amountIndex, item);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Amount column must be the last column')),
                );
              } else {
                _columns.insert(adjustedNewIndex, item);
              }
            } else {
              _columns.insert(adjustedNewIndex, item);
            }

            HapticFeedback.mediumImpact();
          });
        },
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              key: const ValueKey('header'),
              margin: const EdgeInsets.all(8.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Column',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _columnController,
                      decoration: const InputDecoration(
                        labelText: 'Column Name',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        hintText: 'Enter column name',
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<FieldType>(
                      decoration: const InputDecoration(
                        labelText: 'Field Type',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: _selectedFieldType,
                      items: const [
                        DropdownMenuItem(
                          value: FieldType.text,
                          child: Text('Text'),
                        ),
                        DropdownMenuItem(
                          value: FieldType.integer,
                          child: Text('Integer (whole numbers)'),
                        ),
                        DropdownMenuItem(
                          value: FieldType.decimal,
                          child: Text('Decimal (numbers with decimals)'),
                        ),
                      ],
                      onChanged: (FieldType? value) {
                        if (value != null) {
                          setState(() {
                            _selectedFieldType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _addColumn(),
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.white),
                        label: const Text('Add Column'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _columns.isEmpty
                            ? 'Add at least one column to continue'
                            : 'You can reorder columns by dragging them',
                        style: TextStyle(
                          color: _columns.isEmpty ? Colors.red : Colors.grey,
                          fontStyle: _columns.isEmpty
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final columnIndex = index - 1;
          final column = _columns[columnIndex];

          return Card(
            key: ValueKey(column.name + columnIndex.toString()),
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            child: ListTile(
              leading: _getFieldTypeIcon(column.fieldType),
              title: Text(
                column.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Type: ${_getFieldTypeLabel(column.fieldType)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Options button for all columns except Amount
                  if (!_isDefaultColumn(column.name))
                    IconButton(
                      icon: column.hasOptions
                          ? const Tooltip(
                              message: 'Options available',
                              child: Icon(Icons.list_alt, color: Colors.blue),
                            )
                          : const Icon(Icons.list_alt),
                      tooltip: 'Create options for this column',
                      onPressed: () => _showOptionsDialog(context, columnIndex),
                    ),

                  if (_isDefaultColumn(column.name)) ...[
                    // Formula button for Amount column
                    IconButton(
                      icon: column.formula != null
                          ? const Tooltip(
                              message: 'Formula is set',
                              child: Icon(Icons.calculate_outlined,
                                  color: Colors.blue),
                            )
                          : const Icon(Icons.calculate_outlined),
                      tooltip: 'Set formula for Amount calculation',
                      onPressed: () => _showFormulaDialog(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.lock, color: Colors.grey),
                      tooltip: 'Cannot delete amount',
                      onPressed: () => {},
                    )
                  ] else
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Remove column',
                      onPressed: () => _removeColumn(columnIndex),
                    ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(
                      Icons.drag_handle,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
