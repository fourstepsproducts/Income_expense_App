# Personal Finance Tracker REST API Documentation

This document describes all REST API endpoints provided by the Node.js/Express backend service.

Base URL: `http://localhost:5000/api` (Development) or your deployed server URL.

---

## 1. Authentication & Security

All protected endpoints require an HTTP `Authorization` header containing a valid JSON Web Token:
```http
Authorization: Bearer <access_token>
```

When an access token expires (HTTP 401 with `{ "code": "TOKEN_EXPIRED" }`), the client sends the refresh token to `/api/auth/refresh` to obtain new tokens.

---

## 2. Endpoints Summary

### Authentication (`/api/auth`)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `POST` | `/api/auth/register` | Register a new user | No (Rate Limited) |
| `POST` | `/api/auth/login` | Authenticate with email & password | No (Rate Limited) |
| `POST` | `/api/auth/refresh` | Exchange refresh token for fresh tokens | No |
| `GET` | `/api/auth/me` | Fetch authenticated user profile | Yes |
| `PUT` | `/api/auth/me` | Update profile (name, currency) | Yes |

### Categories (`/api/categories`)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `GET` | `/api/categories` | List system default & user categories (query: `type`) | Yes |
| `GET` | `/api/categories/:id` | Get single category by ID | Yes |
| `POST` | `/api/categories` | Create custom category | Yes |
| `PUT` | `/api/categories/:id` | Update custom category | Yes |
| `DELETE` | `/api/categories/:id` | Delete custom category (only if unused) | Yes |

### Transactions (`/api/transactions`)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `GET` | `/api/transactions` | Paginated, filtered, and sorted transactions | Yes |
| `GET` | `/api/transactions/:id` | Get transaction by ID | Yes |
| `POST` | `/api/transactions` | Create new transaction | Yes |
| `PUT` | `/api/transactions/:id` | Update existing transaction | Yes |
| `DELETE` | `/api/transactions/:id` | Delete transaction | Yes |

### Dashboard & Analytics (`/api/dashboard` & `/api/analytics`)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `GET` | `/api/dashboard/summary` | Real-time summary totals, today, month, savings rate, trends | Yes |
| `GET` | `/api/analytics/income-expense` | Grouped bar chart data (`period=day\|week\|month\|year`) | Yes |
| `GET` | `/api/analytics/expense-categories` | Category doughnut/pie chart breakdown & percentages | Yes |
| `GET` | `/api/analytics/cash-flow` | Cumulative balance and cash flow trend points | Yes |
| `GET` | `/api/analytics/monthly-comparison` | Selected month vs previous month category shift | Yes |
| `GET` | `/api/analytics/top-expenses` | Largest expense transactions in period | Yes |
| `GET` | `/api/analytics/daily-spending` | Day-by-day spending bars | Yes |

---

## 3. Detailed Request / Response Payloads

### POST `/api/auth/register`
**Request Body:**
```json
{
  "name": "Alex Mercer",
  "email": "alex@example.com",
  "password": "Password123!",
  "currency": "INR"
}
```
**Response (201 Created):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "67140f0c08b5e94b5952f01a",
      "name": "Alex Mercer",
      "email": "alex@example.com",
      "currency": "INR",
      "createdAt": "2026-10-20T10:00:00.000Z"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### POST `/api/transactions`
**Request Body:**
```json
{
  "type": "expense",
  "amount": 4200.50,
  "categoryId": "67140f0c08b5e94b5952f010",
  "date": "2026-10-20T14:30:00.000Z",
  "paymentMethod": "UPI",
  "description": "Weekly Supermarket Groceries",
  "notes": "Organic fruits and vegetables"
}
```
**Response (201 Created):**
```json
{
  "success": true,
  "message": "Transaction created successfully",
  "data": {
    "_id": "67140f0c08b5e94b5952f089",
    "userId": "67140f0c08b5e94b5952f01a",
    "type": "expense",
    "amount": 4200.5,
    "categoryId": {
      "_id": "67140f0c08b5e94b5952f010",
      "name": "Food and Groceries",
      "type": "expense",
      "icon": "restaurant",
      "color": "#EF4444"
    },
    "date": "2026-10-20T14:30:00.000Z",
    "paymentMethod": "UPI",
    "description": "Weekly Supermarket Groceries",
    "notes": "Organic fruits and vegetables",
    "createdAt": "2026-10-20T14:30:05.123Z"
  }
}
```

### GET `/api/dashboard/summary`
**Response (200 OK):**
```json
{
  "success": true,
  "message": "Dashboard summary retrieved successfully",
  "data": {
    "totals": {
      "totalIncome": 125000.0,
      "totalExpense": 52400.0,
      "netBalance": 72600.0,
      "savingsRate": 58.08
    },
    "today": {
      "income": 0.0,
      "expense": 750.0
    },
    "currentMonth": {
      "year": 2026,
      "month": 10,
      "income": 103000.0,
      "expense": 48350.0,
      "net": 54650.0
    },
    "previousMonth": {
      "expense": 56200.0
    },
    "expenseComparison": {
      "trend": "decreasing",
      "changePercentage": 13.97,
      "isIncrease": false,
      "previousMonthExpense": 56200.0
    },
    "recentTransactions": [...]
  }
}
```
