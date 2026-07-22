/**
 * Unit Tests for MassIntentionDTO
 */
const MassIntentionDTO = require('../../dto/MassIntentionDTO');

describe('MassIntentionDTO', () => {
  describe('fromRequest', () => {
    it('should create DTO from request body', () => {
      const body = {
        type: 'Thanksgiving',
        intentionDetails: 'For good health',
        donorName: 'John Doe',
        parishId: '1',
        massSchedule: '2024-12-25T10:00:00Z',
        preferredPriest: 'Fr. Juan',
        notes: 'Special intention',
      };

      const dto = MassIntentionDTO.fromRequest(body);

      expect(dto.type).toBe('Thanksgiving');
      expect(dto.intentionDetails).toBe('For good health');
      expect(dto.donorName).toBe('John Doe');
      expect(dto.parishId).toBe(1);
      expect(dto.preferredPriest).toBe('Fr. Juan');
    });
  });

  describe('validate', () => {
    it('should return valid for complete data', () => {
      const dto = new MassIntentionDTO({
        type: 'Thanksgiving',
        intentionDetails: 'For good health',
        donorName: 'John Doe',
        parishId: 1,
        massSchedule: new Date(),
      });

      const result = dto.validate();

      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should return invalid for missing type', () => {
      const dto = new MassIntentionDTO({
        intentionDetails: 'For good health',
        donorName: 'John Doe',
        parishId: 1,
        massSchedule: new Date(),
      });

      const result = dto.validate();

      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Invalid or missing intention type');
    });

    it('should return invalid for missing intention details', () => {
      const dto = new MassIntentionDTO({
        type: 'Thanksgiving',
        donorName: 'John Doe',
        parishId: 1,
        massSchedule: new Date(),
      });

      const result = dto.validate();

      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Intention details are required');
    });

    it('should return invalid for missing donor name', () => {
      const dto = new MassIntentionDTO({
        type: 'Thanksgiving',
        intentionDetails: 'For good health',
        parishId: 1,
        massSchedule: new Date(),
      });

      const result = dto.validate();

      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Donor name is required');
    });

    it('should return invalid for invalid type', () => {
      const dto = new MassIntentionDTO({
        type: 'Invalid Type',
        intentionDetails: 'For good health',
        donorName: 'John Doe',
        parishId: 1,
        massSchedule: new Date(),
      });

      const result = dto.validate();

      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Invalid or missing intention type');
    });
  });

  describe('fromEntity', () => {
    it('should create DTO from database entity', () => {
      const entity = {
        id: 1,
        type: 'For the Dead',
        intentionDetails: 'For deceased relatives',
        donorName: 'Maria Santos',
        parishId: 2,
        massSchedule: new Date('2024-12-25'),
        preferredPriest: 'Fr. Pedro',
        notes: null,
        preferredDate: '2024-12-01',
        status: 'pending',
        userId: 5,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      const dto = MassIntentionDTO.fromEntity(entity);

      expect(dto.id).toBe(1);
      expect(dto.type).toBe('For the Dead');
      expect(dto.donorName).toBe('Maria Santos');
      expect(dto.status).toBe('pending');
    });

    it('should return null for null entity', () => {
      const dto = MassIntentionDTO.fromEntity(null);
      expect(dto).toBeNull();
    });
  });

  describe('toObject', () => {
    it('should convert DTO to plain object', () => {
      const dto = new MassIntentionDTO({
        id: 1,
        type: 'Special Intention',
        intentionDetails: 'For safe journey',
        donorName: 'Jose Rizal',
        parishId: 3,
        massSchedule: new Date(),
      });

      const obj = dto.toObject();

      expect(obj).toEqual({
        id: 1,
        type: 'Special Intention',
        intentionDetails: 'For safe journey',
        donorName: 'Jose Rizal',
        parishId: 3,
        massSchedule: expect.any(Date),
        preferredPriest: undefined,
        notes: undefined,
        preferredDate: undefined,
        status: undefined,
        userId: undefined,
        createdAt: undefined,
        updatedAt: undefined,
      });
    });
  });

  describe('getAllowedUpdates', () => {
    it('should return only allowed fields', () => {
      const dto = new MassIntentionDTO({
        type: 'Thanksgiving',
        intentionDetails: 'Updated details',
        donorName: 'New Donor',
        parishId: 5,
        massSchedule: new Date(),
        status: 'approved',
      });

      const allowedFields = ['intentionDetails', 'donorName', 'preferredPriest', 'notes'];
      const updateData = dto.getAllowedUpdates(allowedFields);

      expect(updateData).toEqual({
        intentionDetails: 'Updated details',
        donorName: 'New Donor',
      });
    });
  });
});
