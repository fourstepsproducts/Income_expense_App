const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const { connectDB, disconnectDB } = require('../src/config/db');
const User = require('../src/models/User');
const Category = require('../src/models/Category');
const Transaction = require('../src/models/Transaction');
const categoryService = require('../src/services/categoryService');

const seedData = async () => {
  try {
    console.log('[Seed] Connecting to MongoDB...');
    await connectDB();

    console.log('[Seed] Ensuring default categories exist...');
    await categoryService.seedDefaultCategories();

    // Check or create demo user
    const demoEmail = 'demo@financetracker.com';
    let user = await User.findOne({ email: demoEmail });

    if (!user) {
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash('Password123!', salt);
      user = await User.create({
        name: 'Alex Mercer',
        email: demoEmail,
        passwordHash,
        currency: 'INR'
      });
      console.log(`[Seed] Created demo user: ${demoEmail} / Password123!`);
    } else {
      console.log(`[Seed] Found existing demo user: ${demoEmail}`);
    }

    // Clean existing transactions for demo user to ensure clean state
    await Transaction.deleteMany({ userId: user._id });
    console.log('[Seed] Cleared prior demo transactions');

    // Retrieve categories
    const categories = await Category.find({ $or: [{ userId: null }, { userId: user._id }] });
    const catMap = {};
    categories.forEach((c) => {
      catMap[c.name] = c._id;
    });

    const now = new Date();
    const transactions = [];

    // Function to get date offset
    const daysAgo = (days, hour = 12) => {
      const d = new Date(now);
      d.setDate(d.getDate() - days);
      d.setHours(hour, Math.floor(Math.random() * 59), 0, 0);
      return d;
    };

    // Income items
    transactions.push(
      {
        userId: user._id,
        type: 'income',
        amount: 85000,
        categoryId: catMap['Salary'],
        date: daysAgo(50, 10),
        paymentMethod: 'Bank Transfer',
        description: 'Monthly Corporate Salary',
        notes: 'Tech Corp monthly payroll'
      },
      {
        userId: user._id,
        type: 'income',
        amount: 22000,
        categoryId: catMap['Freelance'],
        date: daysAgo(42, 16),
        paymentMethod: 'UPI',
        description: 'Flutter App UI Design Contract',
        notes: 'Client milestone completion'
      },
      {
        userId: user._id,
        type: 'income',
        amount: 85000,
        categoryId: catMap['Salary'],
        date: daysAgo(20, 10),
        paymentMethod: 'Bank Transfer',
        description: 'Monthly Corporate Salary',
        notes: 'Tech Corp monthly payroll'
      },
      {
        userId: user._id,
        type: 'income',
        amount: 15000,
        categoryId: catMap['Investment Returns'],
        date: daysAgo(12, 14),
        paymentMethod: 'Bank Transfer',
        description: 'Mutual Fund Dividend & Gains',
        notes: 'Quarterly payout'
      },
      {
        userId: user._id,
        type: 'income',
        amount: 85000,
        categoryId: catMap['Salary'],
        date: daysAgo(1, 10),
        paymentMethod: 'Bank Transfer',
        description: 'Monthly Corporate Salary',
        notes: 'Tech Corp monthly payroll'
      },
      {
        userId: user._id,
        type: 'income',
        amount: 18000,
        categoryId: catMap['Freelance'],
        date: daysAgo(0, 11),
        paymentMethod: 'UPI',
        description: 'Backend API Consulting',
        notes: 'Express.js architecture review'
      }
    );

    // Expense items across past 60 days
    const expenseSamples = [
      // Past month
      { days: 55, amount: 25000, cat: 'House Rent', desc: 'Apartment Monthly Rent', method: 'Bank Transfer' },
      { days: 53, amount: 4200, cat: 'Food and Groceries', desc: 'Weekly Supermarket Haul', method: 'UPI' },
      { days: 50, amount: 2800, cat: 'Electricity and Utilities', desc: 'Electricity & High-speed Wifi', method: 'UPI' },
      { days: 48, amount: 1500, cat: 'Transportation', desc: 'Metro Pass & Fuel Recharge', method: 'Credit Card' },
      { days: 45, amount: 6500, cat: 'Shopping', desc: 'Ergonomic Desk Accessories', method: 'Credit Card' },
      { days: 40, amount: 3200, cat: 'Entertainment', desc: 'Weekend Cinema & Dinner', method: 'Credit Card' },
      { days: 38, amount: 12000, cat: 'EMIs and Loans', desc: 'Automobile Loan EMI', method: 'Bank Transfer' },
      { days: 35, amount: 4500, cat: 'Food and Groceries', desc: 'Organic Grocery Stores', method: 'UPI' },
      { days: 32, amount: 2200, cat: 'Healthcare', desc: 'Routine Health Checkup & Vitamins', method: 'Debit Card' },

      // Current month
      { days: 25, amount: 25000, cat: 'House Rent', desc: 'Apartment Monthly Rent', method: 'Bank Transfer' },
      { days: 22, amount: 5100, cat: 'Food and Groceries', desc: 'Hypermarket Grocery Restock', method: 'UPI' },
      { days: 20, amount: 12000, cat: 'EMIs and Loans', desc: 'Automobile Loan EMI', method: 'Bank Transfer' },
      { days: 18, amount: 2900, cat: 'Electricity and Utilities', desc: 'Power & Broadband bill', method: 'UPI' },
      { days: 16, amount: 8400, cat: 'Travel', desc: 'Weekend Getaway Hotel Stay', method: 'Credit Card' },
      { days: 14, amount: 3600, cat: 'Food and Groceries', desc: 'Artisan Cafe & Bakery Haul', method: 'UPI' },
      { days: 11, amount: 4800, cat: 'Shopping', desc: 'Casual Clothing & Footwear', method: 'Credit Card' },
      { days: 8, amount: 2100, cat: 'Transportation', desc: 'Fuel & City Tolls', method: 'Debit Card' },
      { days: 6, amount: 1800, cat: 'Entertainment', desc: 'Streaming Subscriptions & Games', method: 'Credit Card' },
      { days: 4, amount: 3100, cat: 'Food and Groceries', desc: 'Gourmet Produce & Supplies', method: 'UPI' },
      { days: 2, amount: 1400, cat: 'Transportation', desc: 'Cab rides for client meetings', method: 'UPI' },
      { days: 0, amount: 750, cat: 'Food and Groceries', desc: 'Healthy Lunch & Fresh Smoothies', method: 'UPI' }
    ];

    for (const exp of expenseSamples) {
      if (catMap[exp.cat]) {
        transactions.push({
          userId: user._id,
          type: 'expense',
          amount: exp.amount,
          categoryId: catMap[exp.cat],
          date: daysAgo(exp.days, 15),
          paymentMethod: exp.method,
          description: exp.desc,
          notes: `Seeded transaction for ${exp.desc}`
        });
      }
    }

    await Transaction.insertMany(transactions);
    console.log(`[Seed] Seeded ${transactions.length} transactions successfully.`);
    console.log('[Seed] Database initialization complete!');
    await disconnectDB();
    process.exit(0);
  } catch (err) {
    console.error('[Seed] Error seeding data:', err);
    await disconnectDB();
    process.exit(1);
  }
};

seedData();
