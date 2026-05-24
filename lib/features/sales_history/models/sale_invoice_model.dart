import 'package:cloud_firestore/cloud_firestore.dart';

class SaleInvoiceModel {
  final String id;
  final double totalAmount;
  final DateTime date;
  final List<dynamic> items;
  final String customerName;
  final String customerPhone;

  SaleInvoiceModel({
    required this.id,
    required this.totalAmount,
    required this.date,
    required this.items,
    this.customerName = '',
    this.customerPhone = '',
  });

  factory SaleInvoiceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SaleInvoiceModel(
      id: documentId,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null ? (map['date'] as Timestamp).toDate() : DateTime.now(),
      items: map['items'] as List<dynamic>? ?? [],
      customerName: map['customerName'] ?? 'Walk-in Customer',
      customerPhone: map['customerPhone'] ?? '',
    );
  }
}