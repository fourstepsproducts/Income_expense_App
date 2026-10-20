const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/categoryController');
const { protect } = require('../middleware/authMiddleware');
const {
  categoryCreateValidator,
  categoryUpdateValidator
} = require('../validators/categoryValidator');

router.use(protect);

router.get('/', (req, res, next) => categoryController.getCategories(req, res, next));
router.get('/:id', (req, res, next) => categoryController.getCategoryById(req, res, next));
router.post('/', categoryCreateValidator, (req, res, next) => categoryController.createCategory(req, res, next));
router.put('/:id', categoryUpdateValidator, (req, res, next) => categoryController.updateCategory(req, res, next));
router.delete('/:id', (req, res, next) => categoryController.deleteCategory(req, res, next));

module.exports = router;
