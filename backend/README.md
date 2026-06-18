# Diocese of Kalookan - Sacramental Booking System Backend

Backend API for the Diocese Sacramental Management System supporting Baptisms, Weddings, Confirmations, First Communion, Confession, Anointing of the Sick, Funeral Mass, and Mass Intentions.

## Features

### Sacrament Booking
- **Baptism**: Child baptism bookings with godparent management
- **Wedding**: Wedding bookings with seminar scheduling
- **Confirmation**: Confirmation bookings with sponsor management
- **First Communion (Eucharist)**: First Holy Communion bookings
- **Confession (Reconciliation)**: Confession session bookings
- **Anointing of the Sick**: Home/Hospital visit bookings
- **Funeral Mass**: Funeral mass bookings with wake information
- **Mass Intentions**: Mass intention requests (For the Dead, Thanksgiving, Special Intention)

### Parish Management
- Configurable daily/weekly booking limits per sacrament
- Custom time slots for each sacrament type
- Blackout dates (one-time or recurring)
- Advance booking windows (min/max days)
- Mass schedule management

### Document Management
- Upload required documents (birth certificates, baptismal certificates, etc.)
- Document verification by parish staff
- Proof of payment upload

### Payment Tracking
- Donation tracking
- Multiple payment methods (cash, GCash, PayMaya, bank transfer)
- Payment status management

### Sacramental Records
- Digitization of historical sacramental records
- Searchable database by name, date, parents, etc.
- Scanned document attachment
- Export capabilities

### User Roles
- **Parishioner**: Submit bookings, upload documents, check status
- **Parish Staff**: View/manage parish bookings, approve/decline requests
- **Parish Admin**: Full parish management, staff management
- **Priest**: View assigned sacraments
- **Diocese Staff**: Cross-parish oversight
- **Diocese Admin**: Full system access

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/google` - Google OAuth login

### Sacrament Bookings
- `POST /api/baptisms` - Create baptism booking
- `GET /api/baptisms` - Get baptism bookings
- `GET /api/baptisms/:id` - Get baptism booking details
- `PUT /api/baptisms/:id` - Update baptism booking
- `DELETE /api/baptisms/:id` - Cancel baptism booking
- `PATCH /api/baptisms/:id/status` - Approve/decline booking (admin)
- `GET /api/baptisms/available-slots` - Get available time slots

- `POST /api/sacraments/weddings` - Create wedding booking
- `GET /api/sacraments/weddings` - Get wedding bookings
- `POST /api/sacraments/confirmations` - Create confirmation booking
- `GET /api/sacraments/confirmations` - Get confirmation bookings
- `POST /api/sacraments/eucharist` - Create First Communion booking
- `POST /api/sacraments/reconciliations` - Create Confession booking
- `POST /api/sacraments/anointing-sick` - Create Anointing booking
- `POST /api/sacraments/funeral-mass` - Create Funeral Mass booking

### Parish Settings
- `GET /api/parish-settings/:parishId/slot-settings` - Get slot settings
- `POST /api/parish-settings/:parishId/slot-settings` - Create/update slot setting
- `GET /api/parish-settings/:parishId/blackout-dates` - Get blackout dates
- `POST /api/parish-settings/:parishId/blackout-dates` - Create blackout date
- `GET /api/parish-settings/:parishId/configuration` - Get parish configuration

### Sacramental Records
- `GET /api/sacramental-records` - Search records
- `POST /api/sacramental-records` - Create record (digitization)
- `GET /api/sacramental-records/:id` - Get record details
- `PUT /api/sacramental-records/:id` - Update record
- `DELETE /api/sacramental-records/:id` - Delete record
- `GET /api/sacramental-records/export` - Export records

### Payments
- `GET /api/payments` - Get payments
- `POST /api/payments` - Create payment
- `GET /api/payments/:id` - Get payment details
- `PUT /api/payments/:id` - Update payment

### Mass Intentions
- `GET /api/mass-intentions` - Get mass intentions
- `POST /api/mass-intentions` - Create mass intention
- `GET /api/mass-schedules` - Get mass schedules
- `POST /api/mass-schedules` - Create mass schedule

## Installation

### Prerequisites
- Node.js >= 18.0.0
- PostgreSQL database

### Setup

1. Install dependencies:
```bash
npm install
```

2. Configure environment:
```bash
cp .env.example .env.development
```

Edit `.env.development` with your database credentials and other settings.

3. Run database migrations:
```bash
npm run migrate
```

4. Seed sample data (optional):
```bash
npm run seed
```

5. Start the server:
```bash
# Development
npm run dev

# Production
npm start
```

## Default Credentials (After Seeding)

| Role | Email | Password |
|------|-------|----------|
| Diocese Admin | diocese.admin@diocese-kalookan.com | Password123! |
| Parish Admin | parish.admin@olpparish.org | Password123! |
| Parishioner | parishioner1@example.com | Password123! |

**⚠️ Change these passwords in production!**

## API Documentation

Access the Swagger UI at: `http://localhost:3000/api-docs`

Or view the OpenAPI spec in `openapi.json`.

## Database Schema

### Core Tables
- `users` - User accounts
- `parishes` - Parish information
- `bookings` - General bookings (legacy)
- `mass_intentions` - Mass intention requests
- `mass_schedules` - Regular mass schedules

### Sacrament Booking Tables
- `baptism_bookings` - Baptism requests
- `wedding_bookings` - Wedding requests
- `confirmation_bookings` - Confirmation requests
- `eucharist_bookings` - First Communion requests
- `reconciliation_bookings` - Confession requests
- `anointing_sick_bookings` - Anointing of the Sick requests
- `funeral_mass_bookings` - Funeral Mass requests

### Configuration Tables
- `parish_slot_settings` - Booking limits and time slots
- `blackout_dates` - Unavailable dates

### Supporting Tables
- `godparents` - Godparent/sponsor information
- `booking_documents` - Uploaded documents
- `payments` - Payment records
- `sacramental_records` - Historical sacramental records

## Booking Workflow

1. **Submission**: Parishioner submits booking request with required information
2. **Email Confirmation**: Automatic email confirmation sent
3. **Review**: Parish staff reviews the request
4. **Approval/Decline**: Staff approves or declines with optional notes
5. **Notification**: Email notification sent with status update
6. **Payment**: Payment/donation processed (if applicable)
7. **Completion**: Sacrament administered, record marked complete

## Time Slot Management

Each parish can configure:
- **Daily Limits**: Maximum bookings per day
- **Weekly Limits**: Maximum bookings per week
- **Time Slots**: Available time windows with capacity
- **Advance Booking**: Min/max days in advance
- **Cutoff Times**: Same-day booking cutoff

## Blackout Dates

Parishes can set blackout dates:
- **Service-Specific**: Apply to specific sacrament types
- **Recurring**: Yearly, monthly, or weekly recurrence
- **Reason**: Optional explanation (e.g., "Holy Week")

## License

MIT
