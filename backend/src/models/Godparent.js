const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Godparent = sequelize.define('Godparent', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  // Polymorphic association - can belong to different booking types
  bookingType: {
    type: DataTypes.ENUM('baptism', 'wedding', 'confirmation'),
    allowNull: false,
  },
  bookingId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  // Godparent information
  fullName: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  contactEmail: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  contactPhone: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  address: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  // Additional information
  parishAffiliation: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  confirmationCertificateNumber: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
}, {
  tableName: 'godparents',
  timestamps: true,
  underscored: true,
  indexes: [
    { fields: ['booking_type'] },
    { fields: ['booking_id'] },
    {
      name: 'godparents_booking_lookup',
      fields: ['booking_type', 'booking_id'],
    },
  ],
});

module.exports = Godparent;
