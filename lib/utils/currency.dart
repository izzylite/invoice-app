import 'package:invoice_app/pages/invoice_rows_page.dart';

getCurrencySymbol(Currency currency) {
  switch (currency) {
    case Currency.naira:
      return '₦';
    case Currency.dollar:
      return '\$';
    case Currency.rupee:
      return '₹';
  }
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
