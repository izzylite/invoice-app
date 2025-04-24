import '../models/column_definition.dart';

/// Utility functions for column operations

List<String> getFilteredColumns(
    List<String> columns, List<String> filterColumns) {
  return columns.where((col) => filterColumns.contains(col)).toList();
}

int getColumnTotal(String column, List<String> columns, List<dynamic> items) {
  if (columns.contains(column)) {
    double total = items.fold(0.0, (sum, item) {
      var value = item.getValue(column);
      if (value is num) {
        return sum + value;
      }
      return sum;
    });
    return total.round();
  }
  return 0;
}
