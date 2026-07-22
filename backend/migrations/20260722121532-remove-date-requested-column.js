'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface) {
    await queryInterface.removeColumn(
      'mass_intentions',
      'date_requested'
    );
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.addColumn(
      'mass_intentions',
      'date_requested',
      {
        type: Sequelize.DATEONLY,
        allowNull: false,
      }
    );
  },
};
