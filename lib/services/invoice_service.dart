import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice.dart';
import 'event_bus.dart';

class InvoiceService {
  static const String _storageKey = 'invoices';

  static Future<bool> saveInvoice(Invoice invoice) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final List<Invoice> invoices = await getInvoices();
      final existingIndex = invoices.indexWhere((inv) => inv.id == invoice.id);

      if (existingIndex >= 0) {
        invoices[existingIndex] = invoice;
      } else {
        invoices.add(invoice);
      }

      final jsonList = invoices.map((inv) => jsonEncode(inv.toJson())).toList();

      final result = await prefs.setStringList(_storageKey, jsonList);

      if (result) {
        eventBus.fire(AppEvent(EventType.invoiceSaved, invoice));
      }

      return result;
    } catch (e) {
      print('Error saving invoice: $e');
      return false;
    }
  }

  static Future<List<Invoice>> getInvoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final jsonList = prefs.getStringList(_storageKey) ?? [];

      return jsonList.map((jsonStr) {
        final Map<String, dynamic> json = jsonDecode(jsonStr);
        return Invoice.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error getting invoices: $e');
      return [];
    }
  }

  // Get a specific invoice by ID
  static Future<Invoice?> getInvoiceById(String id) async {
    try {
      final invoices = await getInvoices();
      return invoices.firstWhere((inv) => inv.id == id);
    } catch (e) {
      print('Error getting invoice by ID: $e');
      return null;
    }
  }

  static Future<bool> deleteInvoice(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Invoice> invoices = await getInvoices();

      invoices.removeWhere((inv) => inv.id == id);
      final jsonList = invoices.map((inv) => jsonEncode(inv.toJson())).toList();
      final result = await prefs.setStringList(_storageKey, jsonList);
      if (result) {
        eventBus.fire(AppEvent(EventType.invoiceDeleted, id));
      }

      return result;
    } catch (e) {
      print('Error deleting invoice: $e');
      return false;
    }
  }
}
