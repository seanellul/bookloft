# 🚄 Railway Deployment Guide

## Quick Start (5 minutes)

### 1. **Create Railway Account**
```bash
# Visit: https://railway.app
# Sign up with GitHub (free)
```

### 2. **Deploy from GitHub**
1. Go to Railway dashboard
2. Click "New Project"
3. Select "Deploy from GitHub repo"
4. Choose this repository
5. Select the `backend` folder as root directory

### 3. **Add Database**
1. In your Railway project
2. Click "New" → "Database" → "PostgreSQL"
3. Railway will auto-create a PostgreSQL database

### 4. **Set Environment Variables**
Railway will auto-detect some, but add these:

```env
# Railway provides DATABASE_URL automatically
JWT_SECRET=your-super-secret-jwt-key-here-make-it-long-and-random
JWT_EXPIRES_IN=24h
NODE_ENV=production
PORT=3000
CORS_ORIGIN=*
```

### 5. **Deploy Commands**
Railway auto-detects package.json, but ensure:
- **Build Command**: `npm install`
- **Start Command**: `npm start` (from Procfile)

### 6. **Update Flutter App**
Replace the API URL in your Flutter app:
```dart
// In lib/services/api_service.dart and lib/services/auth_service.dart
static const String baseUrl = 'https://your-app-name.up.railway.app/api';
```

## 🔧 Alternative: Render

If Railway doesn't work, try Render:

1. **Visit**: https://render.com
2. **Connect GitHub**: Link your repository
3. **New Web Service**: Select backend folder
4. **Settings**:
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Add PostgreSQL**: Create separate PostgreSQL service

## 🆘 Quick Fix for Current Cloudflare Workers

If you want to stick with Cloudflare Workers, the issue is likely:

1. **Missing Environment Variables**:
   ```bash
   # In Cloudflare Workers dashboard, add:
   JWT_SECRET=your-secret-key
   DATABASE_URL=your-database-connection-string
   ```

2. **Database Connection**: Cloudflare Workers need a different database setup (not SQLite)
   - Use Cloudflare D1 (SQLite) or
   - External PostgreSQL (like Neon, Supabase)

## 🎯 Recommended Next Steps

1. **Try Railway first** (easiest, most compatible with your current setup)
2. **If issues, fall back to Render**
3. **Update Flutter app with new URL**
4. **Test authentication endpoints**

Your backend is already production-ready! 🎉
