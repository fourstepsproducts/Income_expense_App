const request = require('supertest');
const app = require('../src/app');
const { setupTestDB } = require('./setup');
const Category = require('../src/models/Category');

setupTestDB();

describe('Analytics & Dashboard Summary Calculations', () => {
  let user;
  let salaryCat, rentCat, foodCat;

  beforeEach(async () => {
    const res = await request(app).post('/api/auth/register').send({
      name: 'Finance User',
      email: 'finance@example.com',
      password: 'Password123!'
    });
    user = res.body.data;

    salaryCat = await Category.create({ name: 'Salary', type: 'income', icon: 'work', color: '#10B981', isDefault: true });
    rentCat = await Category.create({ name: 'Rent', type: 'expense', icon: 'home', color: '#F59E0B', isDefault: true });
    foodCat = await Category.create({ name: 'Food', type: 'expense', icon: 'restaurant', color: '#EF4444', isDefault: true });
  });

  it('should correctly calculate total income, expense, net balance, and savings rate', async () => {
    const today = new Date();

    // 100,000 Income
    await request(app)
      .post('/api/transactions')
      .set('Authorization', `Bearer ${user.accessToken}`)
      .send({
        type: 'income',
        amount: 100000,
        categoryId: salaryCat._id,
        date: today.toISOString(),
        description: 'Monthly Pay'
      });

    // 25,000 Rent Expense
    await request(app)
      .post('/api/transactions')
      .set('Authorization', `Bearer ${user.accessToken}`)
      .send({
        type: 'expense',
        amount: 25000,
        categoryId: rentCat._id,
        date: today.toISOString(),
        description: 'Apartment'
      });

    // 15,000 Food Expense
    await request(app)
      .post('/api/transactions')
      .set('Authorization', `Bearer ${user.accessToken}`)
      .send({
        type: 'expense',
        amount: 15000,
        categoryId: foodCat._id,
        date: today.toISOString(),
        description: 'Groceries'
      });

    const summaryRes = await request(app)
      .get('/api/dashboard/summary')
      .set('Authorization', `Bearer ${user.accessToken}`);

    expect(summaryRes.statusCode).toBe(200);
    const { totals, today: todayStats } = summaryRes.body.data;

    // Total income = 100,000
    expect(totals.totalIncome).toBe(100000);
    // Total expense = 40,000
    expect(totals.totalExpense).toBe(40000);
    // Net balance = 60,000
    expect(totals.netBalance).toBe(60000);
    // Savings rate = (60000 / 100000) * 100 = 60%
    expect(totals.savingsRate).toBe(60);

    // Today stats
    expect(todayStats.income).toBe(100000);
    expect(todayStats.expense).toBe(40000);
  });

  it('should return 0 savings rate when total income is 0', async () => {
    await request(app)
      .post('/api/transactions')
      .set('Authorization', `Bearer ${user.accessToken}`)
      .send({
        type: 'expense',
        amount: 500,
        categoryId: foodCat._id,
        date: new Date().toISOString(),
        description: 'Snack'
      });

    const summaryRes = await request(app)
      .get('/api/dashboard/summary')
      .set('Authorization', `Bearer ${user.accessToken}`);

    expect(summaryRes.body.data.totals.savingsRate).toBe(0);
    expect(summaryRes.body.data.totals.netBalance).toBe(-500);
  });

  it('should return category breakdown with accurate percentages', async () => {
    // 3,000 on Rent, 1,000 on Food => Total = 4,000 (Rent = 75%, Food = 25%)
    await request(app)
      .post('/api/transactions')
      .set('Authorization', `Bearer ${user.accessToken}`)
      .send({
        type: 'expense',
        amount: 3000,
        categoryId: rentCat._id,
        date: new Date().toISOString(),
        description: 'Room'
      });

    await request(app)
      .post('/api/transactions')
      .set('Authorization', `Bearer ${user.accessToken}`)
      .send({
        type: 'expense',
        amount: 1000,
        categoryId: foodCat._id,
        date: new Date().toISOString(),
        description: 'Lunch'
      });

    const breakdownRes = await request(app)
      .get('/api/analytics/expense-categories')
      .set('Authorization', `Bearer ${user.accessToken}`);

    expect(breakdownRes.statusCode).toBe(200);
    expect(breakdownRes.body.data.totalExpense).toBe(4000);

    const breakdown = breakdownRes.body.data.breakdown;
    expect(breakdown.length).toBe(2);

    const rentItem = breakdown.find((b) => b.name === 'Rent');
    expect(rentItem.totalAmount).toBe(3000);
    expect(rentItem.percentage).toBe(75);

    const foodItem = breakdown.find((b) => b.name === 'Food');
    expect(foodItem.totalAmount).toBe(1000);
    expect(foodItem.percentage).toBe(25);
  });
});
