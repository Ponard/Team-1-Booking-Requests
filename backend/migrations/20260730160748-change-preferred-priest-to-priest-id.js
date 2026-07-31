'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.removeColumn(
      'anointing_sick_bookings',
      'preferred_priest'
    );

    await queryInterface.addColumn('anointing_sick_bookings', 'priest_id', {
      type: Sequelize.INTEGER,
      allowNull: true,
      references: {
        model: 'users',
        key: 'id',
      },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL',
    });

    await queryInterface.addIndex(
      'anointing_sick_bookings',
      ['priest_id']
    );
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeIndex(
      'anointing_sick_bookings',
      ['priest_id']
    );

    await queryInterface.removeColumn(
      'anointing_sick_bookings',
      'priest_id'
    );

    await queryInterface.addColumn(
      'anointing_sick_bookings',
      'preferred_priest',
      {
        type: Sequelize.STRING,
        allowNull: true,
      }
    );
  },
};
