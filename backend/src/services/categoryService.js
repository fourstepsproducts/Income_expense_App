const Category = require('../models/Category');
const Transaction = require('../models/Transaction');

const DEFAULT_CATEGORIES = [
  // Income
  { name: 'Salary', type: 'income', icon: 'work', color: '#10B981', isDefault: true },
  { name: 'Business Income', type: 'income', icon: 'domain', color: '#06B6D4', isDefault: true },
  { name: 'Freelance', type: 'income', icon: 'laptop_mac', color: '#3B82F6', isDefault: true },
  { name: 'Investment Returns', type: 'income', icon: 'trending_up', color: '#8B5CF6', isDefault: true },
  { name: 'Rental Income', type: 'income', icon: 'apartment', color: '#EC4899', isDefault: true },
  { name: 'Other Income', type: 'income', icon: 'account_balance_wallet', color: '#14B8A6', isDefault: true },

  // Expense
  { name: 'Food and Groceries', type: 'expense', icon: 'restaurant', color: '#EF4444', isDefault: true },
  { name: 'Transportation', type: 'expense', icon: 'directions_car', color: '#F97316', isDefault: true },
  { name: 'House Rent', type: 'expense', icon: 'home', color: '#F59E0B', isDefault: true },
  { name: 'Electricity and Utilities', type: 'expense', icon: 'flash_on', color: '#EAB308', isDefault: true },
  { name: 'Shopping', type: 'expense', icon: 'shopping_bag', color: '#EC4899', isDefault: true },
  { name: 'Healthcare', type: 'expense', icon: 'medical_services', color: '#14B8A6', isDefault: true },
  { name: 'Education', type: 'expense', icon: 'school', color: '#6366F1', isDefault: true },
  { name: 'Entertainment', type: 'expense', icon: 'movie', color: '#8B5CF6', isDefault: true },
  { name: 'Travel', type: 'expense', icon: 'flight', color: '#3B82F6', isDefault: true },
  { name: 'EMIs and Loans', type: 'expense', icon: 'credit_card', color: '#D946EF', isDefault: true },
  { name: 'Family Expenses', type: 'expense', icon: 'people', color: '#06B6D4', isDefault: true },
  { name: 'Other Expenses', type: 'expense', icon: 'more_horiz', color: '#64748B', isDefault: true }
];

class CategoryService {
  async seedDefaultCategories() {
    for (const cat of DEFAULT_CATEGORIES) {
      await Category.findOneAndUpdate(
        { userId: null, name: cat.name, type: cat.type },
        { ...cat, userId: null },
        { upsert: true, new: true }
      );
    }
  }

  async getCategories(userId, type = null) {
    // Return system default categories + user custom categories
    const filter = {
      $or: [{ userId: null }, { userId }]
    };

    if (type) {
      filter.type = type;
    }

    return Category.find(filter).sort({ isDefault: -1, name: 1 });
  }

  async getCategoryById(userId, categoryId) {
    const category = await Category.findOne({
      _id: categoryId,
      $or: [{ userId: null }, { userId }]
    });

    if (!category) {
      const error = new Error('Category not found');
      error.statusCode = 404;
      throw error;
    }

    return category;
  }

  async createCategory(userId, { name, type, icon, color }) {
    // Check if category with same name exists for this user or default
    const existing = await Category.findOne({
      name: { $regex: new RegExp(`^${name.trim()}$`, 'i') },
      type,
      $or: [{ userId: null }, { userId }]
    });

    if (existing) {
      const error = new Error(`Category "${name}" of type "${type}" already exists`);
      error.statusCode = 409;
      throw error;
    }

    const category = await Category.create({
      userId,
      name: name.trim(),
      type,
      icon: icon || 'category',
      color: color || '#3B82F6',
      isDefault: false
    });

    return category;
  }

  async updateCategory(userId, categoryId, { name, type, icon, color }) {
    const category = await Category.findOne({ _id: categoryId, userId });

    if (!category) {
      const error = new Error('Category not found or cannot be modified (system defaults are protected)');
      error.statusCode = 403;
      throw error;
    }

    if (name) category.name = name.trim();
    if (type) category.type = type;
    if (icon) category.icon = icon;
    if (color) category.color = color;

    await category.save();
    return category;
  }

  async deleteCategory(userId, categoryId) {
    const category = await Category.findOne({ _id: categoryId, userId });

    if (!category) {
      const error = new Error('Category not found or cannot be deleted (system default categories are protected)');
      error.statusCode = 403;
      throw error;
    }

    // Check if any transaction is using this category
    const transactionCount = await Transaction.countDocuments({ categoryId, userId });
    if (transactionCount > 0) {
      const error = new Error(`Cannot delete category because it is currently used by ${transactionCount} transaction(s). Reassign them first.`);
      error.statusCode = 400;
      throw error;
    }

    await Category.deleteOne({ _id: categoryId });
    return { id: categoryId, deleted: true };
  }
}

module.exports = new CategoryService();
