'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    const bookingTables = [
      'mass_intentions'
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
      'mass_intentions'
    ];

    for (const table of bookingTables) {
      await queryInterface.removeIndex(table, `${table}_approval_stage`);
      await queryInterface.removeColumn(table, 'approval_stage');
    }
  },
};
