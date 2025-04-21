import 'package:flutter/material.dart';
import 'package:invoice_app/utils/currency.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/column_definition.dart';
import '../widgets/invoice_table.dart';
import '../services/invoice_service.dart';
import 'invoice_columns_page.dart';
import 'invoice_rows_page.dart';
import 'invoice_preview_page.dart' show InvoicePreviewPage, PreviewSource;

class CreateInvoicePage extends StatefulWidget {
  final Invoice? invoice;

  const CreateInvoicePage({super.key, this.invoice});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final TextEditingController _invoiceTitleController = TextEditingController();
  final TextEditingController _buildyController = TextEditingController();

  final List<String> _paymentMethods = [];
  final TextEditingController _paymentMethodController =
      TextEditingController();

  // Store columns and items
  List<String> _columns = [
    'Lot No',
    'Quality',
    'Parcel',
    'Kg',
    'Rate',
    'Brand',
    'Amount',
  ];

  Map<String, FieldType> _columnTypes = {
    'Lot No': FieldType.integer,
    'Quality': FieldType.text,
    'Parcel': FieldType.text,
    'Kg': FieldType.decimal,
    'Rate': FieldType.decimal,
    'Brand': FieldType.text,
    'Amount': FieldType.decimal,
  };

  List<InvoiceItem> _items = [];

  Currency _selectedCurrency = Currency.rupee;
  double _freightCost = 0.0;
  final TextEditingController _freightCostController =
      TextEditingController(text: '0.0');

  @override
  void initState() {
    super.initState();

    if (widget.invoice != null) {
      _loadInvoiceData(widget.invoice!);
    }
  }

  void _loadInvoiceData(Invoice invoice) {
    _invoiceTitleController.text = invoice.title;
    _buildyController.text = invoice.buildyNumber;
    _freightCostController.text = invoice.freightCost.toString();
    _selectedCurrency = invoice.currency;
    _columns = invoice.columns;
    _items = invoice.items;
    _paymentMethods.clear();
    _paymentMethods.addAll(invoice.paymentMethods);
    _freightCost = invoice.freightCost;
  }

  @override
  void dispose() {
    _invoiceTitleController.dispose();
    _buildyController.dispose();
    _freightCostController.dispose();
    _paymentMethodController.dispose();

    super.dispose();
  }

  void _updateFreightCost(String value) {
    setState(() {
      _freightCost = double.tryParse(value) ?? 0.0;
    });
  }

  String? validateInvoiceData() {
    if (_invoiceTitleController.text.trim().isEmpty) {
      return 'Invoice title cannot be empty';
    }

    if (_buildyController.text.trim().isEmpty) {
      return 'Buildy number cannot be empty';
    }
    return null;
  }

  // Create invoice object
  Invoice createInvoiceData() {
    return Invoice(
      id: widget.invoice?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _invoiceTitleController.text.trim(),
      buildyNumber: _buildyController.text.trim(),
      createdAt: widget.invoice?.createdAt ?? DateTime.now(),
      columns: _columns,
      items: _items,
      freightCost: _freightCost,
      currency: _selectedCurrency,
      paymentMethods: _paymentMethods,
    );
  }

  double get totalAmount {
    return _items.fold(0.0, (double sum, item) => sum + item.amount);
  }

  double get finalTotal {
    return totalAmount + _freightCost;
  }

