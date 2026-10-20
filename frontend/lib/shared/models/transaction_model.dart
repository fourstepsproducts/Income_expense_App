import 'category_model.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String type; // 'income' | 'expense'
  final double amount;
  final String categoryId;
  final CategoryModel? category;
  final DateTime date;
  final String paymentMethod;
  final String description;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.category,
    required this.date,
    this.paymentMethod = 'Cash',
    required this.description,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    CategoryModel? cat;
    String catId = '';

    if (json['categoryId'] is Map<String, dynamic>) {
      cat = CategoryModel.fromJson(json['categoryId']);
      catId = cat.id;
    } else if (json['categoryId'] is String) {
      catId = json['categoryId'];
    }

    return TransactionModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] is String ? json['userId'] : (json['userId']?['_id'] ?? ''),
      type: json['type'] ?? 'expense',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      categoryId: catId,
      category: cat,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      description: json['description'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'description': description,
      'notes': notes,
    };
  }
}
