/**
 * Data Transfer Object for Mass Intention
 * Encapsulates request/response data and provides validation
 */
class MassIntentionDTO {
  constructor({
    id,
    type,
    intentionDetails,
    donorName,
    parishId,
    parishName,
    preferredDate,
    preferredTimeSlot,
    preferredPriest,
    notes = [],
    status,
    userId,
    createdAt,
    updatedAt,
  }) {
    this.id = id;
    this.type = type;
    this.intentionDetails = intentionDetails;
    this.donorName = donorName;
    this.parishId = parishId;
    this.parishName = parishName;
    this.preferredDate = preferredDate;
    this.preferredTimeSlot = preferredTimeSlot;
    this.preferredPriest = preferredPriest;
    this.notes = Array.isArray(notes) ? notes : [];
    this.status = status;
    this.userId = userId;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  /**
   * Creates DTO from request body
   */
  static fromRequest(body) {
    console.log('[MassIntentionDTO.fromRequest] RECEIVED body.notes:', JSON.stringify(body.notes), 'type:', typeof body.notes);
    let notes = [];

    if (body.notes) {
      console.log('[MassIntentionDTO.fromRequest] body.notes type:', typeof body.notes, 'value:', JSON.stringify(body.notes));
      if (typeof body.notes === 'string') {
        try {
          notes = JSON.parse(body.notes);
        } catch (e) {
          notes = [];
        }
      } else if (Array.isArray(body.notes)) {
        notes = body.notes;
      }
    }
    console.log('[MassIntentionDTO.fromRequest] final notes:', JSON.stringify(notes));

    return new this({
      type: body.type,
      intentionDetails: body.intentionDetails,
      donorName: body.donorName,
      parishId: parseInt(body.parishId),
      preferredDate: body.preferredDate,
      preferredTimeSlot: body.preferredTimeSlot,
      preferredPriest: body.preferredPriest,
      notes: notes,
      status: body.status,
    });
  }

  /**
   * Creates DTO from database entity
   */
  static fromEntity(entity) {
    if (!entity) return null;
    let notes = [];
    if (entity.notes) {
      try {
        const parsed = typeof entity.notes === 'string' ? JSON.parse(entity.notes) : entity.notes;
        notes = Array.isArray(parsed) ? parsed : [];
      } catch (e) {
        notes = [];
      }
    }
    return new this({
      id: entity.id,
      type: entity.type,
      intentionDetails: entity.intentionDetails,
      donorName: entity.donorName,
      parishId: entity.parishId,
      parishName: entity.parish?.name, // from included association
      preferredDate: entity.preferredDate,
      preferredTimeSlot: entity.preferredTimeSlot,
      preferredPriest: entity.preferredPriest,
      notes: notes,
      status: entity.status,
      userId: entity.userId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    });
  }

  /**
   * Creates DTOs from database entities
   */
  static fromEntities(entities) {
    return entities.map(entity => this.fromEntity(entity));
  }

  /**
   * Validates the DTO data
   */
  validate() {
    const errors = [];

    if (!this.type || !['For the Dead', 'Thanksgiving', 'Special Intention'].includes(this.type)) {
      errors.push('Invalid or missing intention type');
    }

    if (!this.intentionDetails || typeof this.intentionDetails !== 'string') {
      errors.push('Intention details are required');
    }

    if (!this.donorName || typeof this.donorName !== 'string') {
      errors.push('Donor name is required');
    }

    if (!this.parishId || typeof this.parishId !== 'number') {
      errors.push('Valid parish ID is required');
    }

    if (!this.preferredDate || isNaN(new Date(this.preferredDate).getTime())) {
      errors.push('Valid preferred date is required');
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  /**
   * Returns only allowed update fields
   */
  getAllowedUpdates(allowedFields) {
    const updateData = {};
    for (const field of allowedFields) {
      if (this[field] !== undefined) {
        updateData[field] = this[field];
      }
    }
    return updateData;
  }

  /**
   * Converts to plain object
   */
  toObject() {
    return {
      id: this.id,
      type: this.type,
      intentionDetails: this.intentionDetails,
      donorName: this.donorName,
      parishId: this.parishId,
      parishName: this.parishName,
      preferredDate: this.preferredDate,
      preferredTimeSlot: this.preferredTimeSlot,
      preferredPriest: this.preferredPriest,
      notes: this.notes,
      status: this.status,
      userId: this.userId,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }

  /**
   * Adds a note to the notes array
   * @param {string} author - 'parishioner' or 'admin'
   * @param {string} content - Note content
   * @param {number} authorId - User ID of the author
   */
  addNote(author, content, authorId) {
    if (!this.notes) this.notes = [];
    this.notes.push({
      author,
      content,
      authorId,
      timestamp: new Date().toISOString(),
    });
  }
}

module.exports = MassIntentionDTO;
