/// Custom exception hierarchy for LinguaBot
/// Provides type-safe error handling across the application

abstract class LinguaBotException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;
  final StackTrace? stackTrace;

  LinguaBotException({
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => 'LinguaBotException: [$code] $message';
}

// Network & Connectivity Errors
class NetworkException extends LinguaBotException {
  NetworkException({
    required String message,
    String? code,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'NETWORK_ERROR',
    originalException: originalException,
    stackTrace: stackTrace,
  );

  factory NetworkException.timeout() => NetworkException(
    message: 'Request timed out. Please check your connection and try again.',
    code: 'TIMEOUT',
  );

  factory NetworkException.noConnection() => NetworkException(
    message: 'No internet connection. Please check your network.',
    code: 'NO_INTERNET',
  );

  factory NetworkException.serverError(int statusCode, {String? details}) =>
      NetworkException(
        message: 'Server error ($statusCode). Please try again later.',
        code: 'SERVER_ERROR_$statusCode',
      );

  factory NetworkException.badRequest(String details) => NetworkException(
    message: 'Invalid request: $details',
    code: 'BAD_REQUEST',
  );
}

// API & External Service Errors
class ApiException extends LinguaBotException {
  final int? statusCode;

  ApiException({
    required String message,
    String? code,
    this.statusCode,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalException: originalException,
    stackTrace: stackTrace,
  );

  factory ApiException.rateLimited() => ApiException(
    message: 'Too many requests. Please wait a moment and try again.',
    code: 'RATE_LIMITED',
    statusCode: 429,
  );

  factory ApiException.unauthorized() => ApiException(
    message: 'Unauthorized. Please log in again.',
    code: 'UNAUTHORIZED',
    statusCode: 401,
  );

  factory ApiException.forbidden() => ApiException(
    message: 'You do not have permission to access this resource.',
    code: 'FORBIDDEN',
    statusCode: 403,
  );

  factory ApiException.notFound() => ApiException(
    message: 'Resource not found.',
    code: 'NOT_FOUND',
    statusCode: 404,
  );

  factory ApiException.serviceUnavailable() => ApiException(
    message: 'Service is temporarily unavailable. Please try again later.',
    code: 'SERVICE_UNAVAILABLE',
    statusCode: 503,
  );
}

// Authentication & Authorization Errors
class AuthenticationException extends LinguaBotException {
  AuthenticationException({
    required String message,
    String? code,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'AUTH_ERROR',
    originalException: originalException,
    stackTrace: stackTrace,
  );

  factory AuthenticationException.invalidCredentials() =>
      AuthenticationException(
        message: 'Invalid email or password.',
        code: 'INVALID_CREDENTIALS',
      );

  factory AuthenticationException.sessionExpired() =>
      AuthenticationException(
        message: 'Your session has expired. Please log in again.',
        code: 'SESSION_EXPIRED',
      );

  factory AuthenticationException.userNotFound() =>
      AuthenticationException(
        message: 'User account not found.',
        code: 'USER_NOT_FOUND',
      );
}

// Data Validation & Input Errors
class ValidationException extends LinguaBotException {
  final Map<String, String>? fieldErrors;

  ValidationException({
    required String message,
    String? code,
    this.fieldErrors,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'VALIDATION_ERROR',
    originalException: originalException,
    stackTrace: stackTrace,
  );

  factory ValidationException.emptyField(String fieldName) =>
      ValidationException(
        message: '$fieldName cannot be empty.',
        code: 'EMPTY_FIELD',
        fieldErrors: {fieldName: 'This field is required'},
      );

  factory ValidationException.invalidEmail() => ValidationException(
    message: 'Please enter a valid email address.',
    code: 'INVALID_EMAIL',
  );

  factory ValidationException.invalidInput(String details) =>
      ValidationException(
        message: 'Invalid input: $details',
        code: 'INVALID_INPUT',
      );

  factory ValidationException.multipleErrors(Map<String, String> errors) =>
      ValidationException(
        message: 'Validation failed for ${errors.length} field(s).',
        code: 'MULTIPLE_ERRORS',
        fieldErrors: errors,
      );
}

// Database & Cache Errors
class CacheException extends LinguaBotException {
  CacheException({
    required String message,
    String? code,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'CACHE_ERROR',
    originalException: originalException,
    stackTrace: stackTrace,
  );

  factory CacheException.readFailed(String key) => CacheException(
    message: 'Failed to read from cache: $key',
    code: 'CACHE_READ_FAILED',
  );

  factory CacheException.writeFailed(String key) => CacheException(
    message: 'Failed to write to cache: $key',
    code: 'CACHE_WRITE_FAILED',
  );
}

class DatabaseException extends LinguaBotException {
  DatabaseException({
    required String message,
    String? code,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'DATABASE_ERROR',
    originalException: originalException,
    stackTrace: stackTrace,
  );

  factory DatabaseException.connectionFailed() => DatabaseException(
    message: 'Failed to connect to database.',
    code: 'CONNECTION_FAILED',
  );

  factory DatabaseException.queryFailed(String query) => DatabaseException(
    message: 'Database query failed.',
    code: 'QUERY_FAILED',
  );

  factory DatabaseException.recordNotFound() => DatabaseException(
    message: 'Record not found.',
    code: 'RECORD_NOT_FOUND',
  );
}

// Audio & Media Errors
class AudioException extends LinguaBotException {
  AudioException({
    required String message,
    String? code,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'AUDIO_ERROR',
    originalException: originalException,
    stackTrace: stackTrace,
  );

  factory AudioException.permissionDenied() => AudioException(
    message: 'Microphone permission denied. Please enable it in settings.',
    code: 'PERMISSION_DENIED',
  );

  factory AudioException.recordingFailed() => AudioException(
    message: 'Failed to record audio. Please try again.',
    code: 'RECORDING_FAILED',
  );

  factory AudioException.playbackFailed() => AudioException(
    message: 'Failed to play audio. Please try again.',
    code: 'PLAYBACK_FAILED',
  );

  factory AudioException.microphoneUnavailable() => AudioException(
    message: 'Microphone is not available on this device.',
    code: 'MIC_UNAVAILABLE',
  );
}

// Parsing & Data Format Errors
class ParsingException extends LinguaBotException {
  ParsingException({
    required String message,
    String? code,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'PARSING_ERROR',
    originalException: originalException,
    stackTrace: stackTrace,
  );

  factory ParsingException.jsonParse(String details) => ParsingException(
    message: 'Failed to parse JSON: $details',
    code: 'JSON_PARSE_ERROR',
  );

  factory ParsingException.invalidFormat() => ParsingException(
    message: 'Invalid data format received.',
    code: 'INVALID_FORMAT',
  );
}

// Generic/Unknown Errors
class UnknownException extends LinguaBotException {
  UnknownException({
    required String message,
    String? code,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'UNKNOWN_ERROR',
    originalException: originalException,
    stackTrace: stackTrace,
  );
}
