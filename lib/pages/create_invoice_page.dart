import 'package:flutter/material.dart';
import 'package:elakkaitrack/services/column_options_service.dart';
import 'package:elakkaitrack/services/customer_options_service.dart';
import 'package:elakkaitrack/services/company_info_service.dart';
import 'package:elakkaitrack/utils/currency.dart';
import 'package:elakkaitrack/utils/column_utils.dart';
import 'package:elakkaitrack/pages/customer_options_page.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/column_definition.dart';
import '../models/formula_calculation.dart';
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
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companySubtitleController =
      TextEditingController();
  final TextEditingController _invoiceTitleController = TextEditingController();
  final TextEditingController _buildyController = TextEditingController();
  final TextEditingController _numberOfBagsController =
      TextEditingController(text: '0');
  final TextEditingController _contactNumberController =
      TextEditingController(text: '');

  // Date picker variables
  DateTime _selectedDate = DateTime.now();

  final List<String> _paymentMethods = [];
  final TextEditingController _paymentMethodController =
      TextEditingController();

  // Store columns and items
  List<String> _columns = [
    'Lot No',
    'Quality',
    'Brand',
    'Parcel',
    'Kg',
    'Rate',
    'Amount',
  ];

  Map<String, FieldType> _columnTypes = {
    'Lot No': FieldType.integer,
    'Quality': FieldType.text,
    'Brand': FieldType.text,
    'Parcel': FieldType.decimal,
    'Kg': FieldType.decimal,
    'Rate': FieldType.decimal,
    'Amount': FieldType.decimal,
  };

  // Store column options for dropdown fields
  Map<String, List<String>> _columnOptions = {};

  // Store customer name options
  List<String> _customerOptions = [];

  // Company info fields state
  bool _companyNameLocked = false;
  bool _companySubtitleLocked = false;
  bool _contactNumberLocked = false;

  List<InvoiceItem> _items = [];

  List<String> getNonTextColume() {
    return getFilteredColumns(_columns, ["Parcel", "Kg"]);
  }

  int getTotal(String column) {
    return getColumnTotal(column, _columns, _items);
  }

  Currency _selectedCurrency = Currency.rupee;
  double _freightCost = 0.0;
  final TextEditingController _freightCostController =
      TextEditingController(text: '0.0');

  Formula _amountFormula = Formula(
      components: List.from([
    FormulaComponent(columnName: 'Kg', operation: OperationType.multiply),
    FormulaComponent(columnName: 'Rate', operation: OperationType.multiply),
  ]));

  @override
  void initState() {
    super.initState();
    // Load column options
    getSavedColumeOptions(_columns).then((value) {
      setState(() {
        _columnOptions = value;
      });
    });

    // Load customer options
    _loadCustomerOptions();

    // Load company info
    _loadCompanyInfo();

    if (widget.invoice != null) {
      _loadInvoiceData(widget.invoice!);
    } else {
      // For new invoices, apply saved company info
      _applyCompanyInfo();
    }
  }

  // Load customer options from shared preferences
  Future<void> _loadCustomerOptions() async {
    final options = await CustomerOptionsService.getCustomerOptions();
    setState(() {
      _customerOptions = options;
    });
  }

  // Load company info from shared preferences
  Future<void> _loadCompanyInfo() async {
    final companyInfo = await CompanyInfoService.getCompanyInfo();
    if (companyInfo != null) {
      setState(() {
        // Only lock fields if we have saved company info
        _companyNameLocked = companyInfo.name.isNotEmpty;
        _companySubtitleLocked = companyInfo.subtitle.isNotEmpty;
        _contactNumberLocked = companyInfo.contactNumber.isNotEmpty;
      });
    }
  }

  // Apply saved company info to fields
  Future<void> _applyCompanyInfo() async {
    final companyInfo = await CompanyInfoService.getCompanyInfo();
    if (companyInfo != null && mounted) {
      setState(() {
        if (companyInfo.name.isNotEmpty) {
          _companyNameController.text = companyInfo.name;
          _companyNameLocked = true;
        }

        if (companyInfo.subtitle.isNotEmpty) {
          _companySubtitleController.text = companyInfo.subtitle;
          _companySubtitleLocked = true;
        }

        if (companyInfo.contactNumber.isNotEmpty) {
          _contactNumberController.text = companyInfo.contactNumber;
          _contactNumberLocked = true;
        }
      });
    }
  }

  Future<Map<String, List<String>>> getSavedColumeOptions(
      List<String> columes) async {
    Map<String, List<String>> columnOptions = {};
    // First, try to load saved options for this column
    for (var name in columes) {
      List<String> options =
          await ColumnOptionsService.getOptionsForColumn(name);
      columnOptions[name] = options;
    }
    return columnOptions;
  }

  void _loadInvoiceData(Invoice invoice) {
    _companyNameController.text = invoice.companyName;
    _companySubtitleController.text = invoice.companySubtitle;
    _invoiceTitleController.text = invoice.title;
    _buildyController.text = invoice.buildyNumber;
    _numberOfBagsController.text = invoice.numberOfBags.toString();
    // Handle contact number - only set if it's not 0
    _contactNumberController.text =
        invoice.contactNumber > 0 ? invoice.contactNumber.toString() : '';
    _selectedDate = invoice.invoiceDate;
    _freightCostController.text = invoice.freightCost.toString();
    _selectedCurrency = invoice.currency;
    _columns = invoice.columns;
    _items = invoice.items;
    _paymentMethods.clear();
    _paymentMethods.addAll(invoice.paymentMethods);
    _freightCost = invoice.freightCost;
    if (invoice.formula != null) {
      _amountFormula = invoice.formula!;
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companySubtitleController.dispose();
    _invoiceTitleController.dispose();
    _buildyController.dispose();
    _numberOfBagsController.dispose();
    _contactNumberController.dispose();
    _freightCostController.dispose();
    _paymentMethodController.dispose();

    super.dispose();
  }

  void _updateFreightCost(String value) {
    setState(() {
      _freightCost = double.tryParse(value) ?? 0.0;
    });
  }

  // Show dialog to manage customer name options
  Future<void> _showCustomerOptionsDialog(BuildContext context) async {
    final options = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerOptionsPage(
          initialOptions: _customerOptions,
        ),
      ),
    );

    if (options != null) {
      setState(() {
        _customerOptions = options;

        // If the current customer name is not in the options, clear it
        if (_invoiceTitleController.text.isNotEmpty &&
            !_customerOptions.contains(_invoiceTitleController.text)) {
          // Add the current customer name to options if it's not empty
          if (_invoiceTitleController.text.trim().isNotEmpty) {
            _customerOptions.add(_invoiceTitleController.text.trim());
            CustomerOptionsService.saveCustomerOptions(_customerOptions);
          }
        }
      });
    }
  }

  // Method to show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String? validateInvoiceData() {
    if (_invoiceTitleController.text.trim().isEmpty) {
      return 'Customer name cannot be empty';
    }

    // Validate contact number
    String contactNumber = _contactNumberController.text.trim();
    if (contactNumber.isNotEmpty) {
      // Check if it's a valid number
      if (int.tryParse(contactNumber) == null) {
        return 'Contact number must contain only digits';
      }

      // Check length (assuming Indian phone numbers which are 10 digits)
      if (contactNumber.length != 10) {
        return 'Contact number must be 10 digits';
      }
    }

    return null;
  }

  // Create invoice object
  Invoice createInvoiceData() {
    // Parse contact number with validation
    int contactNum = 0;
    String contactText = _contactNumberController.text.trim();
    if (contactText.isNotEmpty && int.tryParse(contactText) != null) {
      contactNum = int.parse(contactText);
    }

    // Get customer name
    String customerName = _invoiceTitleController.text.trim();

    // Save customer name to options if not already present
    if (customerName.isNotEmpty && !_customerOptions.contains(customerName)) {
      _customerOptions.add(customerName);
      CustomerOptionsService.saveCustomerOptions(_customerOptions);
    }

    // Save company info to preferences
    final companyName = _companyNameController.text.trim();
    final companySubtitle = _companySubtitleController.text.trim();
    final contactNumber = _contactNumberController.text.trim();

    if (companyName.isNotEmpty ||
        companySubtitle.isNotEmpty ||
        contactNumber.isNotEmpty) {
      final companyInfo = CompanyInfo(
        name: companyName,
        subtitle: companySubtitle,
        contactNumber: contactNumber,
      );
      CompanyInfoService.saveCompanyInfo(companyInfo);
    }

    return Invoice(
      id: widget.invoice?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: customerName,
      buildyNumber: _buildyController.text.trim(),
      createdAt: widget.invoice?.createdAt ?? DateTime.now(),
      invoiceDate: _selectedDate,
      numberOfBags: int.tryParse(_numberOfBagsController.text) ?? 0,
      contactNumber: contactNum,
      columns: _columns,
      items: _items,
      freightCost: _freightCost,
      currency: _selectedCurrency,
      paymentMethods: _paymentMethods,
      formula: _amountFormula, // Include formula in the invoice
      companyName: _companyNameController.text.trim(),
      companySubtitle: _companySubtitleController.text.trim(),
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
                        'Company Information',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _companyNameController,
                            decoration: const InputDecoration(
                              labelText: 'Company Name',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 16),
                              hintText: 'Enter your company name',
                              prefixIcon: Icon(Icons.business),
                            ),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            onEditingComplete: () =>
                                FocusScope.of(context).nextFocus(),
                            enabled: !_companyNameLocked,
                          ),
                        ),
                        if (_companyNameLocked) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit company name',
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () {
                              setState(() {
                                _companyNameLocked = false;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _companySubtitleController,
                            decoration: const InputDecoration(
                              labelText: 'Company Subtitle',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 16),
                              hintText: 'Enter company subtitle or tagline',
                              prefixIcon: Icon(Icons.short_text),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
                            onEditingComplete: () =>
                                FocusScope.of(context).nextFocus(),
                            enabled: !_companySubtitleLocked,
                          ),
                        ),
                        if (_companySubtitleLocked) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit company subtitle',
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () {
                              setState(() {
                                _companySubtitleLocked = false;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _contactNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Contact Number',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 16),
                              hintText: 'Enter 10-digit contact number',
                              prefixText: '+91',
                              prefixIcon: Icon(Icons.numbers_outlined),
                              helperText: 'Enter a 10-digit mobile number',
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            maxLength: 10,
                            onEditingComplete: () =>
                                FocusScope.of(context).nextFocus(),
                            // Add inline validation
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return null; // Contact number is optional
                              }
                              if (int.tryParse(value) == null) {
                                return 'Enter digits only';
                              }
                              if (value.length != 10) {
                                return 'Must be 10 digits';
                              }
                              return null;
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            enabled: !_contactNumberLocked,
                          ),
                        ),
                        if (_contactNumberLocked) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit contact number',
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () {
                              setState(() {
                                _contactNumberLocked = false;
                              });
                            },
                          ),
                        ],
                      ],
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
                    Row(
                      children: [
                        Expanded(
                          child: _customerOptions.isEmpty
                              ? TextFormField(
                                  controller: _invoiceTitleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Customer Name',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 16),
                                    hintText: 'Enter customer name',
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  onEditingComplete: () =>
                                      FocusScope.of(context).nextFocus(),
                                )
                              : DropdownButtonFormField<String>(
                                  value: _invoiceTitleController.text.isNotEmpty
                                      ? (_customerOptions.contains(
                                              _invoiceTitleController.text)
                                          ? _invoiceTitleController.text
                                          : null)
                                      : null,
                                  decoration: const InputDecoration(
                                    labelText: 'Customer Name',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 16),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  hint: const Text('Select customer'),
                                  items: _customerOptions.map((option) {
                                    return DropdownMenuItem<String>(
                                      value: option,
                                      child: Text(option),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _invoiceTitleController.text = value;
                                      });
                                    }
                                  },
                                  isExpanded: true,
                                ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          tooltip: 'Add customer options',
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () => _showCustomerOptionsDialog(context),
                        ),
                      ],
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
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                    ),

                    const SizedBox(height: 16),

                    // Date picker field
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Invoice Date',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Number of bags field
                    TextFormField(
                      controller: _numberOfBagsController,
                      decoration: const InputDecoration(
                        labelText: 'No of Bags',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        hintText: 'Enter number of bags',
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                      keyboardType: TextInputType.number,
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
                              prefixIcon: Icon(Icons.currency_exchange),
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
                              prefixIcon:
                                  const Icon(Icons.local_shipping_outlined),
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
                                columnOptions: _columnOptions,
                                amountFormula: _amountFormula),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            _columns = result['columns'];
                            _columnTypes = result['columnTypes'];
                            _amountFormula = result['amountFormula'];
                            _columnOptions = result['columnOptions'] ?? {};
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
                      onTap: () async {
                        // Navigate directly to the rows page with the stored column definitions
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InvoiceRowsPage(
                              columns: _columns,
                              columnTypes: _columnTypes,
                              columnOptions: _columnOptions,
                              existingItems: _items,
                              selectedCurrency: _selectedCurrency,
                              amountFormula: _amountFormula,
                            ),
                          ),
                        );

                        if (result != null && mounted) {
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
                            ...getNonTextColume().map((col) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total $col:',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text('${getTotal(col)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                )),
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
