const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analyticsController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

router.get('/income-expense', (req, res, next) => analyticsController.getIncomeVsExpense(req, res, next));
router.get('/expense-categories', (req, res, next) => analyticsController.getExpenseCategories(req, res, next));
router.get('/cash-flow', (req, res, next) => analyticsController.getCashFlow(req, res, next));
router.get('/monthly-comparison', (req, res, next) => analyticsController.getMonthlyComparison(req, res, next));
router.get('/top-expenses', (req, res, next) => analyticsController.getTopExpenses(req, res, next));
router.get('/daily-spending', (req, res, next) => analyticsController.getDailySpending(req, res, next));

module.exports = router;
