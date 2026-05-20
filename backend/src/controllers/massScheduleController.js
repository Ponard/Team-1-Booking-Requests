const { validationResult } = require('express-validator');
const { MassSchedule, User, Parish } = require('../models');
const { Op } = require('sequelize');
const PDFDocument = require('pdfkit');
const nodemailer = require('nodemailer');
const fs = require('fs');
const path = require('path');

// Create a new mass schedule
exports.createMassSchedule = async (req, res, next) => {
  try {
    // Validate request
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const {
      parishId,
      dayOfWeek,
      startTime,
      endTime,
      priestId,
      intentionCutoffTime,
      notes
    } = req.body;

    // Check if parish exists
    const parish = await Parish.findByPk(parishId);
    if (!parish) {
      return res.status(404).json({
        error: 'Parish not found',
        message: 'The specified parish does not exist'
      });
    }

    // Check if priest exists (if provided)
    let priest = null;
    if (priestId) {
      priest = await User.findByPk(priestId);
      if (!priest || priest.role !== 'priest') {
        return res.status(404).json({
          error: 'Priest not found',
          message: 'The specified priest does not exist or is not a valid priest'
        });
      }
    }

    // Check if user has permission to create mass schedule for this parish
    if (req.user.role !== 'diocese_staff' && req.user.role !== 'diocese_admin') {
      if (req.user.role === 'parish_admin' || req.user.role === 'parish_staff') {
        // Auto-assign to user's parish if not provided
        const targetParishId = parishId || req.user.assignedParishId;
        if (req.user.assignedParishId !== targetParishId) {
          return res.status(403).json({
            error: 'Access denied',
            message: 'You can only create mass schedules for your assigned parish'
          });
        }
        req.body.parishId = targetParishId;
      } else {
        return res.status(403).json({
          error: 'Access denied',
          message: 'Only authorized personnel can create mass schedules'
        });
      }
    }

    // Create mass schedule
    const massSchedule = await MassSchedule.create({
      parishId,
      dayOfWeek,
      startTime,
      endTime,
      priestId,
      intentionCutoffTime,
      notes,
      isActive: true
    });

    // Populate associations for response
    const populatedSchedule = await MassSchedule.findByPk(massSchedule.id, {
      include: [
        {
          model: Parish,
          as: 'parish',
          attributes: ['id', 'name', 'address']
        },
        {
          model: User,
          as: 'assignedPriest',
          attributes: ['id', 'firstName', 'lastName', 'email']
        }
      ]
    });

    res.status(201).json({
      message: 'Mass schedule created successfully',
      massSchedule: populatedSchedule
    });
  } catch (error) {
    next(error);
  }
};

// Get all mass schedules for a parish
exports.getAllMassSchedules = async (req, res, next) => {
  try {
    const { parishId } = req.query;

    // Check if user has permission to view mass schedules
    if (req.user.role !== 'diocese_staff' && req.user.role !== 'diocese_admin') {
      if (req.user.role === 'parish_admin' || req.user.role === 'parish_staff') {
        // Parish-level users can only view schedules for their assigned parish
        const userParishId = req.user.assignedParishId;
        if (userParishId) {
          req.query.parishId = userParishId;
        }
        // If user has no assignedParishId, proceed without parish filter
        // (will return all active schedules)
      } else {
        return res.status(403).json({
          error: 'Access denied',
          message: 'Only authorized personnel can view mass schedules'
        });
      }
    }

    const whereClause = { isActive: true };

    if (req.query.parishId) {
      whereClause.parishId = req.query.parishId;
    }

    const massSchedules = await MassSchedule.findAll({
      where: whereClause,
      include: [
        {
          model: Parish,
          as: 'parish',
          attributes: ['id', 'name', 'address']
        },
        {
          model: User,
          as: 'assignedPriest',
          attributes: ['id', 'firstName', 'lastName', 'email']
        }
      ],
      order: [['dayOfWeek', 'ASC'], ['startTime', 'ASC']]
    });

    res.json({
      massSchedules: massSchedules
    });
  } catch (error) {
    next(error);
  }
};

