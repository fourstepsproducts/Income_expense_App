# 💳 FinanceFlow — Personal Income & Expense Tracker

> A production-grade personal finance application with a deep navy and black aesthetic, real-time MongoDB aggregations, interactive charts, and complete transaction management.

---

## 🚀 Key Features

### 1. 📊 Main Dashboard
- **Live MongoDB Totals**: Total Income, Total Expenses, Net Balance, Today's Totals, Current Month's Totals.
- **Dynamic Savings Rate**: Automatically calculated as `(Net Income / Total Income) * 100` when Total Income > 0.
- **Period Trend Indicator**: Badge showing whether monthly expenses are increasing or decreasing compared to the previous month (e.g. `+12.5% vs last month`).
- **Real-Time Visualizations**:
  - Monthly Income vs Expense grouped bar chart.
  - Expense Category doughnut breakdown with percentage breakdown.
  - Cumulative Cash Flow trend line chart with area glow.
- **Recent Transactions Feed**: Live stream of the latest 5 transactions with quick-tap detail & edit access.
- **Helpful Empty States**: Clean onboarding prompts for new users before transactions are logged.

### 2. ⚡ Fast Transaction Entry
- **Income & Expense Modes**: Visual switch with distinct green/red accents and icons.
- **Input Validation**: Required fields, numeric keypad validation (> 0), description length checks.
- **Date & Time Pickers**: Defaults to today, allows selecting past or future dates and custom times.
- **Payment Method**: Cash, Bank Transfer, UPI, Credit Card, Debit Card, Other.
- **Double-Tap Protection**: Button locking prevents accidental duplicate entries.
- **Edit & Delete**: Full transaction editing with confirmation dialogs before deletion.

### 3. 🏷️ Category Management
- **MongoDB Stored**: Default categories seeded via backend script (`Salary`, `Food and Groceries`, `House Rent`, etc.).
- **Custom Categories**: Users can add custom categories for both Income and Expense.
- **Personalized Icons & Colors**: Icon picker with 20+ Material icons and curated hex color palette.
- **Integrity Guard**: Deletion is blocked if any existing transaction currently uses the category.

### 4. 📜 Transaction History & Filtering
- **Reverse Chronological Order**: Latest transactions shown first.
- **Real-Time Search**: Debounced search across descriptions and notes.
- **Multi-Filter Modal**: Filter by Type (Income/Expense), Category, Payment Method, and Date Range.
- **Sorting**: Sort by Date or Amount (Ascending / Descending).
- **Pagination Support**: Infinite scroll with lazy loading.
- **Monthly Summary Banner**: Quick view of filtered Income, Expense, and Net totals at the top.

### 5. 📈 Analytics & Data Visualizations
- **Income vs Expense**: Grouped bar chart viewable by **Daily, Weekly, Monthly, or Yearly**.
- **Category Breakdown**: Interactive doughnut chart with legend and percentage breakdowns.
- **Cash Flow Line Chart**: Cumulative financial trajectory over time.
- **Daily Spending**: Bar chart showing day-by-day burn rate.
- **Month-over-Month Comparison**: Compares the current month against the previous month category-by-category.
- **Top Expenses**: Highlights the 5 largest individual expenses in the selected period.
- **Custom Date Range Filter**: Dynamically query any custom time window.

### 6. ⚙️ Settings & Configuration
- **Currency Selection**: Configurable currency formatting (default: **INR ₹** with Indian numbering e.g. `1,50,000`, supports USD `$`, EUR `€`, GBP `£`, AED, SGD, JPY).
- **Theme Preferences**: OLED Black and Deep Navy primary dark theme.
- **Network Endpoint Manager**: Configure or reset backend API URL directly inside the app.
- **Secure Authentication**: JWT access and refresh token strategy with platform storage.

---

## 🛠️ Technology Stack

| Layer | Technologies |
|---|---|
| **Frontend** | Flutter 3.47+, Dart 3.13+, Material Design 3, Riverpod 2.6+, fl_chart 0.70+, Google Fonts |
| **Backend** | Node.js 20+, Express.js 4+, Mongoose 8+, JWT, bcryptjs, Helmet, CORS, Morgan |
| **Database** | MongoDB 6.0+ (supports local mongod, MongoDB Atlas, and automatic embedded in-memory fallback) |
| **Testing** | Jest, Supertest, mongodb-memory-server (Backend) • flutter_test (Frontend) |

---

## 📁 Repository Structure

