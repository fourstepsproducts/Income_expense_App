const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');
const { authLimiter } = require('../middleware/rateLimiter');
const {
  registerValidator,
  loginValidator,
  refreshValidator
} = require('../validators/authValidator');

router.post('/register', authLimiter, registerValidator, (req, res, next) => authController.register(req, res, next));
router.post('/login', authLimiter, loginValidator, (req, res, next) => authController.login(req, res, next));
router.post('/refresh', refreshValidator, (req, res, next) => authController.refresh(req, res, next));
router.get('/me', protect, (req, res, next) => authController.getProfile(req, res, next));
router.put('/me', protect, (req, res, next) => authController.updateProfile(req, res, next));

module.exports = router;
