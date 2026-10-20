class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  AppException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([super.message = 'Unable to connect to server. Please check your network.']);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([super.message = 'Session expired. Please log in again.'])
      : super(statusCode: 401);
}

class ValidationException extends AppException {
  ValidationException(super.message, {super.details})
      : super(statusCode: 400);
}

class ServerException extends AppException {
  ServerException([super.message = 'Server error. Please try again later.'])
      : super(statusCode: 500);
}
