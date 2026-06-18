# Admin Backend System Configuration

## Overview

This document describes the admin backend APIs and system configuration for the Diocese of Kalookan Booking System.

## Features Implemented

### 1. Admin Dashboard
- Statistics overview (parishes, users, bookings)
- Recent bookings display
- Bookings by status and type breakdowns

### 2. User Management
- Create, read, update, delete (soft delete) users
- Filter by role, parish, search, and active status
- Support for all user roles:
  - `diocese_admin` - Full system access
  - `parish_admin` - Parish-level administration
  - `parish_staff` - Parish booking management
  - `priest` - Priest-specific functions
  - `diocese_staff` - Diocese-level staff
  - `parishioner` - Regular user

### 3. Parish Management
- Create and manage parishes
- Configure parish services offered
- Set contact information and schedules
- Soft delete capability

### 4. System Configuration
Per-parish, per-sacrament configuration including:
- Daily/weekly/monthly booking limits
- Available time slots
- Blackout dates (holidays, special events)
- Mass schedules
- Booking cutoff periods
- Auto-approval settings
- Required documents
- Maximum number of godparents/sponsors
- Custom instructions

### 5. Booking Management
- View all bookings with advanced filtering
- Approve, reject, or reschedule bookings
- Manage bookings by sacrament type
- Add admin notes

### 6. Mass Intention Management
- View and manage all mass intentions
- Update status and add notes

### 7. Sacrament-Specific Booking Models

Dedicated models for each sacrament:
- **Baptism** - Child details, parents, godparents, birth certificate
- **Wedding** - Bride/groom details, CENOMAR, pre-cana, godparents
- **Confirmation** - Confirmand details, sponsors, preparation certificates
- **Eucharist** - First Communion, communicant details, parents
- **Reconciliation** - Confession scheduling
- **Anointing of the Sick** - Urgency levels, location (hospital/home)
- **Funeral Mass** - Deceased details, wake information, death certificate

## Setup Instructions

### 1. Environment Configuration

Copy `.env.example` to `.env.development` (or `.env.production`):

```bash
cp .env.example .env.development
```

Update the admin configuration:
```
DEFAULT_ADMIN_EMAIL=admin@diocese.kalookan.org
DEFAULT_ADMIN_PASSWORD=ChangeMe123!
DEFAULT_ADMIN_FIRST_NAME=Diocese
DEFAULT_ADMIN_LAST_NAME=Administrator
```

### 2. Database Migration

Run the database sync to create all tables:
```bash
npm run migrate
```

Or start the server (it will auto-sync):
```bash
npm start
```

### 3. Seed Initial Data

Populate the database with default admin user and sample parishes:
```bash
npm run seed
```

This creates:
- 1 diocese admin user
- 5 sample parishes
- Default configurations for all sacraments per parish

### 4. Start the Server

```bash
# Development
npm run dev

# Production
npm start
```

## API Endpoints

All admin endpoints are prefixed with `/api/admin`

### Dashboard
- `GET /api/admin/dashboard` - Get statistics

### Users
- `GET /api/admin/users` - List all users
- `GET /api/admin/users/:id` - Get user details
- `POST /api/admin/users` - Create user
- `PUT /api/admin/users/:id` - Update user
- `DELETE /api/admin/users/:id` - Delete user

### Parishes
- `GET /api/admin/parishes` - List all parishes
- `GET /api/admin/parishes/:id` - Get parish details
- `POST /api/admin/parishes` - Create parish
- `PUT /api/admin/parishes/:id` - Update parish
- `DELETE /api/admin/parishes/:id` - Delete parish

### Configurations
- `GET /api/admin/parishes/:parishId/configurations` - Get configurations
- `PUT /api/admin/parishes/:parishId/configurations/:configType` - Create/Update
- `DELETE /api/admin/configurations/:id` - Delete configuration

### Bookings
- `GET /api/admin/bookings` - List all bookings
- `GET /api/admin/bookings/:id` - Get booking details
- `PUT /api/admin/bookings/:id/status` - Update status
- `DELETE /api/admin/bookings/:id` - Delete booking

### Mass Intentions
- `GET /api/admin/mass-intentions` - List all mass intentions
- `PUT /api/admin/mass-intentions/:id/status` - Update status

## Authentication

All admin endpoints require JWT authentication. Include the token:
```
Authorization: Bearer <jwt_token>
```

Role-based authorization is enforced:
- `diocese_admin` - Full access to all endpoints
- `parish_admin` - Access limited to assigned parish
- `parish_staff` - Limited to booking management

## Database Schema

### New Tables Created
- `system_configurations` - Parish/sacrament configurations
- `baptism_bookings` - Baptism-specific bookings
- `wedding_bookings` - Wedding-specific bookings
- `confirmation_bookings` - Confirmation-specific bookings
- `eucharist_bookings` - First Communion bookings
- `reconciliation_bookings` - Confession bookings
- `anointing_sick_bookings` - Anointing of the Sick bookings
- `funeral_mass_bookings` - Funeral Mass bookings

### Updated Tables
- `users` - Added `diocese_admin` role
- `parishes` - Added `description` and `image_url` fields

## Configuration Options

### Time Slots Format
```json
["08:00", "09:00", "10:00", "14:00", "15:00", "16:00"]
```

### Blackout Dates Format
```json
[
  "2024-12-25",
  "2024-01-01",
  {"start": "2024-04-01", "end": "2024-04-07"}
]
```

### Mass Schedules Format
```json
[
  {"day": "Sunday", "time": "06:00"},
  {"day": "Sunday", "time": "08:00"},
  {"day": "Wednesday", "time": "06:00"}
]
```

### Required Documents
```json
["birth_certificate", "baptismal_certificate", "cenomar"]
```

## Security Notes

1. **Change Default Password**: Immediately change the default admin password after first login
2. **JWT Secrets**: Use strong, unique JWT secrets (minimum 256 bits)
3. **HTTPS**: Always use HTTPS in production
4. **Rate Limiting**: Admin endpoints are protected by rate limiting

## Testing

Test the admin endpoints:
```bash
# Get admin token first
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@diocese.kalookan.org","password":"ChangeMe123!"}'

# Use token to access admin endpoints
curl http://localhost:3000/api/admin/dashboard \
  -H "Authorization: Bearer <token>"
```

## Files Created/Modified

### New Files
- `src/models/SystemConfiguration.js`
- `src/models/BaptismBooking.js`
- `src/models/WeddingBooking.js`
- `src/models/ConfirmationBooking.js`
- `src/models/EucharistBooking.js`
- `src/models/ReconciliationBooking.js`
- `src/models/AnointingOfTheSickBooking.js`
- `src/models/FuneralMassBooking.js`
- `src/controllers/adminController.js`
- `src/routes/admin.js`
- `src/scripts/seed.js`
- `ADMIN_API.md`
- `ADMIN_SETUP.md`

### Modified Files
- `src/models/index.js` - Added new model associations
- `src/models/User.js` - Added `diocese_admin` role
- `src/models/Parish.js` - Added fields and associations
- `src/app.js` - Registered admin routes
- `.env.example` - Added admin configuration

## Next Steps

1. Run database migration
2. Seed initial data
3. Test all admin endpoints
4. Integrate with frontend admin dashboard
5. Set up email notifications for booking approvals
6. Implement PDF generation for Mass Intentions
7. Add calendar integration for scheduling

## Support

For issues or questions, refer to:
- API Documentation: `ADMIN_API.md`
- Main README: `README.md`
- Running Instructions: `RUNNING_APPS.md`
