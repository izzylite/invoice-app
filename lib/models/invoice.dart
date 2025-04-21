import 'invoice_item.dart';
import '../pages/invoice_rows_page.dart' show Currency;

class Invoice {
  String id;
  String title;
  String buildyNumber;
  DateTime createdAt;
  List<String> columns;
  List<InvoiceItem> items;
  double freightCost;
  Currency currency;
  List<String> paymentMethods;

  Invoice({
    required this.id,
    required this.title,
    this.buildyNumber = '',
    required this.createdAt,
    required this.columns,
    required this.items,
    this.freightCost = 0.0,
    this.currency = Currency.rupee,
    this.paymentMethods = const [],
  });

  double get totalAmount {
    return _calculateTotalAmount(this);
  }

  double get finalTotal {
    return totalAmount + freightCost;
  }

// Helper method to calculate total amount from all items in the table
  double _calculateTotalAmount(Invoice invoice) {
    double total = 0.0;

    if (invoice.columns.contains('Amount')) {
      for (var item in invoice.items) {
        final amountValue = item.getValue('Amount');
        if (amountValue is double) {
          total += amountValue;
        } else if (amountValue is int) {
          total += amountValue.toDouble();
        } else if (amountValue is String) {
          total += double.tryParse(amountValue) ?? 0.0;
        }
      }
    } else {
      total = invoice.items.fold(0.0, (sum, item) => sum + item.amount);
    }

    return total;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'buildyNumber': buildyNumber,
      'createdAt': createdAt.toIso8601String(),
      'columns': columns,
      'items': items.map((item) => item.toJson()).toList(),
      'freightCost': freightCost,
      'currency': currency.toString().split('.').last,
      'paymentMethods': paymentMethods,
    };
  }

  // Helper method to parse currency from string
  static Currency _parseCurrency(String? currencyStr) {
    if (currencyStr == 'naira') {
      return Currency.naira;
    } else if (currencyStr == 'rupee') {
      return Currency.rupee;
    } else {
      return Currency.dollar;
    }
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      title: json['title'],
      buildyNumber: json['buildyNumber'],
      createdAt: DateTime.parse(json['createdAt']),
      columns: List<String>.from(json['columns']),
      items: (json['items'] as List)
          .map((item) => InvoiceItem.fromJson(item))
          .toList(),
      freightCost: json['freightCost'],
      currency: _parseCurrency(json['currency']),
      paymentMethods: List<String>.from(json['paymentMethods']),
    );
  }
}
