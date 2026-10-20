const mongoose = require('mongoose');
const Transaction = require('../models/Transaction');
const { getStartAndEndOfDay, getStartAndEndOfMonth, getPreviousMonthRange, parseDateRange } = require('../utils/dateUtils');

class AnalyticsService {
  /**
   * Main Dashboard Summary
   */
  async getDashboardSummary(userId, timezoneOffsetMinutes = 0) {
    const userObjId = new mongoose.Types.ObjectId(userId);
    const now = new Date();

    // Adjust for client timezone if provided
    const localNow = new Date(now.getTime() - timezoneOffsetMinutes * 60000);
    const today = getStartAndEndOfDay(localNow);

    const currentYear = localNow.getUTCFullYear();
    const currentMonth = localNow.getUTCMonth();
    const currentMonthRange = getStartAndEndOfMonth(currentYear, currentMonth);
    const prevMonthRange = getPreviousMonthRange(currentMonthRange.start);

    const [
      overallAgg,
      todayAgg,
      currentMonthAgg,
      prevMonthAgg,
      recentTransactions
    ] = await Promise.all([
      // Overall totals
      Transaction.aggregate([
        { $match: { userId: userObjId } },
        {
          $group: {
            _id: '$type',
            total: { $sum: '$amount' },
            count: { $sum: 1 }
          }
        }
      ]),

      // Today's totals
      Transaction.aggregate([
        {
          $match: {
            userId: userObjId,
            date: { $gte: today.start, $lte: today.end }
          }
        },
        {
          $group: {
            _id: '$type',
            total: { $sum: '$amount' }
          }
        }
      ]),

      // Current month's totals
      Transaction.aggregate([
        {
          $match: {
            userId: userObjId,
            date: { $gte: currentMonthRange.start, $lte: currentMonthRange.end }
          }
        },
        {
          $group: {
            _id: '$type',
            total: { $sum: '$amount' }
          }
        }
      ]),

      // Previous month's totals for comparison
      Transaction.aggregate([
        {
          $match: {
            userId: userObjId,
            date: { $gte: prevMonthRange.start, $lte: prevMonthRange.end }
          }
        },
        {
          $group: {
            _id: '$type',
            total: { $sum: '$amount' }
          }
        }
      ]),

      // Recent 5 transactions
      Transaction.find({ userId: userObjId })
        .populate('categoryId', 'name type icon color')
        .sort({ date: -1, createdAt: -1 })
        .limit(5)
        .lean()
    ]);

    // Parse aggregates
    let totalIncome = 0;
    let totalExpense = 0;
    overallAgg.forEach((item) => {
      if (item._id === 'income') totalIncome = item.total;
      if (item._id === 'expense') totalExpense = item.total;
    });

    let todayIncome = 0;
    let todayExpense = 0;
    todayAgg.forEach((item) => {
      if (item._id === 'income') todayIncome = item.total;
      if (item._id === 'expense') todayExpense = item.total;
    });

    let currentMonthIncome = 0;
    let currentMonthExpense = 0;
    currentMonthAgg.forEach((item) => {
      if (item._id === 'income') currentMonthIncome = item.total;
      if (item._id === 'expense') currentMonthExpense = item.total;
    });

    let prevMonthExpense = 0;
    prevMonthAgg.forEach((item) => {
      if (item._id === 'expense') prevMonthExpense = item.total;
    });

    const netBalance = Math.round((totalIncome - totalExpense) * 100) / 100;
    const currentMonthNet = Math.round((currentMonthIncome - currentMonthExpense) * 100) / 100;

    // Savings rate: (net income / total income) * 100 when total income > 0
    let savingsRate = 0;
    if (totalIncome > 0) {
      savingsRate = Math.round((netBalance / totalIncome) * 10000) / 100;
    }

    // Expense trend compared to previous month
    let expenseChangePercentage = 0;
    let expenseTrend = 'neutral';
    if (prevMonthExpense > 0) {
      const diff = currentMonthExpense - prevMonthExpense;
      expenseChangePercentage = Math.round((diff / prevMonthExpense) * 10000) / 100;
      if (diff > 0) expenseTrend = 'increasing';
      else if (diff < 0) expenseTrend = 'decreasing';
    } else if (currentMonthExpense > 0) {
      expenseChangePercentage = 100;
      expenseTrend = 'increasing';
    }

    return {
      totals: {
        totalIncome: Math.round(totalIncome * 100) / 100,
        totalExpense: Math.round(totalExpense * 100) / 100,
        netBalance,
        savingsRate
      },
      today: {
        income: Math.round(todayIncome * 100) / 100,
        expense: Math.round(todayExpense * 100) / 100
      },
      currentMonth: {
        year: currentYear,
        month: currentMonth + 1,
        income: Math.round(currentMonthIncome * 100) / 100,
        expense: Math.round(currentMonthExpense * 100) / 100,
        net: currentMonthNet
      },
      previousMonth: {
        expense: Math.round(prevMonthExpense * 100) / 100
      },
      expenseComparison: {
        trend: expenseTrend,
        changePercentage: Math.abs(expenseChangePercentage),
        isIncrease: expenseChangePercentage > 0,
        previousMonthExpense: Math.round(prevMonthExpense * 100) / 100
      },
      recentTransactions
    };
  }

