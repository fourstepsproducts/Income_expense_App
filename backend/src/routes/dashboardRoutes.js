const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

router.get('/summary', (req, res, next) => dashboardController.getSummary(req, res, next));

module.exports = router;
