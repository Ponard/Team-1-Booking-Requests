/**
 * Use Case: Get Mass Intention by ID
 * Single responsibility: Handle retrieval of a single mass intention
 */
const MassIntentionDTO = require('../../dto/MassIntentionDTO');

class GetMassIntentionByIdUseCase {
  /**
   * @param {IMassIntentionRepository} massIntentionRepository
   */
  constructor(massIntentionRepository) {
    this.massIntentionRepository = massIntentionRepository;
  }

  /**
   * Executes the use case
   * @param {number} id - The mass intention ID
   * @param {Object} user - The authenticated user
   * @returns {Promise<MassIntentionDTO>}
   */
  async execute(id, user) {
    const intention = await this.massIntentionRepository.findById(id);

    if (!intention) {
      throw new Error('Mass intention not found');
    }

    // Check permissions
    this._checkAccessPermission(intention, user);

    return intention;
  }

  /**
   * Checks if user has permission to view the intention
   */
  _checkAccessPermission(intention, user) {
    if (user.role === 'parishioner' && intention.userId !== user.userId) {
      throw new Error('Access denied: You can only view your own mass intentions');
    }
  }
}

module.exports = GetMassIntentionByIdUseCase;
