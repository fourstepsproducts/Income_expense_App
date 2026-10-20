# Architecture and System Design

## 1. High-Level Architecture

The Personal Finance Tracker follows a strict separation of concerns with a decoupled client-server architecture:

```
┌────────────────────────────────────────────────────────┐
│               Flutter Mobile / Tablet App              │
│  - Material 3 Design System (Dark Navy & Black Theme)  │
│  - Riverpod State Management & Notifiers               │
│  - fl_chart Reactive Financial Data Visualizations     │
│  - SharedPreferences JWT Session & Currency Store      │
└──────────────────────────┬─────────────────────────────┘
                           │ HTTPS / JSON REST API
                           │ Bearer Tokens
┌──────────────────────────▼─────────────────────────────┐
│                 Node.js / Express Backend               │
│  - Helmet, CORS, Compression, Morgan Logger            │
│  - Rate Limiting on Authentication Endpoints           │
│  - Express-Validator Input Sanitization               │
│  - JWT Verification & Short-lived Access Tokens        │
│  - Layered Architecture: Routes -> Controllers ->      │
│    Services -> Mongoose Models                         │
└──────────────────────────┬─────────────────────────────┘
                           │ Mongoose ODM
                           │ Aggregation Pipelines
┌──────────────────────────▼─────────────────────────────┐
│                   MongoDB Database                      │
│  - Users, Categories, Transactions Collections         │
│  - Compound Query Indexes & User Isolation Scope       │
│  - Real-time Group & Time-Series Aggregations          │
└────────────────────────────────────────────────────────┘
```

---

## 2. Frontend Clean Architecture

The Flutter application (`frontend/`) is structured by feature:

- **`app/`**: Application root, theme tokens (`app_colors.dart`), Material 3 theme configuration (`app_theme.dart`), and 5-section bottom navigation scaffold (`navigation_scaffold.dart`).
- **`core/`**:
  - `config/`: Dynamic API base URL resolution (`api_config.dart`).
  - `constants/`: Payment methods, default currency symbols, storage keys.
  - `network/`: `ApiClient` with automatic JWT Bearer insertion, error normalization, and 401 token refresh interception.
  - `utils/`: `CurrencyFormatter` with Indian numbering (`1,50,000`) and international formats; `DateFormatter`.
  - `widgets/`: Reusable components (`AppCard`, `StatCard`, `CustomButton`, `EmptyState`, `ErrorView`, `ConfirmationDialog`).
- **`features/`**:
  - `authentication/`: Login and registration flows.
  - `dashboard/`: Dynamic summary cards, real-time Mongo aggregation charts, recent transactions.
  - `transactions/`: Entry form with validation, reverse-chronological history, search, filtering, and pagination.
  - `categories/`: Income & Expense tabs, custom category addition, icon & color pickers, deletion guard.
  - `analytics/`: 6 interactive charts (Income vs Expense bar, Expense doughnut, Cash flow line, Daily spending bar, Monthly comparison, Top expenses).
  - `settings/`: Currency picker, dark mode preferences, server URL endpoint manager, logout.
- **`shared/`**:
  - `models/`: Strongly-typed data models with JSON serialization.
  - `services/`: API client consumption abstractions.
  - `providers.dart`: Riverpod providers.

---

## 3. Database Schema & Indexes

### Collections

#### Users (`users`)
- `_id`: ObjectId
- `name`: String (trimmed, max 60)
- `email`: String (lowercase, unique, indexed)
- `passwordHash`: String (bcrypt hash)
- `currency`: String (default 'INR')
- `createdAt`, `updatedAt`: Timestamps

#### Categories (`categories`)
- `_id`: ObjectId
- `userId`: ObjectId (null for system defaults, User ID for custom user categories)
- `name`: String
- `type`: Enum ('income', 'expense')
- `icon`: String (Material icon identifier)
- `color`: String (Hex code)
- `isDefault`: Boolean
- **Compound Index**: `{ userId: 1, name: 1, type: 1 }` (unique per scope)

#### Transactions (`transactions`)
- `_id`: ObjectId
- `userId`: ObjectId (indexed, ref: 'User')
- `type`: Enum ('income', 'expense')
- `amount`: Number (min: 0.01)
- `categoryId`: ObjectId (ref: 'Category')
- `date`: Date (indexed)
- `paymentMethod`: Enum ('Cash', 'Bank Transfer', 'UPI', 'Credit Card', 'Debit Card', 'Other')
- `description`: String
- `notes`: String
- **Compound Indexes**:
  - `{ userId: 1, date: -1 }` (reverse-chronological history)
  - `{ userId: 1, type: 1, date: -1 }` (filtered queries)
  - `{ userId: 1, categoryId: 1 }` (category usage verification)
  - `{ userId: 1, date: 1, type: 1 }` (aggregation pipelines)

---

## 4. Security & Data Isolation Guarantees

1. **User Data Isolation**: Every transaction and custom category query enforces `{ userId: req.user._id }`. Users can never read, modify, or delete another user's financial transactions.
2. **Zero In-Flutter Secrets**: Mobile clients do not hold database strings or signing keys. The Flutter app communicates exclusively with the REST API.
3. **Password Security**: Passwords are encrypted with `bcrypt` salt rounds. Password hashes are stripped before serialization (`userSchema.methods.toJSON`).
4. **Token Strategy**:
   - Access tokens: Short-lived (15 minutes).
   - Refresh tokens: Long-lived (7 days), exchanged via `/api/auth/refresh`.
5. **Rate Limiting**: Express rate limiters protect authentication endpoints against brute force attacks.
