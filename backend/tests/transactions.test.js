const request = require('supertest');
const app = require('../src/app');
const { setupTestDB } = require('./setup');
const Category = require('../src/models/Category');

setupTestDB();

describe('Transactions API & Ownership Tests', () => {
  let userA, userB;
  let categoryExpense, categoryIncome;

  beforeEach(async () => {
    // Register User A
    const resA = await request(app).post('/api/auth/register').send({
      name: 'User Alpha',
      email: 'alpha@example.com',
      password: 'Password123!'
    });
    userA = resA.body.data;

    // Register User B
    const resB = await request(app).post('/api/auth/register').send({
      name: 'User Beta',
      email: 'beta@example.com',
      password: 'Password123!'
    });
    userB = resB.body.data;

    // Create categories
    categoryExpense = await Category.create({
      name: 'Dining',
      type: 'expense',
      icon: 'restaurant',
      color: '#EF4444',
      isDefault: true
    });

    categoryIncome = await Category.create({
      name: 'Tech Salary',
      type: 'income',
      icon: 'work',
      color: '#10B981',
      isDefault: true
    });
  });

  it('should allow user to create an expense transaction', async () => {
    const res = await request(app)
      .post('/api/transactions')
      .set('Authorization', `Bearer ${userA.accessToken}`)
      .send({
        type: 'expense',
        amount: 2500,
        categoryId: categoryExpense._id,
        date: new Date().toISOString(),
        paymentMethod: 'UPI',
        description: 'Dinner with friends'
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.amount).toBe(2500);
    expect(res.body.data.description).toBe('Dinner with friends');
  });

  it('should reject transaction creation with incompatible category type', async () => {
    const res = await request(app)
      .post('/api/transactions')
      .set('Authorization', `Bearer ${userA.accessToken}`)
      .send({
        type: 'income',
        amount: 5000,
        categoryId: categoryExpense._id, // Incompatible: expense category with income transaction
        date: new Date().toISOString(),
        description: 'Mismatched transaction'
      });

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('should enforce strict ownership: User B cannot access User A transaction', async () => {
    // User A creates a transaction
    const createRes = await request(app)
      .post('/api/transactions')
      .set('Authorization', `Bearer ${userA.accessToken}`)
      .send({
        type: 'expense',
        amount: 1500,
        categoryId: categoryExpense._id,
        date: new Date().toISOString(),
        description: 'Alpha Private Expense'
      });

    const txId = createRes.body.data._id;

    // User B attempts to read User A transaction
    const readRes = await request(app)
      .get(`/api/transactions/${txId}`)
      .set('Authorization', `Bearer ${userB.accessToken}`);

    expect(readRes.statusCode).toBe(404);

    // User B attempts to delete User A transaction
    const delRes = await request(app)
      .delete(`/api/transactions/${txId}`)
      .set('Authorization', `Bearer ${userB.accessToken}`);

    expect(delRes.statusCode).toBe(404);
  });

  it('should prevent deleting a category if it is in use by transactions', async () => {
    // User A creates a custom category
    const catRes = await request(app)
      .post('/api/categories')
      .set('Authorization', `Bearer ${userA.accessToken}`)
      .send({
        name: 'Custom Books',
        type: 'expense',
        icon: 'book',
        color: '#6366F1'
      });
    const customCatId = catRes.body.data._id;

    // User A creates a transaction with this category
    await request(app)
      .post('/api/transactions')
      .set('Authorization', `Bearer ${userA.accessToken}`)
      .send({
        type: 'expense',
        amount: 800,
        categoryId: customCatId,
        date: new Date().toISOString(),
        description: 'Algorithms Textbook'
      });

    // Attempt to delete custom category
    const delRes = await request(app)
      .delete(`/api/categories/${customCatId}`)
      .set('Authorization', `Bearer ${userA.accessToken}`);

    expect(delRes.statusCode).toBe(400);
    expect(delRes.body.message).toMatch(/currently used by 1 transaction/);
  });
});
