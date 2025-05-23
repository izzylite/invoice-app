import 'dart:async';
import 'package:flutter/material.dart';
import 'package:elakkaitrack/utils/currency.dart';
import 'package:elakkaitrack/utils/column_utils.dart';
import '../models/invoice.dart';
import '../widgets/invoice_table.dart';
import '../services/export_service.dart';
import '../services/pdf_export_service.dart';
import '../services/invoice_service.dart';
import 'create_invoice_page.dart';

// Define an enum for the source of navigation
enum PreviewSource { dashboard, createInvoice }

class InvoicePreviewPage extends StatelessWidget {
  final Invoice invoice;
  final PreviewSource source;

  const InvoicePreviewPage(
      {super.key,
      required this.invoice,
      this.source = PreviewSource.createInvoice});

  // Get non-text columns (specifically Parcel and Kg)
  List<String> getNonTextColumns() {
    return getFilteredColumns(invoice.columns, ["Parcel", "Kg"]);
  }

  // Calculate total for a specific column
  int getTotal(String column) {
    return getColumnTotal(column, invoice.columns, invoice.items);
  }

  void _showExportOptions(BuildContext context, Invoice invoice) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Invoice',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              subtitle: const Text('Create a PDF document'),
              onTap: () {
                Navigator.pop(context);
                _exportInvoiceToPdf(context, invoice);
              },
            ),
            ListTile(
              leading: const Icon(Icons.print, color: Colors.blue),
              title: const Text('Print Invoice'),
              subtitle: const Text('Send to printer'),
              onTap: () {
                Navigator.pop(context);
                _printInvoice(context, invoice);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as CSV'),
              subtitle: const Text('Create a spreadsheet file'),
              onTap: () {
                Navigator.pop(context);
                _exportInvoiceToCSV(context, invoice);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportInvoiceToPdf(
      BuildContext context, Invoice invoice) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creating PDF...')),
    );

    try {
      final filePath = await PdfExportService.exportInvoiceToPdf(invoice);
      if (filePath != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF created successfully!')),
        );

        // Show options for sharing or viewing
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PDF Created',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.blue),
                  title: const Text('Share PDF'),
                  onTap: () {
                    Navigator.pop(context);
                    PdfExportService.sharePdfFile(filePath);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.print, color: Colors.green),
                  title: const Text('Print PDF'),
                  onTap: () {
                    Navigator.pop(context);
                    PdfExportService.printPdf(filePath);
                  },
                ),
              ],
            ),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to create PDF. Please try again.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating PDF: $e')),
        );
      }
    }
  }

  Future<void> _printInvoice(BuildContext context, Invoice invoice) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing to print...')),
    );

    try {
      final filePath = await PdfExportService.exportInvoiceToPdf(invoice);
      if (filePath != null && context.mounted) {
        await PdfExportService.printPdf(filePath);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to prepare print job. Please try again.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _exportInvoiceToCSV(
      BuildContext context, Invoice invoice) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting to CSV...')),
    );

    try {
      final filePath = await ExportService.exportInvoiceToCSV(invoice);
      if (filePath != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('CSV export successful! Opening share dialog...')),
        );

        await ExportService.shareCSVFile(filePath);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to export CSV. Please try again.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Invoice Preview'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company information card
            if (invoice.companyName.isNotEmpty ||
                invoice.companySubtitle.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (invoice.companyName.isNotEmpty)
                        Text(
                          invoice.companyName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      if (invoice.companySubtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            invoice.companySubtitle,
                            style: const TextStyle(
                                fontSize: 16, fontStyle: FontStyle.italic),
                          ),
                        ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.business,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text(
                            'Invoice Information',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Invoice header card
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text(
                          'Customer: ',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          invoice.title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Date: ${invoice.invoiceDate.day}-${invoice.invoiceDate.month}-${invoice.invoiceDate.year}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    if (invoice.buildyNumber.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Buildy: ${invoice.buildyNumber}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Invoice items table card
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invoice Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  InvoiceTable(
                    columns: invoice.columns,
                    items: invoice.items,
                    currencySymbol: getCurrencySymbol(invoice.currency),
                    showActions: false,
                  ),
                ],
              ),
            ),

            // Summary section
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Summary',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Display total for Parcel and Kg columns
                    ...getNonTextColumns().map((col) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total $col:'),
                              Text(
                                '${getTotal(col)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:'),
                        Text(
                          // Calculate total from all item amounts in the table
                          '${getCurrencySymbol(invoice.currency)}${formatNumber(invoice.totalAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Freight Cost:'),
                        Text(
                          '${getCurrencySymbol(invoice.currency)}${formatNumber(invoice.freightCost)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Final Total:',
                            style: TextStyle(fontSize: 16)),
                        Text(
                          '${getCurrencySymbol(invoice.currency)}${formatNumber(invoice.totalAmount + invoice.freightCost)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (source == PreviewSource.dashboard) {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CreateInvoicePage(invoice: invoice),
                                ),
                              );
                            } else {
                              final scaffoldMessenger =
                                  ScaffoldMessenger.of(context);

                              try {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                      content: Text('Saving invoice...')),
                                );

                                final success =
                                    await InvoiceService.saveInvoice(invoice);

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
                                        content:
                                            Text('Error saving invoice: $e')),
                                  );
                                }
                              }
                            }
                          },
                          icon: Icon(
                            source == PreviewSource.dashboard
                                ? Icons.edit
                                : Icons.save,
                            color: Colors.white,
                          ),
                          label: Text(
                            source == PreviewSource.dashboard ? 'EDIT' : 'SAVE',
                            style: const TextStyle(color: Colors.white),
                          ),
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
                          onPressed: () => _showExportOptions(context, invoice),
                          icon: const Icon(Icons.file_download,
                              color: Colors.white),
                          label: const Text('EXPORT',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onSecondary,
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
            ),

            if (invoice.paymentMethods.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Methods',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ...invoice.paymentMethods.map((method) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(method),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
