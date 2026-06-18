# Postman Test Scripts Documentation

## Overview

This directory contains Postman collection and environment files for testing the Diocese Booking System API. The collection includes comprehensive test scripts for all backend endpoints with automated validation.

## Files

| File | Description |
|------|-------------|
| `Diocese-Booking-System.postman_collection.json` | Complete Postman collection with all API endpoints and test scripts |
| `Diocese-Booking-System.postman_environment.json` | Environment variables for the collection |

## Installation

### Step 1: Import Collection

1. Open Postman
2. Click **Import** button (top left)
3. Select `Diocese-Booking-System.postman_collection.json`
4. Click **Import**

### Step 2: Import Environment

1. In Postman, click the **gear icon** (Manage Environments)
2. Click **Import**
3. Select `Diocese-Booking-System.postman_environment.json`
4. Click **Import**

### Step 3: Select Environment

1. Click the environment dropdown (top right)
2. Select **Diocese Booking System - Environment**

## Environment Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `baseUrl` | API base URL | `http://localhost:3000` |
| `accessToken` | JWT access token (auto-populated after login) | - |
| `refreshToken` | JWT refresh token (auto-populated after login) | - |
| `adminId` | Admin user ID (auto-populated) | - |
| `userId` | User ID (auto-populated after creating user) | - |
| `parishId` | Parish ID (auto-populated after creating parish) | - |
| `bookingId` | Booking ID (auto-populated after creating booking) | - |
| `massIntentionId` | Mass intention ID (auto-populated) | - |

## Collection Structure

```
Diocese Booking System API
├── Health Check
│   ├── Health Status
│   └── API Info
├── Authentication
│   ├── Register User
│   ├── Login
│   ├── Login - Invalid Credentials
│   ├── Refresh Token
│   ├── Logout
│   └── Get Current User
├── Admin - Dashboard
│   └── Get Dashboard Statistics
├── Admin - Users
│   ├── List All Users
│   ├── Create New User
│   ├── Get User By ID
│   ├── Update User
│   └── Delete User (Soft Delete)
├── Admin - Parishes
│   ├── List All Parishes
│   ├── Create New Parish
│   ├── Get Parish By ID
│   ├── Update Parish
│   └── Delete Parish (Soft Delete)
├── Admin - Configurations
│   ├── Get Parish Configurations
│   ├── Create/Update Configuration
│   └── Delete Configuration
├── Admin - Bookings
│   ├── List All Bookings
│   ├── Create Booking
│   ├── Get Booking By ID
│   ├── Update Booking Status
│   ├── Update Booking
│   └── Delete Booking
├── Admin - Mass Intentions
│   ├── List All Mass Intentions
│   └── Update Mass Intention Status
├── Parishes (Public)
│   ├── Get All Parishes
│   ├── Get Parish By ID
│   ├── Search Parishes
│   └── Get Parishes By Service
├── Mass Intentions (User)
│   ├── Get All Mass Intentions
│   ├── Create Mass Intention
│   ├── Get Mass Intention By ID
│   ├── Update Mass Intention
│   ├── Approve Mass Intention
│   ├── Decline Mass Intention
│   └── Delete Mass Intention
├── Mass Schedules
│   ├── Get All Mass Schedules
│   └── Create Mass Schedule
├── Bookings (User)
│   ├── Get My Bookings
│   └── Create Booking
├── Files
│   └── Upload File
└── Mass Intentions - Notifications
    ├── Send Mass Intention Notifications
    └── Send Mass Intention Notifications By Date
```

## Running Tests

### Run Single Request

1. Navigate to the desired request in the collection
2. Click **Send**
3. View response and test results in the **Test Results** tab

### Run Entire Collection

1. Click on the collection name (**Diocese Booking System API**)
2. Click **Run** tab
3. Configure run settings:
   - **Environment**: Select "Diocese Booking System - Environment"
   - **Iterations**: 1
   - **Delay**: 100ms (recommended)
4. Click **Run Diocese Booking System API**

### Run via Newman (CLI)

