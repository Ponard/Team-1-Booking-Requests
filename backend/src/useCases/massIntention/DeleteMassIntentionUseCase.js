/**
 * Use Case: Delete Mass Intention
 * Single responsibility: Handle deletion with role-based permissions
 */
class DeleteMassIntentionUseCase {
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
   * @returns {Promise<boolean>}
   */
  async execute(id, user) {
    // Get existing intention
    const intention = await this.massIntentionRepository.findById(id);
    if (!intention) {
      throw new Error('Mass intention not found');
    }

    // Check permissions
    this._checkDeletePermission(intention, user);

    // Perform deletion
    return await this.massIntentionRepository.delete(id);
  }

  /**
   * Checks if user has permission to delete the intention
   */
  _checkDeletePermission(intention, user) {
    const adminRoles = ['diocese_staff', 'diocese_admin'];

    if (adminRoles.includes(user.role)) {
      return; // Admins can delete anything
    }

    if (user.role === 'parishioner') {
      // Parishioners can only delete their own pending intentions
      if (intention.userId !== user.userId) {
        throw new Error('Access denied: You can only delete your own mass intentions');
      }
      if (intention.status !== 'pending') {
        throw new Error('Cannot delete mass intention once it is no longer pending');
      }
      return;
    }

    // Parish staff and priests cannot delete intentions
    if (['parish_staff', 'priest'].includes(user.role)) {
      throw new Error('Access denied: Parish staff and priests cannot delete mass intentions');
    }

    throw new Error('Insufficient permissions');
  }
}

module.exports = DeleteMassIntentionUseCase;
