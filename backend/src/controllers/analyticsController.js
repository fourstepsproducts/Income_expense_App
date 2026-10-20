const analyticsService = require('../services/analyticsService');
const { successResponse } = require('../utils/response');

class AnalyticsController {
  async getIncomeVsExpense(req, res, next) {
    try {
      const { period, startDate, endDate } = req.query;
      const data = await analyticsService.getIncomeVsExpense(req.user._id, {
        period,
        startDate,
        endDate
      });
      return successResponse(res, data, 'Income vs Expense data retrieved successfully');
    } catch (err) {
      next(err);
    }
  }

  async getExpenseCategories(req, res, next) {
    try {
      const { startDate, endDate } = req.query;
      const data = await analyticsService.getExpenseCategoryBreakdown(req.user._id, {
        startDate,
        endDate
      });
      return successResponse(res, data, 'Expense categories retrieved successfully');
    } catch (err) {
      next(err);
    }
  }

  async getCashFlow(req, res, next) {
    try {
      const { startDate, endDate } = req.query;
      const data = await analyticsService.getCashFlow(req.user._id, {
        startDate,
        endDate
      });
      return successResponse(res, data, 'Cash flow retrieved successfully');
    } catch (err) {
      next(err);
    }
  }

  async getMonthlyComparison(req, res, next) {
    try {
      const { year, month } = req.query;
      const data = await analyticsService.getMonthlyComparison(req.user._id, {
        year,
        month
      });
      return successResponse(res, data, 'Monthly comparison retrieved successfully');
    } catch (err) {
      next(err);
    }
  }

  async getTopExpenses(req, res, next) {
    try {
      const { limit, startDate, endDate } = req.query;
      const data = await analyticsService.getTopExpenses(req.user._id, {
        limit,
        startDate,
        endDate
      });
      return successResponse(res, data, 'Top expenses retrieved successfully');
    } catch (err) {
      next(err);
    }
  }

  async getDailySpending(req, res, next) {
    try {
      const { startDate, endDate } = req.query;
      const data = await analyticsService.getDailySpending(req.user._id, {
        startDate,
        endDate
      });
      return successResponse(res, data, 'Daily spending retrieved successfully');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new AnalyticsController();
