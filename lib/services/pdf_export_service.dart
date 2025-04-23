import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import '../utils/currency.dart';

class PdfExportService {
  static Future<String?> exportInvoiceToPdf(Invoice invoice) async {
    try {
      final pdf = pw.Document();

      // Load font
      final font = await PdfGoogleFonts.nunitoRegular();
      final fontBold = await PdfGoogleFonts.nunitoBold();

      // Define styles
      final titleStyle = pw.TextStyle(font: fontBold, fontSize: 24);
      final headerStyle = pw.TextStyle(font: fontBold, fontSize: 16);
      final subheaderStyle = pw.TextStyle(font: fontBold, fontSize: 14);
      final bodyStyle = pw.TextStyle(font: font, fontSize: 12);
      final smallStyle =
          pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700);

      // Get currency symbol
      final currencySymbol = getCurrencySymbol(invoice.currency);

      // Create PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('ElakkaiTrack', style: titleStyle),
                pw.SizedBox(height: 4),
                pw.Text('Smart Spice Management', style: smallStyle),
                pw.Divider(),
              ],
            );
          },
          footer: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Divider(),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: smallStyle,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generated on ${_formatDate(DateTime.now())}',
                  style: smallStyle,
                ),
              ],
            );
          },
          build: (pw.Context context) {
            return [
              // Invoice header
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(invoice.title, style: headerStyle),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                                'Invoice Date: ${_formatDate(invoice.invoiceDate)}',
                                style: bodyStyle),
                            if (invoice.buildyNumber.isNotEmpty)
                              pw.Text('Buildy Number: ${invoice.buildyNumber}',
                                  style: bodyStyle),
                            // if (invoice.numberOfBags > 0)
                            //   pw.Text('Number of Bags: ${invoice.numberOfBags}',
                            //       style: bodyStyle),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('Invoice ID: ${invoice.id}',
                                style: bodyStyle),
                            if (invoice.numberOfBags > 0)
                              pw.Text('Number of Bags: ${invoice.numberOfBags}',
                                  style: bodyStyle),
                            // pw.Text(
                            //     'Created: ${_formatDate(invoice.createdAt)}',
                            //     style: bodyStyle),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Invoice items table
              pw.Header(
                  level: 1, text: 'Invoice Items', textStyle: subheaderStyle),
              pw.SizedBox(height: 8),
              _buildInvoiceTable(
                  invoice, currencySymbol, bodyStyle, headerStyle),

              pw.SizedBox(height: 20),

              // Summary section
              pw.Header(level: 1, text: 'Summary', textStyle: subheaderStyle),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  children: [
                    _buildSummaryRow(
                        'Total Amount:',
                        '$currencySymbol${formatNumber(invoice.totalAmount)}',
                        bodyStyle),
                    _buildSummaryRow(
                        'Freight Cost:',
                        '$currencySymbol${formatNumber(invoice.freightCost)}',
                        bodyStyle),
                    pw.Divider(),
                    _buildSummaryRow(
                        'Final Total:',
                        '$currencySymbol${formatNumber(invoice.finalTotal)}',
                        headerStyle),
                  ],
                ),
              ),

              // Payment methods section
              if (invoice.paymentMethods.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Header(
                    level: 1,
                    text: 'Payment Methods',
                    textStyle: subheaderStyle),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: invoice.paymentMethods.map((method) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Text('• $method', style: bodyStyle),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ];
          },
        ),
      );

      // Save the PDF file
      final directory = await getApplicationDocumentsDirectory();

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      String sanitizedTitle = invoice.title.isEmpty
          ? 'Invoice'
          : invoice.title.replaceAll(RegExp(r'[^\w\s.-]'), '_');
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath =
          '${directory.path}/invoice_${sanitizedTitle}_$timestamp.pdf';

      final File file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      print('Error generating PDF: $e');
      return null;
    }
  }

  // Helper method to build a summary row
  static pw.Widget _buildSummaryRow(
      String label, String value, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  // Helper method to build the invoice table
  static pw.Widget _buildInvoiceTable(Invoice invoice, String currencySymbol,
      pw.TextStyle bodyStyle, pw.TextStyle headerStyle) {
    // Create cell alignments map
    final cellAlignments = {
      for (int i = 0; i < invoice.columns.length; i++)
        i: i == invoice.columns.length - 1
            ? pw.Alignment.centerRight
            : pw.Alignment.centerLeft,
    };

    return pw.TableHelper.fromTextArray(
      border: null,
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.grey200,
      ),
      headerHeight: 30,
      cellHeight: 30,
      cellAlignments: cellAlignments,
      headerStyle: headerStyle,
      cellStyle: bodyStyle,
      headers: invoice.columns,
      data: invoice.items.map((item) {
        return invoice.columns.map((column) {
          var value = item.getValue(column);

          if (column == 'Amount') {
            if (value is double) {
              return '$currencySymbol${formatNumber(value)}';
            } else if (value is int) {
              return '$currencySymbol${formatNumber(value.toDouble())}';
            } else if (value is String && double.tryParse(value) != null) {
              return '$currencySymbol${formatNumber(double.parse(value))}';
            } else {
              return '$currencySymbol${value.toString()}';
            }
          } else if (column.toLowerCase().contains('date') &&
              value is DateTime) {
            return _formatDate(value);
          } else {
            return value.toString();
          }
        }).toList();
      }).toList(),
    );
  }

  // Helper method to format dates
  static String _formatDate(DateTime date) {
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    String year = date.year.toString();

    return '$day/$month/$year';
  }

  // Share PDF file
  static Future<void> sharePdfFile(String filePath) async {
    try {
      final file = XFile(filePath);
      await Share.shareXFiles(
        [file],
        subject: 'Invoice PDF Export',
        text: 'Here is your exported invoice as PDF.',
      );
    } catch (e) {
      print('Error sharing PDF: $e');
    }
  }

  // Print PDF file
  static Future<void> printPdf(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: 'Invoice',
      );
    } catch (e) {
      print('Error printing PDF: $e');
    }
  }
}
