import 'package:elakkaitrack/pages/invoice_rows_page.dart';

getCurrencySymbol(Currency currency, {bool replaceForExport = false}) {
  String cur;
  switch (currency) {
    case Currency.naira:
      cur = '₦';
      break;
    case Currency.dollar:
      cur = '\$';
      break;
    case Currency.rupee:
      cur = '₹';
      break;
  }
  if (replaceForExport) {
    cur = cur.replaceAll('₹', 'Rs.');
    cur = cur.replaceAll('₦', 'N');
  }
  return cur;
}

String formatNumber(dynamic value) {
  if (value == null) return '0.00';

  double numValue;
  if (value is int) {
    numValue = value.toDouble();
  } else if (value is double) {
    numValue = value;
  } else if (value is String) {
    numValue = double.tryParse(value) ?? 0.0;
  } else {
    return value.toString();
  }

  String formatted = numValue.toStringAsFixed(2);

  final parts = formatted.split('.');
  final wholePart = parts[0];
  final decimalPart = parts.length > 1 ? parts[1] : '00';

  final formattedWholePart = wholePart.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

  return '$formattedWholePart.$decimalPart';
}
