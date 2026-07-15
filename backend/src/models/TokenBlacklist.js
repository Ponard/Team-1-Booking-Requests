const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const TokenBlacklist = sequelize.define('TokenBlacklist', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  token: {
    type: DataTypes.STRING(500),
    allowNull: false,
    unique: true,
  },
  expiresAt: {
    type: DataTypes.DATE,
    allowNull: false,
  },
  blacklistedAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
  reason: {
    type: DataTypes.STRING,
    defaultValue: 'logout',
  },
}, {
  tableName: 'token_blacklist',
  timestamps: false,
  indexes: [
  ],
});

// Static method to check if token is blacklisted
TokenBlacklist.isBlacklisted = async (token) => {
  const blacklistedToken = await TokenBlacklist.findOne({
    where: {
      token: token,
      expiresAt: {
        [require('sequelize').Op.gt]: new Date(),
      },
    },
  });
  return !!blacklistedToken;
};

// Static method to add token to blacklist
TokenBlacklist.blacklist = async (token, expiresAt, reason = 'logout') => {
  try {
    await TokenBlacklist.create({
      token,
      expiresAt,
      reason,
    });
    return true;
  } catch (error) {
    if (error.name === 'SequelizeUniqueConstraintError') {
      // Token already blacklisted
      return true;
    }
    throw error;
  }
};

// Static method to clean up expired tokens
TokenBlacklist.cleanupExpired = async () => {
  try {
    const result = await TokenBlacklist.destroy({
      where: {
        expiresAt: {
          [require('sequelize').Op.lt]: new Date(),
        },
      },
    });
    return result;
  } catch (error) {
    console.error('Error cleaning up expired tokens:', error);
    return 0;
  }
};

module.exports = TokenBlacklist;