  void _removeRow(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _showAddPaymentMethodDialog(BuildContext context) {
    _paymentMethodController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: Row(
          children: [
            Icon(
              Icons.payment,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Add Payment'),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter payment details below:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paymentMethodController,
                decoration: InputDecoration(
                  labelText: 'Payment Details',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2.0,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  hintText:
                      'Enter payment details (e.g., Bank transfer to Account No: 1234567890)',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerLowest,
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 5,
                minLines: 3,
                maxLength: 500,
                textInputAction: TextInputAction.newline,
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final paymentMethod = _paymentMethodController.text.trim();
              if (paymentMethod.isNotEmpty) {
                setState(() {
                  _paymentMethods.add(paymentMethod);
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Create Invoice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: const EdgeInsets.all(8.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Methods',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showAddPaymentMethodDialog(context);
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Add Method',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_paymentMethods.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'No payment methods added yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _paymentMethods.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            elevation: 2,
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: ListTile(
                                leading: Icon(
                                  Icons.payment_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                title: Text(
                                  _paymentMethods[index],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  tooltip: 'Remove payment method',
                                  onPressed: () {
                                    setState(() {
                                      _paymentMethods.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: const EdgeInsets.all(8.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Invoice Details',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextFormField(
                      controller: _invoiceTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Invoice Title',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        hintText: 'Enter a title for this invoice',
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _buildyController,
                      decoration: const InputDecoration(
                        labelText: 'Buildy (Transport number)',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        hintText: 'Enter transport number',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Currency>(
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 16),
                            ),
                            value: _selectedCurrency,
                            items: const [
                              DropdownMenuItem(
                                value: Currency.rupee,
                                child: Text('₹ Rupee'),
                              ),
                              DropdownMenuItem(
                                value: Currency.dollar,
                                child: Text('\$ Dollar'),
                              ),
                              DropdownMenuItem(
                                value: Currency.naira,
                                child: Text('₦ Naira'),
                              ),
                            ],
                            onChanged: (Currency? value) {
                              if (value != null) {
                                setState(() {
                                  _selectedCurrency = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _freightCostController,
                            decoration: InputDecoration(
                              labelText: 'Freight Cost',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 16),
                              hintText: 'Enter freight cost',
                              prefixText: getCurrencySymbol(_selectedCurrency),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: _updateFreightCost,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InvoiceColumnsPage(
                              existingColumns: _columns,
                              existingColumnTypes: _columnTypes,
                            ),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            _columns = result['columns'];
                            _columnTypes = result['columnTypes'];
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.view_column,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add Columns',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_columns.length} columns defined',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    child: InkWell(
                      onTap: _columns.isEmpty
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please define columns first'),
                                ),
                              );
                            }
                          : () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InvoiceRowsPage(
                                    columns: _columns,
                                    columnTypes: _columnTypes,
                                    existingItems: _items,
                                    selectedCurrency: _selectedCurrency,
                                  ),
                                ),
                              );

                              if (result != null) {
                                setState(() {
                                  _items = result['items'];
                                });
                              }
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.view_list,
                              size: 48,
                              color: _columns.isEmpty
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add Items',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_items.length} items added',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_columns.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: const Text(
                  'Invoice Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                child: Column(
                  children: [
                    InvoiceTable(
                        columns: _columns,
                        items: _items,
                        currencySymbol: getCurrencySymbol(_selectedCurrency),
                        showActions: true,
                        onRemoveRow: _removeRow),
                    if (_items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                size: 24,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Click "Add Rows" to add invoice items',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Divider(height: 32, thickness: 1),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Amount:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      '${getCurrencySymbol(_selectedCurrency)}${formatNumber(totalAmount)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Freight Cost:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      '${getCurrencySymbol(_selectedCurrency)}${formatNumber(_freightCost)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Final Total:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text(
                                    '${getCurrencySymbol(_selectedCurrency)}${formatNumber(finalTotal)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final validationError =
                                        validateInvoiceData();

                                    if (validationError != null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(validationError),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    final invoice = createInvoiceData();

                                    final scaffoldMessenger =
                                        ScaffoldMessenger.of(context);

                                    try {
                                      scaffoldMessenger.showSnackBar(
                                        const SnackBar(
                                            content: Text('Saving invoice...')),
                                      );

                                      final success =
                                          await InvoiceService.saveInvoice(
                                              invoice);

                                      if (success && context.mounted) {
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Invoice saved successfully!')),
                                        );

                                        Navigator.of(context).pop(true);
                                      } else if (context.mounted) {
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Failed to save invoice. Please try again.')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error saving invoice: $e')),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.save,
                                      color: Colors.white),
                                  label: const Text('SAVE',
                                      style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    final validationError =
                                        validateInvoiceData();

                                    if (validationError != null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(validationError),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    final invoice = createInvoiceData();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            InvoicePreviewPage(
                                                invoice: invoice,
                                                source: PreviewSource
                                                    .createInvoice),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.preview,
                                      color: Colors.white),
                                  label: const Text('PREVIEW',
                                      style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.tertiary,
                                    foregroundColor: Theme.of(context)
                                        .colorScheme
                                        .onTertiary,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
