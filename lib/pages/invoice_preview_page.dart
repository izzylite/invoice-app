import 'dart:async';
import 'package:flutter/material.dart';
import 'package:invoice_app/utils/currency.dart';
import '../models/invoice.dart';
import '../widgets/invoice_table.dart';
import '../services/export_service.dart';
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

  Future<void> _exportInvoice(BuildContext context, Invoice invoice) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting invoice...')),
    );

    try {
      final filePath = await ExportService.exportInvoiceToCSV(invoice);
      if (filePath != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Export successful! Opening share dialog...')),
        );

        await ExportService.shareCSVFile(filePath);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to export invoice. Please try again.')),
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
                    Text(
                      invoice.title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Date: ${invoice.createdAt.toString().substring(0, 10)}',
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
                          onPressed: () => _exportInvoice(context, invoice),
                          icon: const Icon(Icons.file_download,
                              color: Colors.white),
                          label: const Text('EXPORT CSV',
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
