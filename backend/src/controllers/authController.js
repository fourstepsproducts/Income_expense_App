const authService = require('../services/authService');
const { successResponse, errorResponse } = require('../utils/response');

class AuthController {
  async register(req, res, next) {
    try {
      const { name, email, password, currency } = req.body;
      const result = await authService.register({ name, email, password, currency });
      return successResponse(res, result, 'User registered successfully', 201);
    } catch (err) {
      next(err);
    }
  }

  async login(req, res, next) {
    try {
      const { email, password } = req.body;
      const result = await authService.login({ email, password });
      return successResponse(res, result, 'Login successful');
    } catch (err) {
      next(err);
    }
  }

  async refresh(req, res, next) {
    try {
      const { refreshToken } = req.body;
      const result = await authService.refresh(refreshToken);
      return successResponse(res, result, 'Token refreshed successfully');
    } catch (err) {
      next(err);
    }
  }

  async getProfile(req, res, next) {
    try {
      const user = await authService.getProfile(req.user._id);
      return successResponse(res, { user }, 'Profile retrieved successfully');
    } catch (err) {
      next(err);
    }
  }

  async updateProfile(req, res, next) {
    try {
      const { name, currency } = req.body;
      const user = await authService.updateProfile(req.user._id, { name, currency });
      return successResponse(res, { user }, 'Profile updated successfully');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new AuthController();
