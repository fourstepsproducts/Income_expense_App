const transactionService = require('../services/transactionService');
const { successResponse, paginatedResponse } = require('../utils/response');

class TransactionController {
  async getTransactions(req, res, next) {
    try {
      const { transactions, pagination, summary } = await transactionService.getTransactions(
        req.user._id,
        req.query
      );

      return res.status(200).json({
        success: true,
        message: 'Transactions retrieved successfully',
        data: transactions,
        pagination: {
          total: pagination.total,
          page: pagination.page,
          limit: pagination.limit,
          totalPages: Math.ceil(pagination.total / pagination.limit) || 1,
          hasNext: pagination.page < Math.ceil(pagination.total / pagination.limit),
          hasPrev: pagination.page > 1
        },
        summary
      });
    } catch (err) {
      next(err);
    }
  }

  async getTransactionById(req, res, next) {
    try {
      const transaction = await transactionService.getTransactionById(req.user._id, req.params.id);
      return successResponse(res, transaction, 'Transaction retrieved successfully');
    } catch (err) {
      next(err);
    }
  }

  async createTransaction(req, res, next) {
    try {
      const transaction = await transactionService.createTransaction(req.user._id, req.body);
      return successResponse(res, transaction, 'Transaction created successfully', 201);
    } catch (err) {
      next(err);
    }
  }

  async updateTransaction(req, res, next) {
    try {
      const transaction = await transactionService.updateTransaction(
        req.user._id,
        req.params.id,
        req.body
      );
      return successResponse(res, transaction, 'Transaction updated successfully');
    } catch (err) {
      next(err);
    }
  }

  async deleteTransaction(req, res, next) {
    try {
      const result = await transactionService.deleteTransaction(req.user._id, req.params.id);
      return successResponse(res, result, 'Transaction deleted successfully');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new TransactionController();
