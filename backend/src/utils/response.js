/**
 * Standardized JSON API Response Helpers
 */

const successResponse = (res, data = {}, message = 'Success', statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data
  });
};

const paginatedResponse = (res, data = [], pagination = {}, message = 'Success', statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
    pagination: {
      total: pagination.total || 0,
      page: pagination.page || 1,
      limit: pagination.limit || 20,
      totalPages: Math.ceil((pagination.total || 0) / (pagination.limit || 20)) || 1,
      hasNext: pagination.page < Math.ceil((pagination.total || 0) / (pagination.limit || 20)),
      hasPrev: pagination.page > 1
    }
  });
};

const errorResponse = (res, message = 'An error occurred', statusCode = 500, errors = null) => {
  const payload = {
    success: false,
    message
  };

  if (errors) {
    payload.errors = errors;
  }

  return res.status(statusCode).json(payload);
};

module.exports = {
  successResponse,
  paginatedResponse,
  errorResponse
};