// Get a specific mass schedule by ID
exports.getMassScheduleById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const massSchedule = await MassSchedule.findByPk(id, {
      include: [
        {
          model: Parish,
          as: 'parish',
          attributes: ['id', 'name', 'address']
        },
        {
          model: User,
          as: 'assignedPriest',
          attributes: ['id', 'firstName', 'lastName', 'email']
        }
      ]
    });

    if (!massSchedule) {
      return res.status(404).json({
        error: 'Mass schedule not found',
        message: 'The specified mass schedule does not exist'
      });
    }

    // Check if user has permission to view this mass schedule
    if (req.user.role !== 'diocese_staff' && req.user.role !== 'diocese_admin') {
      if (req.user.role === 'parish_admin' || req.user.role === 'parish_staff') {
        if (massSchedule.parishId !== req.user.assignedParishId) {
          return res.status(403).json({
            error: 'Access denied',
            message: 'You can only view mass schedules for your assigned parish'
          });
        }
      } else {
        return res.status(403).json({
          error: 'Access denied',
          message: 'Only authorized personnel can view mass schedules'
        });
      }
    }

    res.json({
      massSchedule: massSchedule
    });
  } catch (error) {
    next(error);
  }
};

// Update a mass schedule
exports.updateMassSchedule = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Validate request
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const massSchedule = await MassSchedule.findByPk(id);
    if (!massSchedule) {
      return res.status(404).json({
        error: 'Mass schedule not found',
        message: 'The specified mass schedule does not exist'
      });
    }

    // Check if user has permission to update mass schedule
    if (req.user.role !== 'diocese_staff' && req.user.role !== 'diocese_admin') {
      if (req.user.role === 'parish_admin' || req.user.role === 'parish_staff') {
        if (massSchedule.parishId !== req.user.assignedParishId) {
          return res.status(403).json({
            error: 'Access denied',
            message: 'You can only update mass schedules for your assigned parish'
          });
        }
      } else {
        return res.status(403).json({
          error: 'Access denied',
          message: 'Only authorized personnel can update mass schedules'
        });
      }
    }

    const {
      dayOfWeek,
      startTime,
      endTime,
      priestId,
      intentionCutoffTime,
      notes,
      isActive
    } = req.body;

    // Check if priest exists (if provided)
    if (priestId) {
      const priest = await User.findByPk(priestId);
      if (!priest || priest.role !== 'priest') {
        return res.status(404).json({
          error: 'Priest not found',
          message: 'The specified priest does not exist or is not a valid priest'
        });
      }
    }

    // Update the mass schedule
    await massSchedule.update({
      dayOfWeek,
      startTime,
      endTime,
      priestId,
      intentionCutoffTime,
      notes,
      isActive
    });

    // Populate associations for response
    const populatedSchedule = await MassSchedule.findByPk(massSchedule.id, {
      include: [
        {
          model: Parish,
          as: 'parish',
          attributes: ['id', 'name', 'address']
        },
        {
          model: User,
          as: 'assignedPriest',
          attributes: ['id', 'firstName', 'lastName', 'email']
        }
      ]
    });

    res.json({
      message: 'Mass schedule updated successfully',
      massSchedule: populatedSchedule
    });
  } catch (error) {
    next(error);
  }
};

