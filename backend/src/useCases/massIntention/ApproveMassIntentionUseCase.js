/**
 * Use Case: Approve Mass Intention
 * Single responsibility: Handle approval of mass intentions
 */
class ApproveMassIntentionUseCase {
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
      throw new Error('Access denied: Only authorized personnel can approve mass intentions');
    }

    // Update status
    const approvedIntention = await this.massIntentionRepository.updateStatus(id, 'approved');

    // Send notification email (non-blocking)
    this._sendApprovalNotification(approvedIntention).catch(err => {
      console.error('Failed to send approval notification:', err);
    });

    return approvedIntention;
  }

  /**
   * Sends approval notification email
   */
  async _sendApprovalNotification(intention) {
    if (!this.emailService) return;

    // In production, get user email from repository
    await this.emailService.sendNotification(
      intention.email || 'user@example.com',
      'Mass Intention Approved',
      `
        <h2>Mass Intention Approved</h2>
        <p>Your mass intention (Reference: ${intention.id}) has been approved.</p>
        <p><strong>Details:</strong></p>
        <ul>
          <li>Type: ${intention.type}</li>
          <li>Scheduled Date: ${new Date(intention.massSchedule).toLocaleDateString()}</li>
        </ul>
        <br>
        <p>Best regards,<br>The Diocese of Kalookan Team</p>
      `
    );
  }
}

module.exports = ApproveMassIntentionUseCase;
