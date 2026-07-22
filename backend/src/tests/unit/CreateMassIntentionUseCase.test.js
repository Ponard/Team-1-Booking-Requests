/**
 * Unit Tests for CreateMassIntentionUseCase
 */
const CreateMassIntentionUseCase = require('../../useCases/massIntention/CreateMassIntentionUseCase');
const MassIntentionDTO = require('../../dto/MassIntentionDTO');

describe('CreateMassIntentionUseCase', () => {
  let useCase;
  let mockMassIntentionRepository;
  let mockParishRepository;
  let mockEmailService;

  beforeEach(() => {
    mockMassIntentionRepository = {
      create: jest.fn(),
    };
    mockParishRepository = {
      findById: jest.fn(),
    };
    mockEmailService = {
      sendNotification: jest.fn(),
    };

    useCase = new CreateMassIntentionUseCase(
      mockMassIntentionRepository,
      mockParishRepository,
      mockEmailService
    );
  });

  describe('execute', () => {
    it('should create mass intention successfully', async () => {
      const dto = new MassIntentionDTO({
        type: 'Thanksgiving',
        intentionDetails: 'For good health',
        donorName: 'John Doe',
        parishId: 1,
        massSchedule: new Date('2024-12-25'),
      });
      const user = { userId: 123, email: 'john@example.com', firstName: 'John' };

      mockParishRepository.findById.mockResolvedValue({ id: 1, name: 'Test Parish' });
      mockMassIntentionRepository.create.mockResolvedValue(dto);

      const result = await useCase.execute(dto, user);

      expect(result).toEqual(dto);
      expect(mockParishRepository.findById).toHaveBeenCalledWith(1);
      expect(mockMassIntentionRepository.create).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 123,
          status: 'pending',
        })
      );
    });

    it('should throw error if validation fails', async () => {
      const dto = new MassIntentionDTO({
        type: 'Invalid Type',
        intentionDetails: '',
        donorName: '',
        parishId: 1,
        massSchedule: new Date(),
      });
      const user = { userId: 123 };

      await expect(useCase.execute(dto, user)).rejects.toThrow('Invalid or missing intention type');
    });

    it('should throw error if parish not found', async () => {
      const dto = new MassIntentionDTO({
        type: 'Thanksgiving',
        intentionDetails: 'For good health',
        donorName: 'John Doe',
        parishId: 999,
        massSchedule: new Date(),
      });
      const user = { userId: 123 };

      mockParishRepository.findById.mockResolvedValue(null);

      await expect(useCase.execute(dto, user)).rejects.toThrow('Parish not found');
    });

    it('should set userId from user', async () => {
      const dto = new MassIntentionDTO({
        type: 'Thanksgiving',
        intentionDetails: 'For good health',
        donorName: 'John Doe',
        parishId: 1,
        massSchedule: new Date(),
      });
      const user = { userId: 456 };

      mockParishRepository.findById.mockResolvedValue({ id: 1 });
      mockMassIntentionRepository.create.mockResolvedValue(dto);

      await useCase.execute(dto, user);

      expect(mockMassIntentionRepository.create).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 456,
        })
      );
    });

    it('should send confirmation email after creation', async () => {
      const dto = new MassIntentionDTO({
        type: 'Thanksgiving',
        intentionDetails: 'For good health',
        donorName: 'John Doe',
        parishId: 1,
        massSchedule: new Date(),
      });
      const user = { userId: 123, email: 'john@example.com', firstName: 'John' };

      mockParishRepository.findById.mockResolvedValue({ id: 1 });
      mockMassIntentionRepository.create.mockResolvedValue(dto);

      await useCase.execute(dto, user);

      // Wait for async email to be sent
      await new Promise(resolve => setTimeout(resolve, 100));

      expect(mockEmailService.sendNotification).toHaveBeenCalled();
    });

    it('should not fail if email service fails', async () => {
      const dto = new MassIntentionDTO({
        type: 'Thanksgiving',
        intentionDetails: 'For good health',
        donorName: 'John Doe',
        parishId: 1,
        massSchedule: new Date(),
      });
      const user = { userId: 123, email: 'john@example.com', firstName: 'John' };

      mockParishRepository.findById.mockResolvedValue({ id: 1 });
      mockMassIntentionRepository.create.mockResolvedValue(dto);
      mockEmailService.sendNotification.mockRejectedValue(new Error('Email failed'));

      // Should not throw
      await expect(useCase.execute(dto, user)).resolves.toEqual(dto);
    });
  });
});