// Delete a mass schedule
exports.deleteMassSchedule = async (req, res, next) => {
  try {
    const { id } = req.params;

    const massSchedule = await MassSchedule.findByPk(id);
    if (!massSchedule) {
      return res.status(404).json({
        error: 'Mass schedule not found',
        message: 'The specified mass schedule does not exist'
      });
    }

    // Check if user has permission to delete mass schedule
    if (req.user.role !== 'diocese_staff' && req.user.role !== 'diocese_admin') {
      if (req.user.role === 'parish_admin' || req.user.role === 'parish_staff') {
        if (massSchedule.parishId !== req.user.assignedParishId) {
          return res.status(403).json({
            error: 'Access denied',
            message: 'You can only delete mass schedules for your assigned parish'
          });
        }
      } else {
        return res.status(403).json({
          error: 'Access denied',
          message: 'Only authorized personnel can delete mass schedules'
        });
      }
    }

    // Soft delete by setting isActive to false
    await massSchedule.update({ isActive: false });

    res.json({
      message: 'Mass schedule deactivated successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Generate PDF list of mass intentions for priests
exports.generateMassIntentionPDF = async (req, res, next) => {
  try {
    const { parishId, date } = req.query;

    // Check if user has permission to generate PDF
    if (req.user.role !== 'diocese_staff' && req.user.role !== 'diocese_admin') {
      if (req.user.role === 'parish_admin' || req.user.role === 'parish_staff') {
        if (parishId && req.user.assignedParishId !== parseInt(parishId)) {
          return res.status(403).json({
            error: 'Access denied',
            message: 'You can only generate PDFs for your assigned parish'
          });
        }
      } else {
        return res.status(403).json({
          error: 'Access denied',
          message: 'Only authorized personnel can generate mass intention PDFs'
        });
      }
    }

    // Find parish
    const parish = await Parish.findByPk(parishId);
    if (!parish) {
      return res.status(404).json({
        error: 'Parish not found',
        message: 'The specified parish does not exist'
      });
    }

    // Find mass intentions for the specified date and parish
    const whereClause = {
      parishId: parishId,
      status: 'approved'
    };

    if (date) {
      // Filter by date
      whereClause.massSchedule = {
        [Op.and]: [
          { [Op.gte]: new Date(date + ' 00:00:00') },
          { [Op.lt]: new Date(date + ' 23:59:59') }
        ]
      };
    }

    const massIntentions = await MassIntention.findAll({
      where: whereClause,
      include: [
        {
          model: User,
          as: 'submitter',
          attributes: ['id', 'firstName', 'lastName']
        }
      ],
      order: [['massSchedule', 'ASC']]
    });

    // Create PDF document
    const doc = new PDFDocument();
    
    // Set response headers for PDF download
    res.setHeader('Content-disposition', `attachment; filename="mass-intentions-${parish.name}-${date || 'all'}.pdf"`);
    res.setHeader('Content-type', 'application/pdf');
    
    // Pipe PDF to response
    doc.pipe(res);

    // Check if logo exists and add header with diocese letterhead
    const logoPath = path.join(__dirname, '../../assets/diocese-logo.png');
    if (fs.existsSync(logoPath)) {
      doc.image(logoPath, 50, 45, { width: 100 })
         .fontSize(20)
         .text('Diocese of Kalookan', 160, 57)
         .fontSize(14)
         .text('Office of Sacred Liturgy', 160, 80)
         .moveDown();
    } else {
      // Add header without logo
      doc.fontSize(20)
         .text('Diocese of Kalookan', 50, 50)
         .fontSize(14)
         .text('Office of Sacred Liturgy', 50, 75)
         .moveDown();
    }

    // Add title
    doc.fontSize(18)
       .text(`Mass Intention List for ${parish.name}`, 50, 120)
       .text(`Date: ${date || 'All Dates'}`, 50, 140)
       .moveDown();

    // Add table header
    let yPosition = 180;
    doc.fontSize(12)
       .font('Helvetica-Bold')
       .text('Date & Time', 50, yPosition)
       .text('Type', 150, yPosition)
       .text('Intention Details', 220, yPosition)
       .text('Donor Name', 380, yPosition)
       .text('Submitted By', 480, yPosition)
       .font('Helvetica');

    yPosition += 25;

    // Add mass intentions to the PDF
    if (massIntentions.length === 0) {
      doc.text('No approved mass intentions found for the selected criteria.', 50, yPosition);
    } else {
      for (const intention of massIntentions) {
        // Format date for display
        const formattedDate = new Date(intention.massSchedule).toLocaleString('en-US', {
          month: 'short',
          day: 'numeric',
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit'
        });

        // Add row data
        doc.text(formattedDate, 50, yPosition)
           .text(intention.type, 150, yPosition)
           .text(intention.intentionDetails.substring(0, 30) + (intention.intentionDetails.length > 30 ? '...' : ''), 220, yPosition)
           .text(intention.donorName, 380, yPosition)
           .text(`${intention.submitter.firstName} ${intention.submitter.lastName}`, 480, yPosition);

        yPosition += 20;

        // Add page break if needed
        if (yPosition > 700) {
          doc.addPage();
          yPosition = 50;
        }
      }
    }

    // Add footer
    doc.fontSize(10)
       .text(`Page ${doc.bufferedPageRange().count || 1}`, 50, 780)
       .text('Generated on: ' + new Date().toLocaleDateString(), 450, 780);

    // Finalize PDF
    doc.end();
  } catch (error) {
    next(error);
  }
};

// Send notification emails to assigned priests and parish staff
exports.sendMassIntentionNotifications = async (req, res, next) => {
  try {
    const { parishId, date } = req.query;

    // Check if user has permission to send notifications
    if (req.user.role !== 'diocese_staff' && req.user.role !== 'diocese_admin') {
      if (req.user.role === 'parish_admin' || req.user.role === 'parish_staff') {
        if (parishId && req.user.assignedParishId !== parseInt(parishId)) {
          return res.status(403).json({
            error: 'Access denied',
            message: 'You can only send notifications for your assigned parish'
          });
        }
      } else {
        return res.status(403).json({
          error: 'Access denied',
          message: 'Only authorized personnel can send mass intention notifications'
        });
      }
    }

    // Find parish
    const parish = await Parish.findByPk(parishId);
    if (!parish) {
      return res.status(404).json({
        error: 'Parish not found',
        message: 'The specified parish does not exist'
      });
    }

    // Find mass intentions for the specified date and parish that are approved
    const whereClause = {
      parishId: parishId,
      status: 'approved'
    };

    if (date) {
      // Filter by date
      whereClause.massSchedule = {
        [Op.and]: [
          { [Op.gte]: new Date(date + ' 00:00:00') },
          { [Op.lt]: new Date(date + ' 23:59:59') }
        ]
      };
    }

    const massIntentions = await MassIntention.findAll({
      where: whereClause,
      include: [
        {
          model: User,
          as: 'submitter',
          attributes: ['id', 'firstName', 'lastName', 'email']
        }
      ],
      order: [['massSchedule', 'ASC']]
    });

    if (massIntentions.length === 0) {
      return res.json({
        message: 'No mass intentions found for the specified criteria',
        sent: 0
      });
    }

    // Get assigned priests and parish staff for the parish
    const assignedUsers = await User.findAll({
      where: {
        [Op.or]: [
          { assignedParishId: parishId, role: 'priest' },
          { assignedParishId: parishId, role: 'parish_staff' }
        ]
      },
      attributes: ['id', 'firstName', 'lastName', 'email', 'role']
    });

    if (assignedUsers.length === 0) {
      return res.json({
        message: 'No assigned priests or parish staff found for this parish',
        sent: 0
      });
    }

    // Create transporter for sending emails
    const transporter = nodemailer.createTransporter({
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: process.env.SMTP_PORT || 587,
      secure: false, // true for 465, false for other ports
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
      }
    });

    // Prepare email content
    const formatDate = (date) => {
      return new Date(date).toLocaleString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    };

    let emailBody = `
      <h2>Mass Intention Notifications for ${parish.name}</h2>
      <p>Date: ${date || 'All upcoming dates'}</p>
      <p>Dear Priest and Parish Staff,</p>
      <p>Please find below the mass intentions scheduled for your parish:</p>
      
      <table border="1" cellpadding="10" cellspacing="0">
        <thead>
          <tr>
            <th>Date & Time</th>
            <th>Type</th>
            <th>Intention Details</th>
            <th>Donor Name</th>
            <th>Submitted By</th>
          </tr>
        </thead>
        <tbody>
    `;

    for (const intention of massIntentions) {
      emailBody += `
        <tr>
          <td>${formatDate(intention.massSchedule)}</td>
          <td>${intention.type}</td>
          <td>${intention.intentionDetails}</td>
          <td>${intention.donorName}</td>
          <td>${intention.submitter.firstName} ${intention.submitter.lastName}</td>
        </tr>
      `;
    }

    emailBody += `
        </tbody>
      </table>
      
      <p>Please prepare for these masses accordingly.</p>
      <br>
      <p>Best regards,<br>
      Diocese of Kalookan Administration</p>
    `;

    // Send emails to all assigned users
    const emailPromises = assignedUsers.map(user => {
      return transporter.sendMail({
        from: process.env.SMTP_USER || '"Diocese of Kalookan" <noreply@diocesekalookan.org>',
        to: user.email,
        subject: `Mass Intention Notifications for ${parish.name} - ${date || 'Upcoming Dates'}`,
        html: emailBody
      });
    });

    // Wait for all emails to be sent
    await Promise.all(emailPromises);

    res.json({
      message: `Mass intention notifications sent successfully to ${assignedUsers.length} recipients`,
      sentTo: assignedUsers.map(u => `${u.firstName} ${u.lastName} (${u.role})`),
      totalIntentions: massIntentions.length
    });
  } catch (error) {
    next(error);
  }
};