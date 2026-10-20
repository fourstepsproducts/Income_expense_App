# Deployment and Production Setup Guide

This guide covers deploying the backend to production with MongoDB Atlas and building the Flutter Android release APK.

---

## 1. MongoDB Atlas Configuration

1. Create a free cluster on [MongoDB Atlas](https://www.mongodb.com/cloud/atlas).
2. Under **Database Access**, create a database user with `readWriteAnyDatabase` privileges.
3. Under **Network Access**, add an IP Access List entry (e.g. `0.0.0.0/0` for cloud services, or specific server IP).
4. Under **Clusters > Connect**, copy the Connection String:
   ```
   mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/finance_tracker?retryWrites=true&w=majority
   ```

---

## 2. Backend Deployment

### A. Deploying to Render / Railway / Heroku

1. Create a new Web Service pointing to the `backend/` folder.
2. Set Environment Variables:
   ```env
   NODE_ENV=production
   PORT=5000
   MONGODB_URI=mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/finance_tracker?retryWrites=true&w=majority
   JWT_ACCESS_SECRET=your_long_random_production_access_secret_here
   JWT_REFRESH_SECRET=your_long_random_production_refresh_secret_here
   ACCESS_TOKEN_EXPIRES_IN=15m
   REFRESH_TOKEN_EXPIRES_IN=7d
   CLIENT_ORIGIN=*
   ```
3. Build Command: `npm install`
4. Start Command: `npm start`
5. Optional: Run seed script once in production console to provision demo data:
   ```bash
   npm run seed
   ```

### B. Docker Deployment

A `Dockerfile` can be used for containerized hosting:

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 5000
CMD ["node", "src/server.js"]
```

---

## 3. Flutter Android APK Build

### Step 1: Configure Production API URL

Pass the production API URL at build time using `--dart-define`:

```bash
cd frontend
flutter build apk --release --dart-define=API_URL=https://your-finance-api.onrender.com/api
```

The APK will be generated at:
```
frontend/build/app/outputs/flutter-apk/app-release.apk
```

### Step 2: Testing on Android Emulator

For local testing with Android emulator:
```bash
flutter run --dart-define=API_URL=http://10.0.2.2:5000/api
```
*(Note: Android emulator maps host `localhost` to `10.0.2.2`)*

### Step 3: Testing on Physical Devices / LAN

Connect phone to same Wi-Fi as your development machine and run:
```bash
flutter run --dart-define=API_URL=http://<YOUR_LOCAL_IP>:5000/api
```
Or simply use the in-app **Settings > API Endpoint Configuration** dialog to change the server address at runtime without recompiling!
