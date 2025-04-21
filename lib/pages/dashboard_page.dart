import 'dart:async';
import 'package:flutter/material.dart';
import 'package:invoice_app/utils/currency.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import '../services/event_bus.dart';
import 'create_invoice_page.dart';
import 'invoice_preview_page.dart' show InvoicePreviewPage, PreviewSource;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.title});

  final String title;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  late StreamSubscription<AppEvent> _eventSubscription;

  @override
  void initState() {
    super.initState();
    _loadInvoices();

    _eventSubscription = eventBus.stream.listen((event) {
      if (event.type == EventType.invoiceSaved ||
          event.type == EventType.invoiceDeleted) {
        _loadInvoices();
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
    });

    final invoices = await InvoiceService.getInvoices();

    setState(() {
      _invoices = invoices;
      _isLoading = false;
    });
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Invoice'),
            content:
                Text('Are you sure you want to delete "${invoice.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('DELETE'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      setState(() {
        _isLoading = true;
      });

      final success = await InvoiceService.deleteInvoice(invoice.id);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice deleted successfully')),
          );
        }

        _loadInvoices();
      } else {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete invoice')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadInvoices(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Invoices',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: ${_invoices.length} ${_invoices.length == 1 ? 'invoice' : 'invoices'}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _invoices.isEmpty ? _buildEmptyState() : _buildInvoiceList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _invoices.isEmpty
          ? const SizedBox.shrink()
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateInvoicePage(),
                  ),
                ).then((_) => _loadInvoices());
              },
              icon: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              label: const Text('Create Invoice'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 4,
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: _isLoading
          ? const SizedBox.shrink()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No invoices yet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first invoice by tapping the button below',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateInvoicePage(),
                      ),
                    ).then((_) => _loadInvoices());
                  },
                  icon: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                  label: const Text('Create Invoice'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInvoiceList() {
    return ListView.builder(
      itemCount: _invoices.length,
      itemBuilder: (context, index) {
        final invoice = _invoices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InvoicePreviewPage(
                    invoice: invoice,
                    source: PreviewSource.dashboard,
                  ),
                ),
              ).then((_) => _loadInvoices());
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              invoice.createdAt.toString().substring(0, 10),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.receipt,
                                size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${invoice.items.length} ${invoice.items.length == 1 ? 'item' : 'items'}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${getCurrencySymbol(invoice.currency)}${formatNumber(invoice.finalTotal)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 22,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    tooltip: 'Delete Invoice',
                    onPressed: () => _deleteInvoice(invoice),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
