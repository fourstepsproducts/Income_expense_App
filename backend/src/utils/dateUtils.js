/**
 * Date utility functions for financial calculations and aggregations
 */

const getStartAndEndOfDay = (date = new Date()) => {
  const start = new Date(date);
  start.setHours(0, 0, 0, 0);

  const end = new Date(date);
  end.setHours(23, 59, 59, 999);

  return { start, end };
};

const getStartAndEndOfMonth = (year, month) => {
  // month is 0-indexed (0 = Jan, 11 = Dec)
  const start = new Date(Date.UTC(year, month, 1, 0, 0, 0, 0));
  const end = new Date(Date.UTC(year, month + 1, 0, 23, 59, 59, 999));
  return { start, end };
};

const getPreviousMonthRange = (currentStart) => {
  const d = new Date(currentStart);
  d.setUTCMonth(d.getUTCMonth() - 1);
  return getStartAndEndOfMonth(d.getUTCFullYear(), d.getUTCMonth());
};

const parseDateRange = (startDateStr, endDateStr) => {
  let start = null;
  let end = null;

  if (startDateStr) {
    start = new Date(startDateStr);
    if (!isNaN(start.getTime())) {
      start.setHours(0, 0, 0, 0);
    } else {
      start = null;
    }
  }

  if (endDateStr) {
    end = new Date(endDateStr);
    if (!isNaN(end.getTime())) {
      end.setHours(23, 59, 59, 999);
    } else {
      end = null;
    }
  }

  return { start, end };
};

module.exports = {
  getStartAndEndOfDay,
  getStartAndEndOfMonth,
  getPreviousMonthRange,
  parseDateRange
};
