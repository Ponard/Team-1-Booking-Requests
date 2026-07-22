'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface) {
    await queryInterface.renameColumn(
      'mass_intentions',
      'submitted_by',
      'user_id'
    );
  },

  async down(queryInterface) {
    await queryInterface.renameColumn(
      'mass_intentions',
      'user_id',
      'submitted_by'
    );
  },
};
