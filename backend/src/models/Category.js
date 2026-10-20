const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true
    },
    name: {
      type: String,
      required: [true, 'Please provide category name'],
      trim: true,
      maxlength: [50, 'Category name cannot exceed 50 characters']
    },
    type: {
      type: String,
      required: [true, 'Please provide category type'],
      enum: {
        values: ['income', 'expense'],
        message: '{VALUE} is not a valid category type'
      },
      index: true
    },
    icon: {
      type: String,
      required: [true, 'Please provide an icon identifier'],
      trim: true,
      default: 'category'
    },
    color: {
      type: String,
      required: [true, 'Please provide a color hex'],
      trim: true,
      default: '#3B82F6'
    },
    isDefault: {
      type: Boolean,
      default: false
    }
  },
  {
    timestamps: true
  }
);

// Compound index to ensure uniqueness per user/scope
categorySchema.index({ userId: 1, name: 1, type: 1 }, { unique: true });

const Category = mongoose.model('Category', categorySchema);
module.exports = Category;
