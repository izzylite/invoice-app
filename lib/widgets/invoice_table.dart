import 'package:flutter/material.dart';
import 'package:elakkaitrack/utils/currency.dart';
import '../models/invoice_item.dart';

class InvoiceTable extends StatefulWidget {
  final List<String> columns;
  final List<InvoiceItem> items;
  final String currencySymbol;
  final bool showActions;
  final Function(int)? onRemoveRow;
  final BoxConstraints? constraints;

  const InvoiceTable({
    super.key,
    required this.columns,
    required this.items,
    required this.currencySymbol,
    this.showActions = false,
    this.onRemoveRow,
    this.constraints,
  });

  @override
  State<InvoiceTable> createState() => _InvoiceTableState();
}

class _InvoiceTableState extends State<InvoiceTable> {
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: widget.constraints,
          child: _buildScrollableTable(context),
        ),
        if (widget.columns.length > 3)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.swipe, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Swipe horizontally to see more columns',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildScrollableTable(BuildContext context) {
    return Scrollbar(
      thickness: 6,
      radius: const Radius.circular(8),
      thumbVisibility: true,
      controller: _verticalScrollController,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          thickness: 6,
          radius: const Radius.circular(8),
          thumbVisibility: true,
          controller: _horizontalScrollController,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: _buildDataTable(context),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable(BuildContext context) {
    return DataTable(
      headingRowColor: WidgetStateProperty.resolveWith(
        (states) => Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      columns: [
        ...widget.columns.map(
          (column) => DataColumn(
            label: Text(
              column,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (widget.showActions)
          const DataColumn(
            label: Text(
              'Actions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
      ],
      rows: widget.items.isEmpty
          ? [
              DataRow(
                cells: [
                  ...widget.columns.map(
                    (column) => DataCell(
                      Text(
                        '—',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  if (widget.showActions)
                    const DataCell(
                      Text('', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ]
          : widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return DataRow(
                cells: [
                  ...widget.columns.map(
                    (column) => DataCell(
                      Text(
                        column == 'Amount'
                            ? '${widget.currencySymbol}${formatNumber(item.getValue(column))}'
                            : item.getValue(column).toString(),
                        style: column == 'Amount'
                            ? const TextStyle(fontWeight: FontWeight.bold)
                            : null,
                      ),
                    ),
                  ),
                  if (widget.showActions)
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: widget.onRemoveRow != null
                            ? () => widget.onRemoveRow!(index)
                            : null,
                        tooltip: 'Remove item',
                      ),
                    ),
                ],
              );
            }).toList(),
    );
  }
}
