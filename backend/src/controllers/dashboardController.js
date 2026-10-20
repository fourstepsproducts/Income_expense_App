const analyticsService = require('../services/analyticsService');
const { successResponse } = require('../utils/response');

class DashboardController {
  async getSummary(req, res, next) {
    try {
      const timezoneOffsetMinutes = parseInt(req.query.timezoneOffset, 10) || 0;
      const summary = await analyticsService.getDashboardSummary(req.user._id, timezoneOffsetMinutes);
      return successResponse(res, summary, 'Dashboard summary retrieved successfully');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new DashboardController();
