class InvoiceItem {
  Map<String, dynamic> values;
  double amount;

  InvoiceItem({required this.values, required this.amount});

  dynamic getValue(String column) {
    return values[column];
  }

  void setValue(String column, dynamic value) {
    values[column] = value;
    if (column == 'Amount') {
      amount = value;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'values': values,
      'amount': amount,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      values: Map<String, dynamic>.from(json['values']),
      amount: json['amount'],
    );
  }
}
