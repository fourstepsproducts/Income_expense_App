import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/custom_button.dart';
import '../../shared/models/transaction_model.dart';
import '../../shared/providers.dart';

class TransactionEntryScreen extends ConsumerStatefulWidget {
  final TransactionModel? transactionToEdit;

  const TransactionEntryScreen({
    super.key,
    this.transactionToEdit,
  });

  @override
  ConsumerState<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends ConsumerState<TransactionEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _type; // 'expense' or 'income'
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedCategoryId;
  String _selectedPaymentMethod = 'Cash';

  bool _isSubmitting = false;
  bool _isDeleting = false;

  bool get isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transactionToEdit;

    _type = tx?.type ?? 'expense';
    _amountController = TextEditingController(text: tx != null ? tx.amount.toString() : '');
    _descriptionController = TextEditingController(text: tx?.description ?? '');
    _notesController = TextEditingController(text: tx?.notes ?? '');
    _selectedDate = tx?.date ?? DateTime.now();
    _selectedTime = tx != null ? TimeOfDay.fromDateTime(tx.date) : TimeOfDay.now();
    _selectedCategoryId = tx?.categoryId;
    _selectedPaymentMethod = tx?.paymentMethod ?? 'Cash';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
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
      setState(() => _selectedTime = picked);
    }
  }

  DateTime _getCombinedDateTime() {
    final time = _selectedTime ?? TimeOfDay.now();
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _save() async {
    if (_isSubmitting) return; // Prevent duplicate taps

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than 0'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final txService = ref.read(transactionServiceProvider);

    try {
      final combinedDate = _getCombinedDateTime();

      if (isEditing) {
        await txService.updateTransaction(
          widget.transactionToEdit!.id,
          type: _type,
          amount: amount,
          categoryId: _selectedCategoryId,
          date: combinedDate,
          paymentMethod: _selectedPaymentMethod,
          description: _descriptionController.text.trim(),
          notes: _notesController.text.trim(),
        );
      } else {
        await txService.createTransaction(
          type: _type,
          amount: amount,
          categoryId: _selectedCategoryId!,
          date: combinedDate,
          paymentMethod: _selectedPaymentMethod,
          description: _descriptionController.text.trim(),
          notes: _notesController.text.trim(),
        );
      }

      // Invalidate relevant providers to update dashboard and lists
      ref.invalidate(dashboardSummaryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Transaction updated successfully' : 'Transaction saved!'),
            backgroundColor: AppColors.incomeGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.expenseRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Transaction?',
      message: 'Are you sure you want to delete this transaction? This action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: AppColors.expenseRed,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await ref.read(transactionServiceProvider).deleteTransaction(widget.transactionToEdit!.id);
      ref.invalidate(dashboardSummaryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            backgroundColor: AppColors.info,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final currency = ref.watch(currencyProvider);
    final isIncome = _type == 'income';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (isEditing)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.expenseRed),
                    )
                  : const Icon(Icons.delete_outline_rounded, color: AppColors.expenseRed),
              tooltip: 'Delete',
              onPressed: _isDeleting || _isSubmitting ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type Selector (Income vs Expense)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_type != 'expense') {
                              setState(() {
                                _type = 'expense';
                                _selectedCategoryId = null; // reset category on type switch
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isIncome ? AppColors.expenseRed : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 18,
                                  color: !isIncome ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Expense',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: !isIncome ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_type != 'income') {
                              setState(() {
                                _type = 'income';
                                _selectedCategoryId = null;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isIncome ? AppColors.incomeGreen : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 18,
                                  color: isIncome ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Income',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: isIncome ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount ($currency)',
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        AppConstants.currencySymbols[currency] ?? '$currency ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
                        ),
                      ),
                    ),
                    hintText: '0.00',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter amount';
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null || parsed <= 0) return 'Must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Category Selector
                categoriesAsync.when(
                  loading: () => const LinearProgressIndicator(color: AppColors.vibrantBlue),
                  error: (e, _) => Text('Error loading categories: $e', style: const TextStyle(color: AppColors.expenseRed)),
                  data: (allCategories) {
                    final filteredCategories = allCategories.where((c) => c.type == _type).toList();

                    // Auto-select first if none selected
                    if (_selectedCategoryId == null && filteredCategories.isNotEmpty) {
                      _selectedCategoryId = filteredCategories.first.id;
                    }

                    return DropdownButtonFormField<String>(
                      value: filteredCategories.any((c) => c.id == _selectedCategoryId)
                          ? _selectedCategoryId
                          : (filteredCategories.isNotEmpty ? filteredCategories.first.id : null),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined, color: AppColors.textSecondary),
                      ),
                      dropdownColor: AppColors.surfaceElevated,
                      items: filteredCategories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: cat.parsedColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(cat.iconData, size: 16, color: cat.parsedColor),
                              ),
                              const SizedBox(width: 10),
                              Text(cat.name, style: const TextStyle(color: AppColors.textPrimary)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategoryId = val);
                      },
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.edit_note_rounded, color: AppColors.textSecondary),
                    hintText: 'e.g. Grocery restock, Monthly bonus',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Description is required';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Date & Time Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormatter.formatShort(_selectedDate),
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedTime != null
                                      ? _selectedTime!.format(context)
                                      : 'Time',
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Payment Method
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.payment_rounded, color: AppColors.textSecondary),
                  ),
                  dropdownColor: AppColors.surfaceElevated,
                  items: AppConstants.paymentMethods.map((method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(method, style: const TextStyle(color: AppColors.textPrimary)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPaymentMethod = val);
                  },
                ),
                const SizedBox(height: 18),

                // Optional Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    prefixIcon: Icon(Icons.notes_rounded, color: AppColors.textSecondary),
                    hintText: 'Additional details or memo...',
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                CustomButton(
                  text: isEditing ? 'Update Transaction' : 'Save Transaction',
                  isLoading: _isSubmitting,
                  backgroundColor: isIncome ? AppColors.incomeGreen : AppColors.primaryBlue,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
