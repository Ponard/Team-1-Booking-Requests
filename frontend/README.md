# Diocese Flutter Frontend

Diocese of Kalookan Sacramental Management System - Mobile Application

## Overview

This is a Flutter mobile application that serves as the frontend for the Diocese of Kalookan backend API. It provides a user-friendly interface for parishioners to book sacraments, submit mass intentions, and manage their accounts.

## Features

- **User Authentication**: Login, registration, and profile management
- **Sacrament Booking**: Request baptism, wedding, and confirmation bookings
- **Mass Intentions**: Submit and track mass intentions
- **Document Upload**: Upload required documents for bookings
- **Notifications**: Real-time updates on booking status
- **Responsive UI**: Works on various screen sizes and orientations

## Tech Stack

- **Flutter**: Cross-platform mobile development
- **Dart**: Programming language
- **HTTP Client**: For API communication
- **Provider**: State management
- **Shared Preferences**: Local storage
- **Image Picker**: For document/image uploads
- **Intl**: Internationalization support

## Project Structure

```
lib/
├── main.dart                # App entry point
├── config/
│   ├── api_config.dart      # API configuration
│   └── app_constants.dart   # App constants
├── models/
│   ├── user.dart            # User model
│   ├── booking.dart         # Booking model
│   ├── intention.dart       # Mass intention model
│   └── api_response.dart    # API response wrapper
├── services/
│   ├── api_service.dart     # HTTP client wrapper
│   ├── auth_service.dart    # Authentication service
│   ├── booking_service.dart # Booking service
│   ├── file_service.dart    # File upload service
│   └── storage_service.dart # Local storage service
├── providers/
│   ├── auth_provider.dart   # Authentication state
│   ├── booking_provider.dart # Booking state
│   └── app_provider.dart    # Main app state
├── screens/
│   ├── splash_screen.dart   # Splash screen
│   ├── login_screen.dart    # Login screen
│   ├── register_screen.dart # Registration screen
│   ├── home_screen.dart     # Home/dashboard screen
│   ├── booking/
│   │   ├── booking_list_screen.dart
│   │   ├── create_booking_screen.dart
│   │   └── booking_detail_screen.dart
│   ├── intentions/
│   │   ├── intention_list_screen.dart
│   │   ├── create_intention_screen.dart
│   │   └── intention_detail_screen.dart
│   └── profile/
│       ├── profile_screen.dart
│       └── edit_profile_screen.dart
├── widgets/
│   ├── custom_button.dart   # Reusable button widget
│   ├── text_field.dart      # Custom text field
│   ├── loading_indicator.dart # Loading widget
│   └── error_widget.dart    # Error display widget
└── utils/
    ├── validators.dart      # Input validation
    ├── formatters.dart      # Data formatting
    └── helpers.dart         # Helper functions
```

## Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Dart SDK (bundled with Flutter)
- Android Studio / VS Code with Flutter plugin

### Installation

1. Clone the repository
2. Navigate to the frontend directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the application:
   ```bash   flutter run
   ```

## Environment Configuration

Create a `.env` file in the project root with the following variables:

```
API_BASE_URL=https://cngqa-180-190-226-223.run.pinggy-free.link  # For Android emulator
# API_BASE_URL=http://127.0.0.1:3000  # For iOS simulator
```

## API Integration

The app integrates with the Diocese backend API. All API endpoints are configured in `lib/config/api_config.dart`.

### Base URLs
- **Development**: https://cngqa-180-190-226-223.run.pinggy-free.link (Android emulator) or http://127.0.0.1:3000 (iOS simulator)
- **Production**: https://api.diocese-kalookan.com

### Authentication

The app uses JWT-based authentication. Tokens are stored locally and attached to all protected API requests.

## State Management

The app uses Provider for state management. Authentication state, booking data, and other app states are managed through dedicated providers.

## Security

- All API requests use HTTPS in production
- Sensitive data is encrypted locally
- JWT tokens have short expiration times
- Biometric authentication for sensitive operations

## Testing

Unit and widget tests are located in the `test/` directory:

```bash
flutter test
```

Integration tests are located in the `integration_test/` directory:

```bash
flutter drive --target=integration_test/app_test.dart
```

## Building for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new features
5. Commit your changes
6. Push to the branch
7. Create a pull request

## License

MIT License