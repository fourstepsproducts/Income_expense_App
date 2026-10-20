const Transaction = require('../models/Transaction');
const Category = require('../models/Category');
const { parseDateRange } = require('../utils/dateUtils');

class TransactionService {
  async createTransaction(userId, { type, amount, categoryId, date, paymentMethod, description, notes }) {
    // Validate that category exists and is accessible
    const category = await Category.findOne({
      _id: categoryId,
      $or: [{ userId: null }, { userId }]
    });

    if (!category) {
      const error = new Error('Selected category does not exist or is invalid');
      error.statusCode = 400;
      throw error;
    }

    // Ensure category type matches transaction type
    if (category.type !== type) {
      const error = new Error(`Category "${category.name}" is of type "${category.type}", but transaction type is "${type}"`);
      error.statusCode = 400;
      throw error;
    }

    const transaction = await Transaction.create({
      userId,
      type,
      amount: parseFloat(amount),
      categoryId,
      date: new Date(date),
      paymentMethod: paymentMethod || 'Cash',
      description: description.trim(),
      notes: notes ? notes.trim() : ''
    });

    return Transaction.findById(transaction._id).populate('categoryId', 'name type icon color');
  }

  async getTransactions(userId, query = {}) {
    const page = parseInt(query.page, 10) || 1;
    const limit = parseInt(query.limit, 10) || 20;
    const skip = (page - 1) * limit;

    const filter = { userId };

    if (query.type) {
      filter.type = query.type;
    }

    if (query.categoryId) {
      filter.categoryId = query.categoryId;
    }

    if (query.paymentMethod) {
      filter.paymentMethod = query.paymentMethod;
    }

    // Date range
    const { start, end } = parseDateRange(query.startDate, query.endDate);
    if (start || end) {
      filter.date = {};
      if (start) filter.date.$gte = start;
      if (end) filter.date.$lte = end;
    }

    // Search
    if (query.search && query.search.trim()) {
      const searchRegex = new RegExp(query.search.trim(), 'i');
      filter.$or = [
        { description: searchRegex },
        { notes: searchRegex }
      ];
    }

    // Sorting
    const sortField = query.sortBy === 'amount' ? 'amount' : 'date';
    const sortDirection = query.sortOrder === 'asc' ? 1 : -1;
    const sort = { [sortField]: sortDirection };
    if (sortField !== 'date') {
      sort.date = -1;
    }

    const [transactions, total, summaryAgg] = await Promise.all([
      Transaction.find(filter)
        .populate('categoryId', 'name type icon color')
        .sort(sort)
        .skip(skip)
        .limit(limit)
        .lean(),
      Transaction.countDocuments(filter),
      Transaction.aggregate([
        { $match: filter },
        {
          $group: {
            _id: '$type',
            totalAmount: { $sum: '$amount' },
            count: { $sum: 1 }
          }
        }
      ])
    ]);

    let totalIncome = 0;
    let totalExpense = 0;
    summaryAgg.forEach((item) => {
      if (item._id === 'income') totalIncome = item.totalAmount;
      if (item._id === 'expense') totalExpense = item.totalAmount;
    });

    return {
      transactions,
      pagination: {
        total,
        page,
        limit
      },
      summary: {
        totalIncome: Math.round(totalIncome * 100) / 100,
        totalExpense: Math.round(totalExpense * 100) / 100,
        netBalance: Math.round((totalIncome - totalExpense) * 100) / 100
      }
    };
  }

  async getTransactionById(userId, transactionId) {
    const transaction = await Transaction.findOne({ _id: transactionId, userId })
      .populate('categoryId', 'name type icon color');

    if (!transaction) {
      const error = new Error('Transaction not found');
      error.statusCode = 404;
      throw error;
    }

    return transaction;
  }

  async updateTransaction(userId, transactionId, data) {
    const transaction = await Transaction.findOne({ _id: transactionId, userId });

    if (!transaction) {
      const error = new Error('Transaction not found');
      error.statusCode = 404;
      throw error;
    }

    if (data.categoryId) {
      const category = await Category.findOne({
        _id: data.categoryId,
        $or: [{ userId: null }, { userId }]
      });

      if (!category) {
        const error = new Error('Category not found');
        error.statusCode = 400;
        throw error;
      }

      const targetType = data.type || transaction.type;
      if (category.type !== targetType) {
        const error = new Error(`Category "${category.name}" is not compatible with transaction type "${targetType}"`);
        error.statusCode = 400;
        throw error;
      }
      transaction.categoryId = data.categoryId;
    }

    if (data.type) transaction.type = data.type;
    if (data.amount !== undefined) transaction.amount = parseFloat(data.amount);
    if (data.date) transaction.date = new Date(data.date);
    if (data.paymentMethod) transaction.paymentMethod = data.paymentMethod;
    if (data.description !== undefined) transaction.description = data.description.trim();
    if (data.notes !== undefined) transaction.notes = data.notes.trim();

    await transaction.save();
    return Transaction.findById(transaction._id).populate('categoryId', 'name type icon color');
  }

  async deleteTransaction(userId, transactionId) {
    const transaction = await Transaction.findOneAndDelete({ _id: transactionId, userId });

    if (!transaction) {
      const error = new Error('Transaction not found');
      error.statusCode = 404;
      throw error;
    }

    return { id: transactionId, deleted: true };
  }
}

module.exports = new TransactionService();
