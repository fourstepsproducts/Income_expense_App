import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../shared/models/category_model.dart';
import '../../shared/models/transaction_model.dart';
import '../../shared/providers.dart';
import 'transaction_entry_screen.dart';

class TransactionsHistoryScreen extends ConsumerStatefulWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  ConsumerState<TransactionsHistoryScreen> createState() => _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState extends ConsumerState<TransactionsHistoryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  // Filters
  String _selectedType = 'all'; // 'all', 'income', 'expense'
  String? _selectedCategoryId;
  String? _selectedPaymentMethod;
  DateTimeRange? _selectedDateRange;
  String _sortBy = 'date';
  String _sortOrder = 'desc';

  // Pagination & Data State
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasNext = false;

  // Monthly Summary
  double _summaryIncome = 0.0;
  double _summaryExpense = 0.0;
  double _summaryNet = 0.0;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchTransactions(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasNext) {
      _fetchTransactions(reset: false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchTransactions(reset: true);
    });
  }

  Future<void> _fetchTransactions({required bool reset}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _errorMessage = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final pageToFetch = reset ? 1 : _currentPage + 1;
      final txService = ref.read(transactionServiceProvider);

      final result = await txService.getTransactions(
        page: pageToFetch,
        limit: 20,
        type: _selectedType != 'all' ? _selectedType : null,
        categoryId: _selectedCategoryId,
        paymentMethod: _selectedPaymentMethod,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        search: _searchController.text.trim(),
      );

      setState(() {
        if (reset) {
          _transactions = result.transactions;
        } else {
          _transactions.addAll(result.transactions);
        }
        _currentPage = result.page;
        _hasNext = result.hasNext;
        _summaryIncome = result.summaryIncome;
        _summaryExpense = result.summaryExpense;
        _summaryNet = result.summaryNet;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _openFilterDialog() {
    final categoriesAsync = ref.read(categoriesProvider);
    final List<CategoryModel> categories = categoriesAsync.value ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter & Sort',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCategoryId = null;
                            _selectedPaymentMethod = null;
                            _selectedDateRange = null;
                            _sortBy = 'date';
                            _sortOrder = 'desc';
                          });
                        },
                        child: const Text('Reset', style: TextStyle(color: AppColors.vibrantBlue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sort By
                  const Text('Sort By', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChip(
                        label: 'Date (Newest)',
                        isSelected: _sortBy == 'date' && _sortOrder == 'desc',
                        onTap: () => setModalState(() {
                          _sortBy = 'date';
                          _sortOrder = 'desc';
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        label: 'Date (Oldest)',
                        isSelected: _sortBy == 'date' && _sortOrder == 'asc',
                        onTap: () => setModalState(() {
                          _sortBy = 'date';
                          _sortOrder = 'asc';
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        label: 'Amount (High)',
                        isSelected: _sortBy == 'amount' && _sortOrder == 'desc',
                        onTap: () => setModalState(() {
                          _sortBy = 'amount';
                          _sortOrder = 'desc';
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date Range
                  const Text('Date Range', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDateRange: _selectedDateRange,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.vibrantBlue,
                                surface: AppColors.surfaceElevated,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() => _selectedDateRange = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDateRange != null
                                ? '${DateFormatter.formatShort(_selectedDateRange!.start)} - ${DateFormatter.formatShort(_selectedDateRange!.end)}'
                                : 'All Dates (Tap to select)',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          ),
                          const Icon(Icons.date_range_rounded, size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Filter
                  const Text('Category', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    dropdownColor: AppColors.surfaceElevated,
                    hint: const Text('All Categories', style: TextStyle(color: AppColors.textSecondary)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (val) => setModalState(() => _selectedCategoryId = val),
                  ),
                  const SizedBox(height: 16),

                  // Payment Method
                  const Text('Payment Method', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _selectedPaymentMethod,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    dropdownColor: AppColors.surfaceElevated,
                    hint: const Text('All Payment Methods', style: TextStyle(color: AppColors.textSecondary)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Methods')),
                      ...AppConstants.paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                    ],
                    onChanged: (val) => setModalState(() => _selectedPaymentMethod = val),
                  ),
                  const SizedBox(height: 24),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _fetchTransactions(reset: true);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.vibrantBlue : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.vibrantBlue : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: AppColors.textPrimary),
            tooltip: 'Filter & Sort',
            onPressed: _openFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Type Tabs Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search description or notes...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchTransactions(reset: true);
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                // Type Toggle Chips (All, Expense, Income)
                Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Expenses', 'expense', color: AppColors.expenseRed),
                    const SizedBox(width: 8),
                    _buildFilterChip('Income', 'income', color: AppColors.incomeGreen),
                  ],
                ),
              ],
            ),
          ),

          // Monthly Summary Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surfaceElevated,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Income', _summaryIncome, AppColors.incomeGreen, currency),
                  Container(height: 28, width: 1, color: AppColors.border),
                  _buildSummaryItem('Expense', _summaryExpense, AppColors.expenseRed, currency),
                  Container(height: 28, width: 1, color: AppColors.border),
                  _buildSummaryItem('Net', _summaryNet, _summaryNet >= 0 ? AppColors.accentCyan : AppColors.expenseRed, currency),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Transaction List or States
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.vibrantBlue))
                : _errorMessage != null
                    ? ErrorView(
                        message: _errorMessage!,
                        onRetry: () => _fetchTransactions(reset: true),
                      )
                    : _transactions.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long_rounded,
                            title: 'No Transactions Found',
                            message: 'Try adjusting your filters, search keywords, or add new transactions.',
                          )
                        : RefreshIndicator(
                            color: AppColors.vibrantBlue,
                            backgroundColor: AppColors.surface,
                            onRefresh: () => _fetchTransactions(reset: true),
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                              itemCount: _transactions.length + (_isLoadingMore ? 1 : 0),
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                if (index == _transactions.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.vibrantBlue,
                                      ),
                                    ),
                                  );
                                }

                                final tx = _transactions[index];
                                return _buildTransactionCard(tx, currency);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color, String currency) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 3),
        Text(
          CurrencyFormatter.formatCompact(amount, currency: currency),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, {Color? color}) {
    final isSelected = _selectedType == value;
    final activeColor = color ?? AppColors.vibrantBlue;

    return GestureDetector(
      onTap: () {
        if (_selectedType != value) {
          setState(() => _selectedType = value);
          _fetchTransactions(reset: true);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.18) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx, String currency) {
    final isIncome = tx.isIncome;
    final cat = tx.category;
    final catColor = cat?.parsedColor ?? (isIncome ? AppColors.incomeGreen : AppColors.expenseRed);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () async {
        final updated = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionEntryScreen(transactionToEdit: tx),
          ),
        );
        if (updated == true) {
          _fetchTransactions(reset: true);
        }
      },
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              cat?.iconData ?? (isIncome ? Icons.work : Icons.shopping_bag),
              color: catColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      cat?.name ?? (isIncome ? 'Income' : 'Expense'),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    const SizedBox(width: 6),
                    Text(
                      tx.paymentMethod,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.formatFull(tx.date),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amount, currency: currency)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
                ),
              ),
              const SizedBox(height: 6),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}
