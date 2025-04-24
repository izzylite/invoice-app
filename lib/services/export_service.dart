import 'dart:io';
import 'package:csv/csv.dart';
import 'package:elakkaitrack/utils/currency.dart';
import 'package:elakkaitrack/utils/column_utils.dart';
import 'package:elakkaitrack/utils/export_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice.dart';

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

      // Add company information if available
      if (invoice.companyName.isNotEmpty) {
        csvData.add(['Company:', invoice.companyName]);
      }

      if (invoice.companySubtitle.isNotEmpty) {
        csvData.add(['', invoice.companySubtitle]);
      }
      if (invoice.companySubtitle.isNotEmpty) {
        csvData.add(['Contact No:', "+91 ${invoice.contactNumber}"]);
      }

      // Add a blank line after company info if either field is present
      if (invoice.companyName.isNotEmpty ||
          invoice.companySubtitle.isNotEmpty) {
        csvData.add([]);
      }

      csvData.add(['Customer:', invoice.title]);

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

      String currencySymbol =
          getCurrencySymbol(invoice.currency, replaceForExport: true);

      // Add total parcel and kg rows
      for (var col in getFilteredColumns(invoice.columns, ["Parcel", "Kg"])) {
        List<dynamic> colTotalRow =
            List<dynamic>.generate(invoice.columns.length - 1, (_) => '');
        colTotalRow.add('Total $col:');
        colTotalRow
            .add('${getColumnTotal(col, invoice.columns, invoice.items)}');
        csvData.add(colTotalRow);
      }

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

      try {
        var directory = await getDownloadsDirectory();
        directory ??= await getApplicationDocumentsDirectory();

        // Using directory for CSV
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        String filename = generateFilename(directory.path, invoice, "csv");

        File file = File(filename);
        int count = 1;
        while (await file.exists()) {
          filename =
              generateFilename(directory.path, invoice, "csv", count: count);
          file = File(filename);
          count++;
        }

        // Create parent directories if they don't exist
        if (!await file.parent.exists()) {
          await file.parent.create(recursive: true);
        }

        await file.writeAsString(csv);

        return file.path;
      } catch (dirError) {
        // Error with directory or file operations for CSV
        rethrow; // Re-throw to be caught by outer catch
      }
    } catch (e) {
      // Error generating CSV
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
    } catch (e) {
      // Error sharing CSV
    }
  }
}