```
personal_finance_tracker/
├── frontend/                     # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart             # App entry point (ProviderScope)
│   │   ├── app/                  # App setup, theme & navigation
│   │   │   ├── app.dart          # Auth routing gate
│   │   │   ├── navigation_scaffold.dart # 5-tab bottom navigation
│   │   │   └── theme/            # AppColors & AppTheme (Material 3)
│   │   ├── core/                 # Core utilities & reusable widgets
│   │   │   ├── config/           # ApiConfig (runtime base URL)
│   │   │   ├── constants/        # Currencies, payment methods
│   │   │   ├── errors/           # AppException hierarchy
│   │   │   ├── network/          # ApiClient (JWT token refresh)
│   │   │   ├── utils/            # CurrencyFormatter & DateFormatter
│   │   │   └── widgets/          # AppCard, StatCard, CustomButton, etc.
│   │   ├── features/             # Feature modules
│   │   │   ├── authentication/   # Login & Register screens
│   │   │   ├── dashboard/        # Dashboard, summary cards & charts
│   │   │   ├── transactions/     # Entry form & History screens
│   │   │   ├── categories/       # Category management & creation
│   │   │   ├── analytics/        # 6 charts & date range picker
│   │   │   └── settings/         # Settings, currency picker, logout
│   │   └── shared/               # Shared models, services & Riverpod providers
│   ├── test/                     # Flutter unit & widget tests
│   └── pubspec.yaml              # Dependencies and assets
├── backend/                      # Node.js / Express REST API
│   ├── src/
│   │   ├── config/               # db.js, env.js
│   │   ├── controllers/          # auth, category, transaction, analytics
│   │   ├── middleware/           # authMiddleware, errorMiddleware, rateLimiter
│   │   ├── models/               # User, Category, Transaction (Mongoose)
│   │   ├── routes/               # API route definitions
│   │   ├── services/             # Business logic & Mongo aggregations
│   │   ├── utils/                # response, dateUtils, jwt
│   │   ├── validators/           # express-validator schemas
│   │   ├── app.js                # Express app configuration
│   │   └── server.js             # Server startup & graceful shutdown
│   ├── scripts/
│   │   └── seed.js               # Database initialization & demo seeder
│   ├── tests/                    # Jest API & calculation tests
│   ├── .env                      # Local environment configuration
│   ├── .env.example              # Environment variables template
│   └── package.json              # Backend dependencies
├── docs/                         # Detailed architecture & API guides
│   ├── api_documentation.md      # Full REST API specification
│   ├── architecture.md           # System design & security model
│   └── deployment_guide.md       # MongoDB Atlas & release guide
├── .gitignore                    # Root gitignore
└── README.md                     # Documentation
```

---

## 🏁 Quickstart Guide

### 1. Prerequisites
- **Node.js**: v18.0 or newer
- **Flutter SDK**: v3.20 or newer
- **MongoDB**: Local MongoDB or MongoDB Atlas URI (Note: In development, an embedded in-memory MongoDB will automatically start if no local MongoDB is detected!).

---

### 2. Backend Setup

1. Open terminal and navigate to `backend/`:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Initialize `.env`:
   ```bash
   cp .env.example .env
   ```
4. Seed default categories and realistic demo data:
   ```bash
   npm run seed
   ```
   *Demo credentials created:*
   - **Email**: `demo@financetracker.com`
   - **Password**: `Password123!`

5. Start the backend development server:
   ```bash
   npm run dev
   ```
   The API will be live at `http://localhost:5000/api`. Verify by visiting `http://localhost:5000/api/health`.

6. Run backend automated tests:
   ```bash
   npm test
   ```

---

### 3. Frontend Setup

1. Open a new terminal and navigate to `frontend/`:
   ```bash
   cd frontend
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the Flutter unit & widget tests:
   ```bash
   flutter test
   ```
4. Run the Flutter app:
   - **Desktop / Web**:
     ```bash
     flutter run -d chrome
     # or for Windows Desktop
     flutter run -d windows
     ```
   - **Android Emulator**:
     ```bash
     flutter run --dart-define=API_URL=http://10.0.2.2:5000/api
     ```
   - **Physical Device**:
     ```bash
     flutter run --dart-define=API_URL=http://<YOUR_COMPUTER_LAN_IP>:5000/api
     ```

5. Build Android Release APK:
   ```bash
   flutter build apk --release --dart-define=API_URL=https://your-backend-api.com/api
   ```

---

## 🔒 Security Best Practices Implemented

- **Password Hashing**: Passwords hashed with bcrypt salt rounds before database persistence.
- **Short-Lived Tokens**: JWT access tokens expire in 15 minutes; refresh tokens expire in 7 days.
- **Client Auto-Refresh**: Flutter `ApiClient` transparently catches 401s, calls `/auth/refresh`, updates tokens, and retries the original request.
- **Rate Limiting**: Authentication endpoints are rate-limited to prevent brute-force attacks.
- **Query Scoping**: Every database operation strictly scopes by `req.user._id`. Users cannot view or modify transactions belonging to other users.
- **No Embedded Secrets**: Mobile code contains zero credentials; all sensitive secrets live exclusively in server `.env`.

---

## 🧪 Testing Verification

Both the backend and frontend include test suites covering calculations, aggregations, authorization, and UI components:

```bash
# Backend Test Suite (13 passing tests)
cd backend && npm test

# Frontend Test Suite (9 passing tests)
cd frontend && flutter test
```

---

## 📄 License
This project is open-source under the MIT License.
