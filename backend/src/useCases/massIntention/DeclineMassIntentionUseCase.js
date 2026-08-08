/**
 * Use Case: Decline Mass Intention
 * Single responsibility: Handle declining of mass intentions
 */
class DeclineMassIntentionUseCase {
  /**
   * @param {IMassIntentionRepository} massIntentionRepository
   * @param {IEmailService} emailService
   */
  constructor(massIntentionRepository, emailService) {
    this.massIntentionRepository = massIntentionRepository;
    this.emailService = emailService;
  }

  /**
   * Executes the use case
   * @param {number} id - The mass intention ID
   * @param {Object} user - The authenticated user
   * @returns {Promise<MassIntentionDTO>}
   */
  async execute(id, user) {
    // Check role permission
    const allowedRoles = ['parish_staff', 'parish_admin', 'priest', 'diocese_staff', 'diocese_admin'];
    if (!allowedRoles.includes(user.role)) {
      throw new Error('Access denied: Only authorized personnel can decline mass intentions');
    }

    // Update status
    const declinedIntention = await this.massIntentionRepository.updateStatus(id, 'declined');

    // Send notification email (non-blocking)
    this._sendDeclineNotification(declinedIntention).catch(err => {
      console.error('Failed to send decline notification:', err);
    });

    return declinedIntention;
  }

  /**
   * Sends decline notification email
   */
  async _sendDeclineNotification(intention) {
    if (!this.emailService) return;

    await this.emailService.sendNotification(
      intention.email || 'user@example.com',
      'Mass Intention Update',
      `
        <h2>Mass Intention Update</h2>
        <p>Your mass intention (Reference: ${intention.id}) has been declined.</p>
        <p>Please contact the parish office for more information.</p>
        <br>
        <p>Best regards,<br>The Diocese of Kalookan Team</p>
      `
    );
  }
}

module.exports = DeclineMassIntentionUseCase;