  /**
   * Grouped Income vs Expense for Bar Charts (daily, weekly, monthly, yearly)
   */
  async getIncomeVsExpense(userId, { period = 'month', startDate, endDate }) {
    const userObjId = new mongoose.Types.ObjectId(userId);
    const { start, end } = parseDateRange(startDate, endDate);

    const match = { userId: userObjId };
    if (start || end) {
      match.date = {};
      if (start) match.date.$gte = start;
      if (end) match.date.$lte = end;
    } else {
      // Default to last 6 months if not specified
      const sixMonthsAgo = new Date();
      sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 5);
      sixMonthsAgo.setDate(1);
      sixMonthsAgo.setHours(0, 0, 0, 0);
      match.date = { $gte: sixMonthsAgo };
    }

    let dateGrouping;
    let sortFormat;

    switch (period) {
      case 'day':
        dateGrouping = { $dateToString: { format: '%Y-%m-%d', date: '$date' } };
        sortFormat = 1;
        break;
      case 'week':
        dateGrouping = {
          $concat: [
            { $toString: { $isoWeekYear: '$date' } },
            '-W',
            {
              $cond: [
                { $lt: [{ $isoWeek: '$date' }, 10] },
                { $concat: ['0', { $toString: { $isoWeek: '$date' } }] },
                { $toString: { $isoWeek: '$date' } }
              ]
            }
          ]
        };
        sortFormat = 1;
        break;
      case 'year':
        dateGrouping = { $dateToString: { format: '%Y', date: '$date' } };
        sortFormat = 1;
        break;
      case 'month':
      default:
        dateGrouping = { $dateToString: { format: '%Y-%m', date: '$date' } };
        sortFormat = 1;
        break;
    }

    const results = await Transaction.aggregate([
      { $match: match },
      {
        $group: {
          _id: {
            period: dateGrouping,
            type: '$type'
          },
          total: { $sum: '$amount' }
        }
      },
      {
        $group: {
          _id: '$_id.period',
          income: {
            $sum: {
              $cond: [{ $eq: ['$_id.type', 'income'] }, '$total', 0]
            }
          },
          expense: {
            $sum: {
              $cond: [{ $eq: ['$_id.type', 'expense'] }, '$total', 0]
            }
          }
        }
      },
      {
        $project: {
          _id: 0,
          period: '$_id',
          income: { $round: ['$income', 2] },
          expense: { $round: ['$expense', 2] },
          net: { $round: [{ $subtract: ['$income', '$expense'] }, 2] }
        }
      },
      { $sort: { period: sortFormat } }
    ]);

