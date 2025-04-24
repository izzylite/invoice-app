import 'package:elakkaitrack/models/invoice.dart';

String generateFilename(String path, Invoice invoice, String extension,
    {int count = 0}) {
  String sanitizedTitle = invoice.title.isEmpty
      ? 'Invoice'
      : invoice.title.replaceAll(RegExp(r'[^\w\s.-]'), '_');

  // Use a safe date format without slashes for the filename
  String timestamp =
      "${invoice.invoiceDate.day.toString().padLeft(2, '0')}-${invoice.invoiceDate.month.toString().padLeft(2, '0')}-${invoice.invoiceDate.year}${count == 0 ? "" : "_$count"}";

  final String filePath = '$path/${sanitizedTitle}_$timestamp.$extension';
  return filePath;
}
