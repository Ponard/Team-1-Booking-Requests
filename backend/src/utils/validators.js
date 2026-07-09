exports.validateBookingDate = (preferredDate) => {
  if (!preferredDate) {
    return { valid: true }; // optional field
  }

  const DATE_REGEX = /^\d{4}-\d{2}-\d{2}$/;

  if (!DATE_REGEX.test(preferredDate)) {
    return {
      valid: false,
      error: 'Invalid preferred date. Expected format: YYYY-MM-DD.',
    };
  }

  const date = new Date(`${preferredDate}T00:00:00`);

  if (Number.isNaN(date.getTime())) {
    return {
      valid: false,
      error: 'Invalid preferred date.',
    };
  }

  const normalized = date.toISOString().split('T')[0];

  if (normalized !== preferredDate) {
    return {
      valid: false,
      error: 'Invalid preferred date.',
    };
  }

  return { valid: true };
};