    return results;
  }

  /**
   * Expense Category Breakdown (for Doughnut/Pie Charts)
   */
  async getExpenseCategoryBreakdown(userId, { startDate, endDate }) {
    const userObjId = new mongoose.Types.ObjectId(userId);
    const { start, end } = parseDateRange(startDate, endDate);

    const match = { userId: userObjId, type: 'expense' };
    if (start || end) {
      match.date = {};
      if (start) match.date.$gte = start;
      if (end) match.date.$lte = end;
    }

    const results = await Transaction.aggregate([
      { $match: match },
      {
        $group: {
          _id: '$categoryId',
          totalAmount: { $sum: '$amount' },
          transactionCount: { $sum: 1 }
        }
      },
      {
        $lookup: {
          from: 'categories',
          localField: '_id',
          foreignField: '_id',
          as: 'category'
        }
      },
      { $unwind: '$category' },
      {
        $project: {
          _id: 0,
          categoryId: '$_id',
          name: '$category.name',
          icon: '$category.icon',
          color: '$category.color',
          totalAmount: { $round: ['$totalAmount', 2] },
          transactionCount: 1
        }
      },
      { $sort: { totalAmount: -1 } }
    ]);

    const totalExpense = results.reduce((acc, curr) => acc + curr.totalAmount, 0);

    const formatted = results.map((item) => ({
      ...item,
      percentage: totalExpense > 0 ? Math.round((item.totalAmount / totalExpense) * 10000) / 100 : 0
    }));

    return {
      totalExpense: Math.round(totalExpense * 100) / 100,
      breakdown: formatted
    };
  }

  /**
   * Cash Flow Over Time (Line Chart)
   */
  async getCashFlow(userId, { startDate, endDate }) {
    const userObjId = new mongoose.Types.ObjectId(userId);
    const { start, end } = parseDateRange(startDate, endDate);

    const match = { userId: userObjId };
    if (start || end) {
      match.date = {};
      if (start) match.date.$gte = start;
      if (end) match.date.$lte = end;
    } else {
      // Default to last 30 days
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      match.date = { $gte: thirtyDaysAgo };
    }

    const raw = await Transaction.aggregate([
      { $match: match },
      {
        $group: {
          _id: {
            dateStr: { $dateToString: { format: '%Y-%m-%d', date: '$date' } },
            type: '$type'
          },
          total: { $sum: '$amount' }
        }
      },
      {
        $group: {
          _id: '$_id.dateStr',
          income: {
            $sum: { $cond: [{ $eq: ['$_id.type', 'income'] }, '$total', 0] }
          },
          expense: {
            $sum: { $cond: [{ $eq: ['$_id.type', 'expense'] }, '$total', 0] }
          }
        }
      },
      {
        $project: {
          _id: 0,
          date: '$_id',
          income: { $round: ['$income', 2] },
          expense: { $round: ['$expense', 2] },
          net: { $round: [{ $subtract: ['$income', '$expense'] }, 2] }
        }
      },
      { $sort: { date: 1 } }
    ]);

    // Calculate cumulative balance
    let cumulative = 0;
    const withCumulative = raw.map((item) => {
      cumulative += item.net;
      return {
        ...item,
        cumulativeBalance: Math.round(cumulative * 100) / 100
      };
    });

    return withCumulative;
  }

  /**
   * Daily Spending Bar Chart Data
   */
  async getDailySpending(userId, { startDate, endDate }) {
    const userObjId = new mongoose.Types.ObjectId(userId);
    const { start, end } = parseDateRange(startDate, endDate);

    const match = { userId: userObjId, type: 'expense' };
    if (start || end) {
      match.date = {};
      if (start) match.date.$gte = start;
      if (end) match.date.$lte = end;
    } else {
      // Default to current month
      const now = new Date();
      const currentMonth = getStartAndEndOfMonth(now.getFullYear(), now.getMonth());
      match.date = { $gte: currentMonth.start, $lte: currentMonth.end };
    }

    return Transaction.aggregate([
      { $match: match },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$date' } },
          totalAmount: { $sum: '$amount' },
          count: { $sum: 1 }
        }
      },
      {
        $project: {
          _id: 0,
          date: '$_id',
          totalAmount: { $round: ['$totalAmount', 2] },
          count: 1
        }
      },
      { $sort: { date: 1 } }
    ]);
  }

  /**
   * Monthly Comparison (Selected Month vs Previous Month)
   */
  async getMonthlyComparison(userId, { year, month }) {
    const userObjId = new mongoose.Types.ObjectId(userId);
    const targetYear = parseInt(year, 10) || new Date().getFullYear();
    const targetMonth = (parseInt(month, 10) || (new Date().getMonth() + 1)) - 1; // 0-indexed

    const currentRange = getStartAndEndOfMonth(targetYear, targetMonth);
    const prevRange = getPreviousMonthRange(currentRange.start);

    const [currentMonthAgg, prevMonthAgg, currentCategories, prevCategories] = await Promise.all([
      // Totals current month
      Transaction.aggregate([
        { $match: { userId: userObjId, date: { $gte: currentRange.start, $lte: currentRange.end } } },
        {
          $group: {
            _id: '$type',
            total: { $sum: '$amount' }
          }
        }
      ]),

      // Totals previous month
      Transaction.aggregate([
        { $match: { userId: userObjId, date: { $gte: prevRange.start, $lte: prevRange.end } } },
        {
          $group: {
            _id: '$type',
            total: { $sum: '$amount' }
          }
        }
      ]),

      // Current month category expenses
      Transaction.aggregate([
        { $match: { userId: userObjId, type: 'expense', date: { $gte: currentRange.start, $lte: currentRange.end } } },
        { $group: { _id: '$categoryId', total: { $sum: '$amount' } } },
        { $lookup: { from: 'categories', localField: '_id', foreignField: '_id', as: 'cat' } },
        { $unwind: '$cat' },
        { $project: { _id: 0, categoryId: '$_id', name: '$cat.name', color: '$cat.color', icon: '$cat.icon', total: { $round: ['$total', 2] } } }
      ]),

      // Previous month category expenses
      Transaction.aggregate([
        { $match: { userId: userObjId, type: 'expense', date: { $gte: prevRange.start, $lte: prevRange.end } } },
        { $group: { _id: '$categoryId', total: { $sum: '$amount' } } },
        { $lookup: { from: 'categories', localField: '_id', foreignField: '_id', as: 'cat' } },
        { $unwind: '$cat' },
        { $project: { _id: 0, categoryId: '$_id', name: '$cat.name', total: { $round: ['$total', 2] } } }
      ])
    ]);

    let currentIncome = 0;
    let currentExpense = 0;
    currentMonthAgg.forEach((item) => {
      if (item._id === 'income') currentIncome = item.total;
      if (item._id === 'expense') currentExpense = item.total;
    });

    let prevIncome = 0;
    let prevExpense = 0;
    prevMonthAgg.forEach((item) => {
      if (item._id === 'income') prevIncome = item.total;
      if (item._id === 'expense') prevExpense = item.total;
    });

    // Map category comparisons
    const prevCatMap = {};
    prevCategories.forEach((c) => {
      prevCatMap[c.categoryId.toString()] = c.total;
    });

    const categoryComparison = currentCategories.map((c) => {
      const pTotal = prevCatMap[c.categoryId.toString()] || 0;
      const diff = c.total - pTotal;
      const changePct = pTotal > 0 ? Math.round((diff / pTotal) * 10000) / 100 : 100;
      return {
        ...c,
        previousTotal: pTotal,
        difference: Math.round(diff * 100) / 100,
        changePercentage: changePct
      };
    });

    const expenseDiff = currentExpense - prevExpense;
    const expenseChangePct = prevExpense > 0 ? Math.round((expenseDiff / prevExpense) * 10000) / 100 : (currentExpense > 0 ? 100 : 0);

    const incomeDiff = currentIncome - prevIncome;
    const incomeChangePct = prevIncome > 0 ? Math.round((incomeDiff / prevIncome) * 10000) / 100 : (currentIncome > 0 ? 100 : 0);

    return {
      currentMonth: {
        year: targetYear,
        month: targetMonth + 1,
        income: Math.round(currentIncome * 100) / 100,
        expense: Math.round(currentExpense * 100) / 100,
        net: Math.round((currentIncome - currentExpense) * 100) / 100
      },
      previousMonth: {
        income: Math.round(prevIncome * 100) / 100,
        expense: Math.round(prevExpense * 100) / 100,
        net: Math.round((prevIncome - prevExpense) * 100) / 100
      },
      changes: {
        expenseDifference: Math.round(expenseDiff * 100) / 100,
        expenseChangePercentage: expenseChangePct,
        incomeDifference: Math.round(incomeDiff * 100) / 100,
        incomeChangePercentage: incomeChangePct
      },
      categoryComparison
    };
  }

  /**
   * Top Expenses in Selected Period
   */
  async getTopExpenses(userId, { limit = 5, startDate, endDate }) {
    const userObjId = new mongoose.Types.ObjectId(userId);
    const { start, end } = parseDateRange(startDate, endDate);

    const match = { userId: userObjId, type: 'expense' };
    if (start || end) {
      match.date = {};
      if (start) match.date.$gte = start;
      if (end) match.date.$lte = end;
    }

    return Transaction.find(match)
      .populate('categoryId', 'name type icon color')
      .sort({ amount: -1 })
      .limit(parseInt(limit, 10) || 5)
      .lean();
  }
}

module.exports = new AnalyticsService();
