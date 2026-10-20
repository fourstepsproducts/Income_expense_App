const express = require('express');
const router = express.Router();
const transactionController = require('../controllers/transactionController');
const { protect } = require('../middleware/authMiddleware');
const {
  transactionCreateValidator,
  transactionUpdateValidator,
  transactionQueryValidator
} = require('../validators/transactionValidator');

router.use(protect);

router.get('/', transactionQueryValidator, (req, res, next) => transactionController.getTransactions(req, res, next));
router.get('/:id', (req, res, next) => transactionController.getTransactionById(req, res, next));
router.post('/', transactionCreateValidator, (req, res, next) => transactionController.createTransaction(req, res, next));
router.put('/:id', transactionUpdateValidator, (req, res, next) => transactionController.updateTransaction(req, res, next));
router.delete('/:id', (req, res, next) => transactionController.deleteTransaction(req, res, next));

module.exports = router;
