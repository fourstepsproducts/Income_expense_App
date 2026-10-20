import '../../core/network/api_client.dart';
import '../models/transaction_model.dart';

class TransactionResult {
  final List<TransactionModel> transactions;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNext;
  final double summaryIncome;
  final double summaryExpense;
  final double summaryNet;

  TransactionResult({
    required this.transactions,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNext,
    required this.summaryIncome,
    required this.summaryExpense,
    required this.summaryNet,
  });
}

class TransactionService {
  final ApiClient _client;

  TransactionService(this._client);

  Future<TransactionResult> getTransactions({
    int page = 1,
    int limit = 20,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
    String sortBy = 'date',
    String sortOrder = 'desc',
    String? search,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    if (type != null && type.isNotEmpty && type != 'all') {
      query['type'] = type;
    }
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      query['categoryId'] = categoryId;
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty && paymentMethod != 'all') {
      query['paymentMethod'] = paymentMethod;
    }
    if (startDate != null) {
      query['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      query['endDate'] = endDate.toIso8601String();
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final response = await _client.get('/transactions', queryParams: query);
    final list = (response['data'] as List? ?? [])
        .map((item) => TransactionModel.fromJson(item))
        .toList();

    final pagination = response['pagination'] ?? {};
    final summary = response['summary'] ?? {};

    return TransactionResult(
      transactions: list,
      total: pagination['total'] ?? 0,
      page: pagination['page'] ?? 1,
      limit: pagination['limit'] ?? 20,
      totalPages: pagination['totalPages'] ?? 1,
      hasNext: pagination['hasNext'] ?? false,
      summaryIncome: (summary['totalIncome'] as num?)?.toDouble() ?? 0.0,
      summaryExpense: (summary['totalExpense'] as num?)?.toDouble() ?? 0.0,
      summaryNet: (summary['netBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Future<TransactionModel> getTransactionById(String id) async {
    final response = await _client.get('/transactions/$id');
    return TransactionModel.fromJson(response['data']);
  }

  Future<TransactionModel> createTransaction({
    required String type,
    required double amount,
    required String categoryId,
    required DateTime date,
    String paymentMethod = 'Cash',
    required String description,
    String notes = '',
  }) async {
    final response = await _client.post('/transactions', body: {
      'type': type,
      'amount': amount,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'description': description.trim(),
      'notes': notes.trim(),
    });

    return TransactionModel.fromJson(response['data']);
  }

  Future<TransactionModel> updateTransaction(
    String id, {
    String? type,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? paymentMethod,
    String? description,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (type != null) body['type'] = type;
    if (amount != null) body['amount'] = amount;
    if (categoryId != null) body['categoryId'] = categoryId;
    if (date != null) body['date'] = date.toIso8601String();
    if (paymentMethod != null) body['paymentMethod'] = paymentMethod;
    if (description != null) body['description'] = description.trim();
    if (notes != null) body['notes'] = notes.trim();
    final response = await _client.put('/transactions/$id', body: body);

    return TransactionModel.fromJson(response['data']);
  }

  Future<void> deleteTransaction(String id) async {
    await _client.delete('/transactions/$id');
  }
}