```bash
# Install Newman globally
npm install -g newman

# Run collection with environment
newman run Diocese-Booking-System.postman_collection.json \
  -e Diocese-Booking-System.postman_environment.json

# Run with HTML report
newman run Diocese-Booking-System.postman_collection.json \
  -e Diocese-Booking-System.postman_environment.json \
  -r html --reporter-html-export report.html

# Run with JSON report
newman run Diocese-Booking-System.postman_collection.json \
  -e Diocese-Booking-System.postman_environment.json \
  -r json --reporter-json-export report.json
```

## Test Script Examples

### Authentication Tests

```javascript
// Login - Validate tokens and set environment variables
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has tokens", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.user).to.exist;
    pm.expect(jsonData.accessToken).to.exist;
    pm.expect(jsonData.refreshToken).to.exist;
    
    // Store tokens for subsequent requests
    pm.collectionVariables.set("accessToken", jsonData.accessToken);
    pm.collectionVariables.set("refreshToken", jsonData.refreshToken);
    pm.collectionVariables.set("adminId", jsonData.user.id);
});

pm.test("User has admin role", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.user.role).to.eql('diocese_admin');
});
```

### CRUD Operation Tests

```javascript
// Create User - Validate creation and store ID
pm.test("Status code is 201", function () {
    pm.response.to.have.status(201);
});

pm.test("Response has user data", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.success).to.be.true;
    pm.expect(jsonData.data).to.exist;
    pm.expect(jsonData.data.id).to.exist;
    
    // Store ID for subsequent requests
    pm.collectionVariables.set("userId", jsonData.data.id);
});

pm.test("Email format is valid", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.data.email).to.match(/^[^\s@]+@[^\s@]+\.[^\s@]+$/);
});
```

### Pagination Tests

```javascript
// List Users - Validate pagination structure
pm.test("Response has pagination", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.data.pagination).to.exist;
    pm.expect(jsonData.data.pagination.total).to.exist;
    pm.expect(jsonData.data.pagination.page).to.exist;
});
```

## API Endpoints Summary

### Authentication
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/auth/register` | Register new user | No |
| POST | `/api/auth/login` | Login user | No |
| POST | `/api/auth/refresh` | Refresh access token | No |
| POST | `/api/auth/logout` | Logout user | Yes |
| GET | `/api/auth/me` | Get current user | Yes |
| PUT | `/api/auth/me` | Update current user profile | Yes |
| PATCH | `/api/auth/change-password` | Change password | Yes |

### Admin - Dashboard
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/admin/dashboard` | Get dashboard statistics | Yes (Admin) |

### Admin - Users
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/admin/users` | List all users | Yes (Admin) |
| POST | `/api/admin/users` | Create new user | Yes (Admin) |
| GET | `/api/admin/users/:id` | Get user by ID | Yes (Admin) |
| PUT | `/api/admin/users/:id` | Update user | Yes (Admin) |
| DELETE | `/api/admin/users/:id` | Delete user (soft) | Yes (Admin) |

### Admin - Parishes
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/admin/parishes` | List all parishes | Yes (Admin) |
| POST | `/api/admin/parishes` | Create new parish | Yes (Admin) |
| GET | `/api/admin/parishes/:id` | Get parish by ID | Yes (Admin) |
| PUT | `/api/admin/parishes/:id` | Update parish | Yes (Admin) |
| DELETE | `/api/admin/parishes/:id` | Delete parish (soft) | Yes (Admin) |

### Admin - Configurations
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/admin/parishes/:parishId/configurations` | Get parish configurations | Yes (Admin) |
| PUT | `/api/admin/parishes/:parishId/configurations/:type` | Create/Update configuration | Yes (Admin) |
| DELETE | `/api/admin/configurations/:id` | Delete configuration | Yes (Admin) |

### Admin - Bookings
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/admin/bookings` | List all bookings | Yes (Admin) |
| POST | `/api/admin/bookings` | Create booking | Yes (Admin) |
| GET | `/api/admin/bookings/:id` | Get booking by ID | Yes (Admin) |
| PUT | `/api/admin/bookings/:id` | Update booking | Yes (Admin) |
| PUT | `/api/admin/bookings/:id/status` | Update booking status | Yes (Admin) |
| DELETE | `/api/admin/bookings/:id` | Delete booking | Yes (Admin) |

