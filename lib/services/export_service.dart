import 'dart:io';
import 'package:csv/csv.dart';
import 'package:invoice_app/utils/currency.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice.dart';
import '../pages/invoice_rows_page.dart' show Currency;

class ExportService {
  static String _formatDate(DateTime date) {
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    String year = date.year.toString();

    return '$day/$month/$year';
  }

  static Future<String?> exportInvoiceToCSV(Invoice invoice) async {
    try {
      List<List<dynamic>> csvData = [];

      csvData.add(['Invoice:', invoice.title]);

      if (invoice.buildyNumber.isNotEmpty) {
        csvData.add(['Buildy Number:', invoice.buildyNumber]);
      }

      if (invoice.numberOfBags > 0) {
        csvData.add(['Number of Bags:', invoice.numberOfBags]);
      }

      String formattedDate = _formatDate(invoice.invoiceDate);
      csvData.add(['Date:', formattedDate]);

      // Add empty row before table
      csvData.add([]);

      csvData.add(invoice.columns);

      for (var item in invoice.items) {
        List<dynamic> row = [];
        for (var column in invoice.columns) {
          var value = item.getValue(column);

          if (column == 'Amount') {
            String currencySymbol = getCurrencySymbol(invoice.currency);

            if (value is double) {
              row.add('$currencySymbol${formatNumber(value)}');
            } else if (value is int) {
              row.add('$currencySymbol${formatNumber(value.toDouble())}');
            } else if (value is String && double.tryParse(value) != null) {
              row.add('$currencySymbol${formatNumber(double.parse(value))}');
            } else {
              row.add('$currencySymbol${value.toString()}');
            }
          } else if (column.toLowerCase().contains('date') &&
              value is DateTime) {
            // Format date values
            row.add(_formatDate(value));
          } else {
            row.add(value.toString());
          }
        }
        csvData.add(row);
      }

      // Add empty row
      csvData.add([]);

      String currencySymbol = getCurrencySymbol(invoice.currency);

      List<dynamic> totalRow =
          List<dynamic>.generate(invoice.columns.length - 1, (_) => '');
      totalRow.add('Total Amount:');
      totalRow.add('$currencySymbol${formatNumber(invoice.totalAmount)}');
      csvData.add(totalRow);

      List<dynamic> freightRow =
          List<dynamic>.generate(invoice.columns.length - 1, (_) => '');
      freightRow.add('Freight Cost:');
      freightRow.add('$currencySymbol${formatNumber(invoice.freightCost)}');
      csvData.add(freightRow);

      List<dynamic> finalRow =
          List<dynamic>.generate(invoice.columns.length - 1, (_) => '');
      finalRow.add('Final Total:');
      finalRow.add('$currencySymbol${formatNumber(invoice.finalTotal)}');
      csvData.add(finalRow);

      if (invoice.paymentMethods.isNotEmpty) {
        csvData.add([]);
        csvData.add(['Payment Methods:']);
        for (int i = 0; i < invoice.paymentMethods.length; i++) {
          csvData.add(['Method ${i + 1}:', invoice.paymentMethods[i]]);
        }
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      csv = _replaceCurrencySymbols(csv, invoice.currency);

      final directory = await getApplicationDocumentsDirectory();

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      String sanitizedTitle = invoice.title.isEmpty
          ? 'Invoice'
          : invoice.title.replaceAll(RegExp(r'[^\w\s.-]'), '_');
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath =
          '${directory.path}/invoice_${sanitizedTitle}_$timestamp.csv';

      final File file = File(filePath);
      await file.writeAsString(csv);

      return filePath;
    } catch (ignore) {
      // Handle error
      return null;
    }
  }

  // Share CSV file
  static Future<void> shareCSVFile(String filePath) async {
    try {
      final file = XFile(filePath);
      await Share.shareXFiles(
        [file],
        subject: 'Invoice Export',
        text: 'Here is your exported invoice.',
      );
    } catch (ignore) {
      // Handle error
    }
  }

  static String _replaceCurrencySymbols(String csv, Currency currency) {
    csv = csv.replaceAll('₹', 'Rs.');
    csv = csv.replaceAll('₦', 'N');

    return csv;
  }
}
