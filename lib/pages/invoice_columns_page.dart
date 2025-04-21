import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/column_definition.dart';

class InvoiceColumnsPage extends StatefulWidget {
  final List<String> existingColumns;
  final Map<String, FieldType> existingColumnTypes;

  const InvoiceColumnsPage({
    super.key,
    this.existingColumns = const [],
    this.existingColumnTypes = const {},
  });

  @override
  State<InvoiceColumnsPage> createState() => _InvoiceColumnsPageState();
}

class _InvoiceColumnsPageState extends State<InvoiceColumnsPage> {
  late List<ColumnDefinition> _columns;
  final TextEditingController _columnController = TextEditingController();
  FieldType _selectedFieldType = FieldType.text;

  @override
  void initState() {
    super.initState();
    widget.existingColumns.remove("Amount");
    widget.existingColumns.add("Amount");
    _columns = widget.existingColumns.map((name) {
      return ColumnDefinition(
        name: name,
        fieldType: widget.existingColumnTypes[name] ?? FieldType.text,
      );
    }).toList();
  }

  @override
  void dispose() {
    _columnController.dispose();
    super.dispose();
  }

  void _addColumn() {
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

    setState(() {
      final newColumn =
          ColumnDefinition(name: columnName, fieldType: _selectedFieldType);

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

  @override
  Widget build(BuildContext context) {
    final totalItems = _columns.length + 1; // +1 for the header

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Define Columns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _ensureAmountColumnIsLast();

              final List<String> columnNames =
                  _columns.map((col) => col.name).toList();

              final Map<String, FieldType> columnTypes = {};
              for (var col in _columns) {
                columnTypes[col.name] = col.fieldType;
              }

              Navigator.pop(context, {
                'columns': columnNames,
                'columnTypes': columnTypes,
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
                        onPressed: _addColumn,
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
            color: _isDefaultColumn(column.name)
                ? Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha(128)
                : null,
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
                  if (_isDefaultColumn(column.name))
                    const Tooltip(
                      message: 'Default column (cannot be removed)',
                      child: Icon(Icons.lock, color: Colors.grey),
                    )
                  else
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
