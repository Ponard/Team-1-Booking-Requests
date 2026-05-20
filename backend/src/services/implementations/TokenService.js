/**
 * JWT Token Service Implementation
 */
const jwt = require('jsonwebtoken');

class TokenService {
  constructor() {
    this.jwtSecret = process.env.JWT_SECRET;
    this.refreshSecret = process.env.REFRESH_SECRET;
    this.jwtExpiry = process.env.JWT_EXPIRES_IN || '15m';
    this.refreshExpiry = process.env.REFRESH_EXPIRES_IN || '7d';
  }

  /**
   * Generates access and refresh tokens for a user
   */
  generateTokens(user) {
    const accessToken = this.generateAccessToken(user);
    const refreshToken = this.generateRefreshToken(user);

    return { accessToken, refreshToken };
  }

  /**
   * Generates only an access token
   */
  generateAccessToken(user) {
    return jwt.sign(
      {
        userId: user.id,
        role: user.role,
        email: user.email,
        assignedParishId: user.assignedParishId || null,
      },
      this.jwtSecret,
      { expiresIn: this.jwtExpiry }
    );
  }

  /**
   * Generates only a refresh token
   */
  generateRefreshToken(user) {
    return jwt.sign(
      { userId: user.id },
      this.refreshSecret,
      { expiresIn: this.refreshExpiry }
    );
  }

  /**
   * Verifies an access token
   */
  verifyAccessToken(token) {
    try {
      return jwt.verify(token, this.jwtSecret);
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        throw new Error('Access token expired');
      } else if (error.name === 'JsonWebTokenError') {
        throw new Error('Invalid access token');
      }
      throw error;
    }
  }

  /**
   * Verifies a refresh token
   */
  verifyRefreshToken(token) {
    try {
      return jwt.verify(token, this.refreshSecret);
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        throw new Error('Refresh token expired');
      } else if (error.name === 'JsonWebTokenError') {
        throw new Error('Invalid refresh token');
      }
      throw error;
    }
  }
}

module.exports = TokenService;
