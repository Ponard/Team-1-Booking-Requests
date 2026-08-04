'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.sequelize.query(`
      CREATE TYPE enum_booking_approval_stage AS ENUM (
        'staff',
        'priest'
      );
    `);

    const bookingTables = [
      'baptism_bookings',
      'wedding_bookings',
      'confirmation_bookings',
      'eucharist_bookings',
      'reconciliation_bookings',
      'anointing_sick_bookings',
      'funeral_mass_bookings',
    ];

    for (const table of bookingTables) {
      await queryInterface.addColumn(table, 'approval_stage', {
        type: 'enum_booking_approval_stage',
        allowNull: false,
        defaultValue: 'staff',
      });

      await queryInterface.addIndex(table, ['approval_stage'], {
        name: `${table}_approval_stage`,
      });
    }
  },

  async down(queryInterface, Sequelize) {
    const bookingTables = [
      'baptism_bookings',
      'wedding_bookings',
      'confirmation_bookings',
      'eucharist_bookings',
      'reconciliation_bookings',
      'anointing_sick_bookings',
      'funeral_mass_bookings',
    ];

    for (const table of bookingTables) {
      await queryInterface.removeIndex(table, `${table}_approval_stage`);
      await queryInterface.removeColumn(table, 'approval_stage');
    }

    await queryInterface.sequelize.query(`
      DROP TYPE enum_booking_approval_stage;
    `);
  },
};
