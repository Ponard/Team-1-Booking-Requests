'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface) {
    await queryInterface.renameColumn(
      'mass_intentions',
      'preferred_time',
      'preferred_time_slot'
    );
  },

  async down(queryInterface) {
    await queryInterface.renameColumn(
      'mass_intentions',
      'preferred_time_slot',
      'preferred_time'
    );
  },
};
