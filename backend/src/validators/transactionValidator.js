const { body, param, query } = require('express-validator');
const { handleValidationErrors } = require('./authValidator');

const transactionCreateValidator = [
  body('type')
    .notEmpty()
    .withMessage('Type is required')
    .isIn(['income', 'expense'])
    .withMessage('Type must be either income or expense'),
  body('amount')
    .notEmpty()
    .withMessage('Amount is required')
    .isFloat({ min: 0.01 })
    .withMessage('Amount must be greater than 0'),
  body('categoryId')
    .notEmpty()
    .withMessage('Category ID is required')
    .isMongoId()
    .withMessage('Category ID must be a valid MongoDB ObjectId'),
  body('date')
    .notEmpty()
    .withMessage('Date is required')
    .isISO8601()
    .withMessage('Date must be in ISO8601 format (e.g. 2026-10-20T10:00:00Z)'),
  body('paymentMethod')
    .optional()
    .isIn(['Cash', 'Bank Transfer', 'UPI', 'Credit Card', 'Debit Card', 'Other'])
    .withMessage('Invalid payment method'),
  body('description')
    .trim()
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ max: 120 })
    .withMessage('Description cannot exceed 120 characters'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes cannot exceed 500 characters'),
  handleValidationErrors
];

const transactionUpdateValidator = [
  param('id')
    .isMongoId()
    .withMessage('Invalid transaction ID'),
  body('type')
    .optional()
    .isIn(['income', 'expense'])
    .withMessage('Type must be either income or expense'),
  body('amount')
    .optional()
    .isFloat({ min: 0.01 })
    .withMessage('Amount must be greater than 0'),
  body('categoryId')
    .optional()
    .isMongoId()
    .withMessage('Category ID must be a valid MongoDB ObjectId'),
  body('date')
    .optional()
    .isISO8601()
    .withMessage('Date must be in ISO8601 format'),
  body('paymentMethod')
    .optional()
    .isIn(['Cash', 'Bank Transfer', 'UPI', 'Credit Card', 'Debit Card', 'Other'])
    .withMessage('Invalid payment method'),
  body('description')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Description cannot be empty')
    .isLength({ max: 120 })
    .withMessage('Description cannot exceed 120 characters'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes cannot exceed 500 characters'),
  handleValidationErrors
];

const transactionQueryValidator = [
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
  query('type').optional().isIn(['income', 'expense']),
  query('categoryId').optional().isMongoId(),
  query('startDate').optional().isISO8601(),
  query('endDate').optional().isISO8601(),
  query('sortBy').optional().isIn(['date', 'amount']),
  query('sortOrder').optional().isIn(['asc', 'desc']),
  handleValidationErrors
];

module.exports = {
  transactionCreateValidator,
  transactionUpdateValidator,
  transactionQueryValidator
};
