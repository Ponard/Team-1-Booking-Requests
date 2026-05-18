/**
 * Use Case: Get all Mass Intentions
 * Single responsibility: Handle retrieval of mass intentions with filtering
 */
const MassIntentionDTO = require('../../dto/MassIntentionDTO');

class GetAllMassIntentionsUseCase {
  /**
   * @param {IMassIntentionRepository} massIntentionRepository
   */
  constructor(massIntentionRepository) {
    this.massIntentionRepository = massIntentionRepository;
  }

  /**
   * Executes the use case
   * @param {Object} options - Query options
   * @param {Object} user - The authenticated user
   * @returns {Promise<{data: MassIntentionDTO[], pagination: Object}>}
   */
  async execute(options, user) {
    const { page, limit, filters } = this._prepareFilters(options, user);

    return await this.massIntentionRepository.findAll({
      page,
      limit,
      filters,
    });
  }

  /**
   * Prepares filters based on user role
   */
  _prepareFilters(options, user) {
    const page = parseInt(options.page) || 1;
    const limit = parseInt(options.limit) || 10;
    const filters = { ...options.filters };

    // Support flat query params for massSchedule date filtering
    if (options.massScheduleDate) {
      filters.massScheduleStart = options.massScheduleDate;
      filters.massScheduleEnd = options.massScheduleDate;
    }
    if (options.massScheduleStart) {
      filters.massScheduleStart = options.massScheduleStart;
    }
    if (options.massScheduleEnd) {
      filters.massScheduleEnd = options.massScheduleEnd;
    }

    // Role-based access control
    if (user.role === 'parishioner') {
      // Parishioners can only see their own intentions
      filters.submittedBy = user.userId;
    } else if (['parish_staff', 'priest'].includes(user.role)) {
      // Parish staff and priests can only see intentions for their assigned parishes
      // For now, they can see all; in production, link staff to specific parishes
      if (options.parishId) {
        filters.parishId = options.parishId;
      }
    }

    return { page, limit, filters };
  }
}

module.exports = GetAllMassIntentionsUseCase;
