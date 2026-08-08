/**
 * Use Case: Forward Mass Intention to Priest
 * Single responsibility: Handle forwarding of mass intentions
 * from staff review to priest review
 */
class ForwardMassIntentionToPriestUseCase {
  /**
   * @param {IMassIntentionRepository} massIntentionRepository
   * @param {IUserRepository} userRepository
   * @param {IEmailService} emailService
   */
  constructor(massIntentionRepository, userRepository, emailService) {
    this.massIntentionRepository = massIntentionRepository;
    this.userRepository = userRepository;
    this.emailService = emailService;
  }

  /**
   * Executes the use case
   *
   * Workflow:
   * pending/staff -> pending/priest
   *
   * @param {number} id - The mass intention ID
   * @param {Object} user - The authenticated user
   * @param {string} [notes] - Optional note from the staff member
   * @returns {Promise<MassIntentionDTO>}
   */
  async execute(id, user, notes) {
    // Check role permission
    const allowedRoles = [
      'parish_staff',
      'parish_admin',
      'diocese_staff',
      'diocese_admin',
    ];

    if (!allowedRoles.includes(user.role)) {
      throw new Error(
        'Access denied: Only authorized staff can forward mass intentions to a priest'
      );
    }

    // Get the mass intention
    const intention = await this.massIntentionRepository.findById(id);

    if (!intention) {
      throw new Error('Mass intention not found');
    }

    // Only pending mass intentions can be forwarded
    if (intention.status !== 'pending') {
      throw new Error(
        'Only pending mass intentions can be forwarded to the priest'
      );
    }

    // Only mass intentions currently awaiting staff review can be forwarded
    if (intention.approvalStage !== 'staff') {
      throw new Error(
        'This mass intention has already been forwarded to the priest'
      );
    }

    // Parish-level users may only manage intentions for their assigned parish
    if (['parish_staff', 'parish_admin'].includes(user.role)) {
      const assignedUser = await this.userRepository.findById(user.userId);

      if (!assignedUser) {
        throw new Error('User not found');
      }

      if (intention.parishId !== assignedUser.assignedParishId) {
        throw new Error(
          'Access denied: You are not authorized to manage this mass intention'
        );
      }
    }

    // Move the intention to the priest approval stage.
    // Status intentionally remains "pending".
    const forwardedIntention =
      await this.massIntentionRepository.updateApprovalStage(
        id,
        'priest'
      );

    // TODO: Add optional staff note
    // if (notes && notes.trim()) {
    //   await this.massIntentionRepository.addNote(id, {
    //     author: user.role,
    //     content: notes.trim(),
    //     authorId: user.userId,
    //     timestamp: new Date().toISOString(),
    //   });
    // }

    // Send notification email without blocking the request
    this._sendForwardNotification(forwardedIntention).catch((err) => {
      console.error(
        'Failed to send mass intention forwarding notification:',
        err
      );
    });

    // Return the latest state if a note was added
    if (notes && notes.trim()) {
      return this.massIntentionRepository.findById(id);
    }

    return forwardedIntention;
  }

  /**
   * Sends notification email to indicate that the mass intention
   * has been forwarded for priest confirmation.
   */
  async _sendForwardNotification(intention) {
    if (!this.emailService) return;

    await this.emailService.sendNotification(
      intention.email,
      'Mass Intention Sent for Priest Confirmation',
      `
        <h2>Mass Intention Sent for Priest Confirmation</h2>
        <p>
          Your mass intention (Reference: ${intention.id})
          has been reviewed by the parish staff and sent to the priest
          for confirmation.
        </p>
        <p>
          The mass intention will only be confirmed once the priest
          approves the request.
        </p>
        <p><strong>Details:</strong></p>
        <ul>
          <li>Type: ${intention.type}</li>
          <li>Requested Date: ${new Date(intention.massSchedule).toLocaleDateString()}</li>
        </ul>
        <br>
        <p>Best regards,<br>The Diocese of Kalookan Team</p>
      `
    );
  }
}

module.exports = ForwardMassIntentionToPriestUseCase;
