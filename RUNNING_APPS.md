# How to Run the Diocese Applications

This document provides detailed instructions for running both the backend server and the Flutter frontend application.

## Prerequisites

### Backend Requirements
- Node.js (v18 or higher)
- PostgreSQL (v15 or higher)
- Git

### Frontend Requirements
- Flutter SDK (latest stable version)
- Dart SDK (bundled with Flutter)
- Android Studio / VS Code with Flutter plugin
- For mobile testing: Android SDK or iOS development tools (macOS only)

## Setting Up the Backend Server

### 1. Navigate to the backend directory
```bash
cd backend
```

### 2. Install dependencies
```bash
npm install
```

### 3. Set up environment variables
- Copy the example environment file: `cp .env.example .env.development`
- Edit `.env.development` with your database credentials and other settings:
  - Update `DB_NAME`, `DB_USER`, `DB_PASSWORD` with your PostgreSQL credentials
  - Set appropriate JWT secrets
  - Configure email settings if needed

### 4. Set up the database
- Make sure PostgreSQL is running on your system
- Create the database specified in your .env file:
  ```sql
  -- Connect to PostgreSQL as superuser
  psql -U postgres
  -- Create the database
  CREATE DATABASE diocese_db_dev;
  \q
  ```

### 5. Run database migrations
```bash
npm run migrate
```

### 6. Start the backend server
```bash
npm run dev
```
The server will start on `http://cngqa-180-190-226-223.run.pinggy-free.link` (or the port specified in your .env file)

## Setting Up the Flutter App

### 1. Navigate to the frontend directory
```bash
cd frontend
```

### 2. Get Flutter dependencies
```bash
flutter pub get
```

### 3. Configure API Base URL
The app uses environment-based API configuration. By default, it points to:
- Development: `http://cngqa-180-190-226-223.run.pinggy-free.link` (for Android emulator)
- You can change this in `lib/config/app_constants.dart`

### 4. Make sure you have a device/emulator running:
- For Android: Start an Android emulator or connect an Android device via USB debugging
- For iOS: Start an iOS simulator (only on macOS)
- Check available devices with: `flutter devices`

### 5. Run the Flutter app
```bash
flutter run
```

## Running Both Applications Together

### Backend-first approach:
1. Start the backend server first: `npm run dev`
2. Verify the backend is running by accessing: `http://cngqa-180-190-226-223.run.pinggy-free.link/health`
3. Then start the Flutter app: `flutter run`

### Important Configuration Notes:

#### For Android Emulator:
- The default API URL in the Flutter app is configured for Android emulator (`http://cngqa-180-190-226-223.run.pinggy-free.link`)
- No changes needed for default setup

#### For iOS Simulator:
- Change the API URL in `lib/config/app_constants.dart` to `http://127.0.0.1:3000`

#### For Physical Devices:
- Use your computer's IP address: `http://YOUR_IP_ADDRESS:3000`
- Make sure your firewall allows connections on port 3000
- Find your IP address with:
  - Windows: `ipconfig`
  - Mac/Linux: `ifconfig` or `ip addr`

## Troubleshooting Common Issues

### Backend Issues:
- **Port already in use**: Check if another process is using port 3000
- **Database connection failed**: Verify PostgreSQL is running and credentials are correct
- **Migration errors**: Ensure database exists and user has proper permissions

### Flutter Issues:
- **No connected devices**: Make sure an emulator is running or device is connected
- **Connection errors**: Verify backend server is running and URL is correct
- **Dependency issues**: Run `flutter clean` and `flutter pub get`

### Network Issues:
- **Backend unreachable**: Check firewall settings and network connectivity
- **CORS errors**: Verify ALLOWED_ORIGINS in your backend .env file

## Development Workflow

For development, it's recommended to:
1. Keep the backend server running continuously
2. Use Flutter's hot reload feature for faster UI development
3. Monitor backend logs for API request debugging
4. Use tools like Postman to test API endpoints independently

## Production Deployment

For production deployment:
- Use `.env.production` for backend environment settings
- Build Flutter app for release: `flutter build apk` or `flutter build ios`
- Configure reverse proxy (nginx/Apache) for the backend
- Set up SSL certificates for secure connections