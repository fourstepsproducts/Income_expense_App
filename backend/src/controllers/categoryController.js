const categoryService = require('../services/categoryService');
const { successResponse } = require('../utils/response');

class CategoryController {
  async getCategories(req, res, next) {
    try {
      const { type } = req.query;
      const categories = await categoryService.getCategories(req.user._id, type);
      return successResponse(res, categories, 'Categories retrieved successfully');
    } catch (err) {
      next(err);
    }
  }

  async getCategoryById(req, res, next) {
    try {
      const category = await categoryService.getCategoryById(req.user._id, req.params.id);
      return successResponse(res, category, 'Category retrieved successfully');
    } catch (err) {
      next(err);
    }
  }

  async createCategory(req, res, next) {
    try {
      const category = await categoryService.createCategory(req.user._id, req.body);
      return successResponse(res, category, 'Category created successfully', 201);
    } catch (err) {
      next(err);
    }
  }

  async updateCategory(req, res, next) {
    try {
      const category = await categoryService.updateCategory(req.user._id, req.params.id, req.body);
      return successResponse(res, category, 'Category updated successfully');
    } catch (err) {
      next(err);
    }
  }

  async deleteCategory(req, res, next) {
    try {
      const result = await categoryService.deleteCategory(req.user._id, req.params.id);
      return successResponse(res, result, 'Category deleted successfully');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new CategoryController();