### Admin - Mass Intentions
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/admin/mass-intentions` | List all mass intentions | Yes (Admin) |
| PUT | `/api/admin/mass-intentions/:id/status` | Update mass intention status | Yes (Admin) |

### Parishes (Public)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/parishes` | Get all parishes | No |
| GET | `/api/parishes/:id` | Get parish by ID | No |
| GET | `/api/parishes/search` | Search parishes | No |
| GET | `/api/parishes/by-service/:service` | Get parishes by service | No |
| POST | `/api/parishes` | Create parish | Yes |
| PUT | `/api/parishes/:id` | Update parish | Yes |
| DELETE | `/api/parishes/:id` | Delete parish | Yes |

### Mass Intentions (User)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/mass-intentions` | Get all mass intentions | Yes |
| POST | `/api/mass-intentions` | Create mass intention | Yes |
| GET | `/api/mass-intentions/:id` | Get mass intention by ID | Yes |
| PUT | `/api/mass-intentions/:id` | Update mass intention | Yes |
| PATCH | `/api/mass-intentions/:id/approve` | Approve mass intention | Yes |
| PATCH | `/api/mass-intentions/:id/decline` | Decline mass intention | Yes |
| DELETE | `/api/mass-intentions/:id` | Delete mass intention | Yes |

### Mass Schedules
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/mass-schedules` | Get all mass schedules | Yes |
| POST | `/api/mass-schedules` | Create mass schedule | Yes |

### Bookings (User)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/bookings/my-bookings` | Get user's bookings | Yes |
| POST | `/api/bookings` | Create booking | Yes |

### Files
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/files/upload` | Upload file | Yes |

### Mass Intentions - Notifications
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/mass-intentions/send-notifications` | Send notifications | Yes |
| POST | `/api/mass-intentions/send-notifications-by-date` | Send notifications by date | Yes |

## User Roles

The API supports the following user roles with different access levels:

| Role | Access Level |
|------|-------------|
| `diocese_admin` | Full access to all parishes, users, and configurations |
| `parish_admin` | Access to assigned parish only |
| `diocese_staff` | Access to manage parishes and users |
| `parish_staff` | Limited access to parish bookings and configurations |
| `priest` | Access to mass intentions and schedules |
| `parishioner` | Basic user access for bookings |

## Test Data

The collection uses dynamic data generation:

- **Timestamp**: `{{timestamp}}` is automatically appended to emails and names to ensure uniqueness
- **IDs**: Resource IDs are automatically captured and stored in environment variables after creation

## Troubleshooting

### 401 Unauthorized
- Ensure you're logged in (run **Login** request first)
- Check that `accessToken` is populated in environment variables
- Token may have expired - run **Refresh Token** or **Login** again

### 403 Forbidden
- Your user may not have the required role for the endpoint
- Login with an admin account: `admin@diocese.kalookan.org` / `admin123`

### 404 Not Found
- Resource ID may not exist or was deleted
- Check that `{{userId}}`, `{{parishId}}`, etc. are populated

### Tests Failing
- Ensure the backend server is running on `http://localhost:3000`
- Check database connection and data
- Run requests in order (especially for dependent resources)

## CI/CD Integration

### GitHub Actions Example

```yaml
name: API Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm install
        working-directory: ./backend
      
      - name: Start server
        run: npm start &
        working-directory: ./backend
      
      - name: Wait for server
        run: sleep 10
      
      - name: Run Postman tests
        run: |
          npm install -g newman
          newman run backend/postman-tests/Diocese-Booking-System.postman_collection.json \
            -e backend/postman-tests/Diocese-Booking-System.postman_environment.json
```

## Best Practices

1. **Run in Order**: Execute requests in folder order to ensure dependencies are created
2. **Clean Up**: Delete test data after testing to keep database clean
3. **Environment Specific**: Create separate environments for dev, staging, and production
4. **Secure Secrets**: Never commit environment files with real credentials
5. **Regular Updates**: Update collection when API changes

## Support

For issues or questions:
1. Check the [ADMIN_API.md](../ADMIN_API.md) for API documentation
2. Review the [OpenAPI spec](../openapi.json) for detailed endpoint definitions
3. Check server logs for error details
