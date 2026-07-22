const express = require('express');
const { body, query } = require('express-validator');
const { authenticateJWT, authorizeRoles } = require('../middleware/auth');
const massScheduleController = require('../controllers/massScheduleController');

const router = express.Router();

// All mass schedule routes require authentication
router.use(authenticateJWT);

// Create a new mass schedule (parish_admin, parish_staff, diocese_staff, diocese_admin only)
router.post('/', [
  authorizeRoles('parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'),
  body('parishId')
    .isInt({ min: 1 })
    .withMessage('Valid parish ID is required'),
  body('dayOfWeek')
    .isIn(['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'])
    .withMessage('Day of week must be one of: Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday'),
  body('startTime')
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage('Start time must be in HH:MM format'),
  body('endTime')
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage('End time must be in HH:MM format'),
  body('priestId')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Valid priest ID is required if provided'),
  body('intentionCutoffTime')
    .optional()
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage('Intention cutoff time must be in HH:MM format'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 1000 })
    .withMessage('Notes are too long'),
], massScheduleController.createMassSchedule);

// Get all mass schedules (parish_admin, parish_staff, diocese_staff, diocese_admin only)
router.get('/', [
  authorizeRoles('parishioner', 'parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'),
  query('parishId')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Valid parish ID is required if provided'),
], massScheduleController.getAllMassSchedules);

// Get a specific mass schedule by ID (parish_admin, parish_staff, diocese_staff, diocese_admin only)
router.get('/:id', [
  authorizeRoles('parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'),
], massScheduleController.getMassScheduleById);

// Update a mass schedule (parish_admin, parish_staff, diocese_staff, diocese_admin only)
router.put('/:id', [
  authorizeRoles('parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'),
  body('dayOfWeek')
    .optional()
    .isIn(['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'])
    .withMessage('Day of week must be one of: Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday'),
  body('startTime')
    .optional()
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage('Start time must be in HH:MM format'),
  body('endTime')
    .optional()
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage('End time must be in HH:MM format'),
  body('priestId')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Valid priest ID is required if provided'),
  body('intentionCutoffTime')
    .optional()
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage('Intention cutoff time must be in HH:MM format'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 1000 })
    .withMessage('Notes are too long'),
  body('isActive')
    .optional()
    .isBoolean()
    .withMessage('Active status must be a boolean value'),
], massScheduleController.updateMassSchedule);

// Delete a mass schedule (parish_admin, parish_staff, diocese_staff, diocese_admin only)
router.delete('/:id', [
  authorizeRoles('parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'),
], massScheduleController.deleteMassSchedule);

// Generate PDF list of mass intentions (parish_admin, parish_staff, diocese_staff, diocese_admin only)
router.get('/pdf/generate', [
  authorizeRoles('parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'),
  query('parishId')
    .isInt({ min: 1 })
    .withMessage('Valid parish ID is required'),
  query('date')
    .optional()
    .isISO8601()
    .withMessage('Valid date is required in YYYY-MM-DD format'),
], massScheduleController.generateMassIntentionPDF);

// Send notification emails to assigned priests and parish staff (parish_admin, parish_staff, diocese_staff, diocese_admin only)
router.post('/notifications/send', [
  authorizeRoles('parish_admin', 'parish_staff', 'diocese_staff', 'diocese_admin'),
  query('parishId')
    .isInt({ min: 1 })
    .withMessage('Valid parish ID is required'),
  query('date')
    .optional()
    .isISO8601()
    .withMessage('Valid date is required in YYYY-MM-DD format'),
], massScheduleController.sendMassIntentionNotifications);

module.exports = router;
