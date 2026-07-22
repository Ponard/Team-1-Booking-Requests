'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('mass_intentions', 'preferred_date', {
      type: Sequelize.DATEONLY,
      allowNull: true,
    });

    await queryInterface.sequelize.query(`
      UPDATE mass_intentions
      SET preferred_date = DATE(mass_schedule)
      WHERE mass_schedule IS NOT NULL;
    `);

    await queryInterface.changeColumn('mass_intentions', 'preferred_date', {
      type: Sequelize.DATEONLY,
      allowNull: false,
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('mass_intentions', 'preferred_date');
  },
};
