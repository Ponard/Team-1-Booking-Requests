/**
 * Database Seed Script
 * Populates the database with sample data for development and testing
 */

require('dotenv').config({
  path: `.env.${process.env.NODE_ENV || 'development'}`
});

const { sequelize } = require('../config/database');
const {
  User,
  Parish,
  BaptismBooking,
  WeddingBooking,
  ConfirmationBooking,
  EucharistBooking,
  ReconciliationBooking,
  AnointingSickBooking,
  FuneralMassBooking,
  ParishSlotSetting,
  BlackoutDate,
  Godparent,
  MassIntention,
  MassSchedule,
  SacramentalRecord,
} = require('../models');

async function seedDatabase() {
  console.log('🌱 Starting database seeding...');

  try {
    // Check if already seeded
    const existingUsers = await User.count();
    if (existingUsers > 5) {
      console.log('ℹ️  Database already has sample data. Skipping seed.');
      console.log('   To re-seed, run with force option or clear data manually.');
      process.exit(0);
    }

    // Create sample parishes
    console.log('📍 Creating sample parishes...');
    const parishes = await Parish.bulkCreate([
      {
        name: 'Our Lady of Peace Parish',
        address: '123 Main Street, Kalookan City',
        contactEmail: 'info@olpparish.org',
        contactPhone: '+639123456789',
        contactPerson: 'Parish Secretary',
        servicesOffered: ['baptism', 'wedding', 'confirmation', 'eucharist', 'reconciliation', 'anointing_sick', 'funeral_mass', 'mass_intention'],
        sacramentSettings: {
          baptism: { maxGodparents: 4 },
          wedding: { maxGodparents: 8 },
          confirmation: { maxGodparents: 2 }
        },
        bookingSettings: { autoApprove: false, emailNotifications: true },
        isActive: true,
      },
      {
        name: 'St. John the Baptist Parish',
        address: '456 Church Road, Kalookan City',
        contactEmail: 'info@sjbparish.org',
        contactPhone: '+639234567890',
        contactPerson: 'Parish Admin',
        servicesOffered: ['baptism', 'wedding', 'confirmation', 'eucharist', 'reconciliation', 'mass_intention'],
        sacramentSettings: {
          baptism: { maxGodparents: 3 },
          wedding: { maxGodparents: 6 },
          confirmation: { maxGodparents: 1 }
        },
        bookingSettings: { autoApprove: false, emailNotifications: true },
        isActive: true,
      },
      {
        name: 'San Roque Parish',
        address: '789 Faith Avenue, Kalookan City',
        contactEmail: 'info@sanroqueparish.org',
        contactPhone: '+639345678901',
        contactPerson: 'Parish Coordinator',
        servicesOffered: ['baptism', 'wedding', 'confirmation', 'eucharist', 'anointing_sick', 'funeral_mass', 'mass_intention'],
        sacramentSettings: {
          baptism: { maxGodparents: 4 },
          wedding: { maxGodparents: 10 },
          confirmation: { maxGodparents: 2 }
        },
        bookingSettings: { autoApprove: false, emailNotifications: true },
        isActive: true,
      },
    ]);

    console.log(`✅ Created ${parishes.length} parishes.`);

    // Create sample users
    console.log('👥 Creating sample users...');
    const users = await User.bulkCreate([
      // Diocese Admin
      {
        email: 'diocese.admin@diocese-kalookan.com',
        password: 'Password123!',
        firstName: 'Maria',
        lastName: 'Santos',
        phone: '+639111111111',
        role: 'diocese_admin',
        isActive: true,
      },
      // Diocese Staff
      {
        email: 'diocese.staff@diocese-kalookan.com',
        password: 'Password123!',
        firstName: 'Jose',
        lastName: 'Reyes',
        phone: '+639222222222',
        role: 'diocese_staff',
        isActive: true,
      },
      // Parish Admin - Our Lady of Peace
      {
        email: 'parish.admin@olpparish.org',
        password: 'Password123!',
        firstName: 'Ana',
        lastName: 'Cruz',
        phone: '+639333333333',
        role: 'parish_admin',
        assignedParishId: parishes[0].id,
        isActive: true,
      },
      // Parish Staff - Our Lady of Peace
      {
        email: 'parish.staff@olpparish.org',
        password: 'Password123!',
        firstName: 'Pedro',
        lastName: 'Garcia',
        phone: '+639444444444',
        role: 'parish_staff',
        assignedParishId: parishes[0].id,
        isActive: true,
      },
      // Priest
      {
        email: 'fr.juan@diocese-kalookan.com',
        password: 'Password123!',
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        phone: '+639555555555',
        role: 'priest',
        assignedParishId: parishes[0].id,
        isActive: true,
      },
      // Parishioners
      {
        email: 'parishioner1@example.com',
        password: 'Password123!',
        firstName: 'Carlos',
        lastName: 'Mendoza',
        phone: '+639666666666',
        role: 'parishioner',
        isActive: true,
      },
      {
        email: 'parishioner2@example.com',
        password: 'Password123!',
        firstName: 'Rosa',
        lastName: 'Torres',
        phone: '+639777777777',
        role: 'parishioner',
        isActive: true,
      },
      {
        email: 'parishioner3@example.com',
        password: 'Password123!',
        firstName: 'Miguel',
        lastName: 'Flores',
        phone: '+639888888888',
        role: 'parishioner',
        isActive: true,
      },
    ], { individualHooks: true });

    console.log(`✅ Created ${users.length} users.`);

    // Create Parish Slot Settings
    console.log('⚙️  Creating parish slot settings...');
    const slotSettings = [];
    
    for (const parish of parishes) {
      // Baptism settings
      slotSettings.push(await ParishSlotSetting.create({
        parishId: parish.id,
        serviceType: 'baptism',
        dailyLimit: 5,
        timeSlots: [
          { start: '09:00', end: '10:00', capacity: 1 },
          { start: '10:00', end: '11:00', capacity: 1 },
          { start: '13:00', end: '14:00', capacity: 1 },
          { start: '14:00', end: '15:00', capacity: 1 },
          { start: '15:00', end: '16:00', capacity: 1 },
        ],
        minAdvanceDays: 3,
        maxAdvanceDays: 60,
        isActive: true,
      }));

      // Wedding settings
      slotSettings.push(await ParishSlotSetting.create({
        parishId: parish.id,
        serviceType: 'wedding',
        dailyLimit: 2,
        weeklyLimit: 4,
        timeSlots: [
          { start: '08:00', end: '10:00', capacity: 1 },
          { start: '14:00', end: '16:00', capacity: 1 },
          { start: '16:00', end: '18:00', capacity: 1 },
        ],
        minAdvanceDays: 30,
        maxAdvanceDays: 180,
        isActive: true,
      }));

      // Confirmation settings
      slotSettings.push(await ParishSlotSetting.create({
        parishId: parish.id,
        serviceType: 'confirmation',
        dailyLimit: 10,
        timeSlots: [
          { start: '09:00', end: '11:00', capacity: 5 },
          { start: '13:00', end: '15:00', capacity: 5 },
        ],
        minAdvanceDays: 7,
        maxAdvanceDays: 90,
        isActive: true,
      }));

      // Mass Intention settings
      slotSettings.push(await ParishSlotSetting.create({
        parishId: parish.id,
        serviceType: 'mass_intention',
        dailyLimit: 20,
        cutoffTime: '06:00',
        minAdvanceDays: 1,
        maxAdvanceDays: 30,
        isActive: true,
      }));
    }

    console.log(`✅ Created ${slotSettings.length} slot settings.`);

    // Create Blackout Dates
    console.log('📅 Creating blackout dates...');
    const blackoutDates = await BlackoutDate.bulkCreate([
      {
        parishId: parishes[0].id,
        date: '2025-12-25',
        serviceType: null,
        reason: 'Christmas Day - No Sacraments',
        isRecurring: true,
        recurrencePattern: 'yearly',
        createdBy: users[0].id,
      },
      {
        parishId: parishes[0].id,
        date: '2025-01-01',
        serviceType: null,
        reason: 'New Year Day - No Sacraments',
        isRecurring: true,
        recurrencePattern: 'yearly',
        createdBy: users[0].id,
      },
      {
        parishId: parishes[0].id,
        date: '2025-03-29',
        serviceType: 'wedding',
        reason: 'Holy Week - No Weddings',
        isRecurring: false,
        createdBy: users[0].id,
      },
      {
        parishId: parishes[0].id,
        date: '2025-04-05',
        serviceType: 'baptism',
        reason: 'Easter Sunday - No Baptisms',
        isRecurring: false,
        createdBy: users[0].id,
      },
    ]);

    console.log(`✅ Created ${blackoutDates.length} blackout dates.`);

    // Create Mass Schedules
    console.log('⛪ Creating mass schedules...');
    const massSchedules = await MassSchedule.bulkCreate([
      {
        parishId: parishes[0].id,
        dayOfWeek: 'Sunday',
        startTime: '07:00',
        endTime: '08:00',
        intentionCutoffTime: '06:00',
        isActive: true,
        notes: 'Sunday Morning Mass',
      },
      {
        parishId: parishes[0].id,
        dayOfWeek: 'Sunday',
        startTime: '09:00',
        endTime: '10:00',
        intentionCutoffTime: '06:00',
        isActive: true,
        notes: 'Sunday Main Mass',
      },
      {
        parishId: parishes[0].id,
        dayOfWeek: 'Sunday',
        startTime: '18:00',
        endTime: '19:00',
        intentionCutoffTime: '06:00',
        isActive: true,
        notes: 'Sunday Evening Mass',
      },
      {
        parishId: parishes[0].id,
        dayOfWeek: 'Wednesday',
        startTime: '06:00',
        endTime: '07:00',
        intentionCutoffTime: '05:00',
        isActive: true,
        notes: 'Weekday Mass',
      },
      {
        parishId: parishes[0].id,
        dayOfWeek: 'Saturday',
        startTime: '18:00',
        endTime: '19:00',
        intentionCutoffTime: '06:00',
        isActive: true,
        notes: 'Vigil Mass',
      },
    ]);

    console.log(`✅ Created ${massSchedules.length} mass schedules.`);

    // Create sample Baptism Bookings
    console.log('👶 Creating sample baptism bookings...');
    const baptismBookings = await BaptismBooking.bulkCreate([
      {
        parishId: parishes[0].id,
        userId: users[5].id,
        childFullName: 'Sofia Mendoza',
        dateOfBirth: '2025-01-10',
        fatherName: 'Carlos Mendoza',
        motherName: 'Elena Mendoza',
        contactEmail: 'parishioner1@example.com',
        contactPhone: '+639666666666',
        preferredDate: '2025-03-15',
        preferredTimeSlot: '09:00-10:00',
        preferredPriest: 'Fr. Juan Dela Cruz',
        additionalNotes: 'First child, special occasion',
        status: 'pending',
      },
      {
        parishId: parishes[0].id,
        userId: users[6].id,
        childFullName: 'Mateo Torres',
        dateOfBirth: '2024-12-20',
        fatherName: 'Roberto Torres',
        motherName: 'Rosa Torres',
        contactEmail: 'parishioner2@example.com',
        contactPhone: '+639777777777',
        preferredDate: '2025-03-22',
        preferredTimeSlot: '10:00-11:00',
        status: 'pending',
      },
    ]);

    console.log(`✅ Created ${baptismBookings.length} baptism bookings.`);

    // Create sample Wedding Bookings
    console.log('💒 Creating sample wedding bookings...');
    const weddingBookings = await WeddingBooking.bulkCreate([
      {
        parishId: parishes[0].id,
        userId: users[7].id,
        groomFullName: 'Miguel Flores',
        brideFullName: 'Isabella Rodriguez',
        contactEmail: 'parishioner3@example.com',
        contactPhone: '+639888888888',
        preferredDate: '2025-06-14',
        preferredTimeSlot: '16:00-18:00',
        preferredPriest: 'Fr. Juan Dela Cruz',
        seminarSchedule: '2025-05-15',
        additionalNotes: 'Garden wedding preferred',
        status: 'pending',
      },
    ]);

    console.log(`✅ Created ${weddingBookings.length} wedding bookings.`);

    // Create sample Confirmation Bookings
    console.log('✝️  Creating sample confirmation bookings...');
    const confirmationBookings = await ConfirmationBooking.bulkCreate([
      {
        parishId: parishes[0].id,
        userId: users[5].id,
        confirmandName: 'Luis Mendoza',
        fatherName: 'Carlos Mendoza',
        motherName: 'Elena Mendoza',
        contactEmail: 'parishioner1@example.com',
        contactPhone: '+639666666666',
        preferredDate: '2025-04-20',
        preferredTimeSlot: '09:00-11:00',
        status: 'pending',
      },
    ]);

    console.log(`✅ Created ${confirmationBookings.length} confirmation bookings.`);

    // Create sample Mass Intentions
    console.log('🙏 Creating sample mass intentions...');
    const massIntentions = await MassIntention.bulkCreate([
      {
        parishId: parishes[0].id,
        submittedBy: users[5].id,
        type: 'For the Dead',
        intentionDetails: 'For the souls of departed grandparents',
        donorName: 'Carlos Mendoza',
        dateRequested: '2025-02-15',
        massSchedule: '2025-02-23T07:00:00.000Z',
        preferredPriest: 'Fr. Juan Dela Cruz',
        status: 'pending',
      },
      {
        parishId: parishes[0].id,
        submittedBy: users[6].id,
        type: 'Thanksgiving',
        intentionDetails: 'Thanksgiving for new job',
        donorName: 'Rosa Torres',
        dateRequested: '2025-02-16',
        massSchedule: '2025-02-23T09:00:00.000Z',
        status: 'pending',
      },
      {
        parishId: parishes[0].id,
        submittedBy: users[7].id,
        type: 'Special Intention',
        intentionDetails: 'For good health and guidance',
        donorName: 'Miguel Flores',
        dateRequested: '2025-02-17',
        massSchedule: '2025-02-23T18:00:00.000Z',
        status: 'pending',
      },
    ]);

    console.log(`✅ Created ${massIntentions.length} mass intentions.`);

    // Create sample Sacramental Records
    console.log('📜 Creating sample sacramental records...');
    const sacramentalRecords = await SacramentalRecord.bulkCreate([
      {
        parishId: parishes[0].id,
        sacramentType: 'baptism',
        personName: 'Jose Santos',
        dateOfBirth: '1990-05-15',
        fatherName: 'Antonio Santos',
        motherName: 'Maria Santos',
        sacramentDate: '1990-06-20',
        sacramentLocation: 'Our Lady of Peace Parish',
        officiatingPriest: 'Fr. Pedro Reyes',
        certificateNumber: 'BAP-1990-00123',
        registerNumber: '00123',
        page: '45',
        year: 1990,
        hasScannedCopy: false,
        digitizedBy: users[0].id,
        digitizedAt: new Date(),
      },
      {
        parishId: parishes[0].id,
        sacramentType: 'confirmation',
        personName: 'Jose Santos',
        dateOfBirth: '1990-05-15',
        fatherName: 'Antonio Santos',
        motherName: 'Maria Santos',
        sacramentDate: '2005-08-15',
        sacramentLocation: 'Our Lady of Peace Parish',
        officiatingPriest: 'Bishop Juan Gomez',
        certificateNumber: 'CON-2005-00456',
        registerNumber: '00456',
        page: '78',
        year: 2005,
        hasScannedCopy: false,
        digitizedBy: users[0].id,
        digitizedAt: new Date(),
      },
      {
        parishId: parishes[0].id,
        sacramentType: 'wedding',
        personName: 'Antonio Santos',
        spouseName: 'Maria Reyes',
        dateOfBirth: '1965-03-10',
        sacramentDate: '1988-12-10',
        sacramentLocation: 'Our Lady of Peace Parish',
        officiatingPriest: 'Fr. Luis Cruz',
        certificateNumber: 'WED-1988-00789',
        registerNumber: '00789',
        page: '12',
        year: 1988,
        hasScannedCopy: false,
        digitizedBy: users[0].id,
        digitizedAt: new Date(),
      },
    ]);

    console.log(`✅ Created ${sacramentalRecords.length} sacramental records.`);

    // Summary
    console.log('\n🎉 Database seeding completed successfully!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 Summary:');
    console.log(`   - ${parishes.length} Parishes`);
    console.log(`   - ${users.length} Users`);
    console.log(`   - ${slotSettings.length} Slot Settings`);
    console.log(`   - ${blackoutDates.length} Blackout Dates`);
    console.log(`   - ${massSchedules.length} Mass Schedules`);
    console.log(`   - ${baptismBookings.length} Baptism Bookings`);
    console.log(`   - ${weddingBookings.length} Wedding Bookings`);
    console.log(`   - ${confirmationBookings.length} Confirmation Bookings`);
    console.log(`   - ${massIntentions.length} Mass Intentions`);
    console.log(`   - ${sacramentalRecords.length} Sacramental Records`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🔐 Sample Login Credentials:');
    console.log('   Diocese Admin: diocese.admin@diocese-kalookan.com / Password123!');
    console.log('   Parish Admin: parish.admin@olpparish.org / Password123!');
    console.log('   Parishioner: parishioner1@example.com / Password123!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    process.exit(0);
  } catch (error) {
    console.error('❌ Seeding failed:', error.message);
    console.error('Stack trace:', error.stack);
    process.exit(1);
  }
}

// Run the seeder
seedDatabase();
