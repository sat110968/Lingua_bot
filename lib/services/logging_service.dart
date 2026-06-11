import 'package:flutter/foundation.dart';
import '../core/errors/exceptions.dart';

/// Centralized logging service with error tracking
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();

  bool _isInitialized = false;
  final List<LogEntry> _logHistory = [];
  static const int _maxLogHistory = 500;

  factory LoggingService() {
    return _instance;
  }

  LoggingService._internal() {
    _initialize();
  }

  /// Initialize logging service
  void _initialize() {
    _isInitialized = true;
    info('🚀 Logging service initialized');
  }

  /// Log verbose message
  void verbose(String message, {dynamic error, StackTrace? stackTrace}) {
    _log('VERBOSE', message, error: error, stackTrace: stackTrace);
  }

  /// Log debug message
  void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    _log('DEBUG', message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  void info(String message, {dynamic error, StackTrace? stackTrace}) {
    _log('INFO', message, error: error, stackTrace: stackTrace);
  }

  /// Log warning
  void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    _log('WARNING', message, error: error, stackTrace: stackTrace);
    _captureException(message, error, stackTrace, level: 'warning');
  }

  /// Log error
  void error(String message, {dynamic error, StackTrace? stackTrace}) {
    _log('ERROR', message, error: error, stackTrace: stackTrace);
    _captureException(message, error, stackTrace, level: 'error');
  }

  /// Log fatal error
  void fatal(String message, {dynamic error, StackTrace? stackTrace}) {
    _log('FATAL', message, error: error, stackTrace: stackTrace);
    _captureException(message, error, stackTrace, level: 'fatal');
  }

  /// Internal logging function
  void _log(
    String level,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    _logHistory.add(entry);

    // Keep history size manageable
    if (_logHistory.length > _maxLogHistory) {
      _logHistory.removeAt(0);
    }

    // Output to console in debug mode
    if (kDebugMode) {
      final output = '[$level] $message';
      debugPrint(output);
      if (error != null) {
        debugPrint('  Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('  Stack: $stackTrace');
      }
    }
  }

  /// Log LinguaBot exception with full context
  void logException(
    LinguaBotException exception, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    final message = '''Exception: ${exception.code}
Message: ${exception.message}
${context != null ? 'Context: $context' : ''}
${additionalData != null ? 'Data: $additionalData' : ''}''';

    error(
      message,
      error: exception,
      stackTrace: exception.stackTrace,
    );

    // Send to crash reporting
    _sendToCrashlytics(
      exception,
      stackTrace: exception.stackTrace,
      context: context,
      additionalData: additionalData,
    );
  }

  /// Log network error with details
  void logNetworkError(
    NetworkException exception, {
    String? url,
    String? method,
    int? statusCode,
    String? responseBody,
  }) {
    final message = '''Network Error: ${exception.code}
URL: $url
Method: $method
Status: $statusCode
Message: ${exception.message}''';

    error(message, error: exception);

    _sendToCrashlytics(
      exception,
      stackTrace: exception.stackTrace,
      additionalData: {
        'url': url,
        'method': method,
        'statusCode': statusCode,
      },
    );
  }

  /// Log API error with details
  void logApiError(
    ApiException exception, {
    String? endpoint,
    String? requestBody,
    String? responseBody,
  }) {
    final message = '''API Error: ${exception.code}
Endpoint: $endpoint
Status: ${exception.statusCode}
Message: ${exception.message}''';

    error(message, error: exception);

    _sendToCrashlytics(
      exception,
      stackTrace: exception.stackTrace,
      additionalData: {
        'endpoint': endpoint,
        'statusCode': exception.statusCode,
      },
    );
  }

  /// Log user action
  void logUserAction(
    String action, {
    Map<String, dynamic>? data,
  }) {
    final message = 'User Action: $action';
    if (data != null) {
      info('$message | Data: $data');
    } else {
      info(message);
    }
  }

  /// Log performance metric
  void logPerformanceMetric(
    String metricName,
    Duration duration, {
    Map<String, dynamic>? metadata,
  }) {
    final message = 'Performance: $metricName took ${duration.inMilliseconds}ms';
    if (metadata != null) {
      info('$message | $metadata');
    } else {
      info(message);
    }
  }

  /// Capture exception for crash reporting
  void _captureException(
    String message,
    dynamic error,
    StackTrace? stackTrace, {
    required String level,
  }) {
    if (kDebugMode) {
      debugPrint('📊 Exception captured: $level - $message');
    }
    // TODO: Integrate with Firebase Crashlytics
    // FirebaseCrashlytics.instance.log('[$level] $message');
    // if (error is Exception) {
    //   FirebaseCrashlytics.instance.recordError(error, stackTrace);
    // }
  }

  /// Send exception to crash reporting service
  void _sendToCrashlytics(
    Exception exception, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    if (kDebugMode) {
      debugPrint(
        '📊 Would send to Crashlytics: ${exception.runtimeType}',
      );
    }
    // TODO: Integrate with Firebase Crashlytics or Sentry
    // FirebaseCrashlytics.instance.recordError(
    //   exception,
    //   stackTrace,
    //   reason: context,
    // );
  }

  /// Get log history
  List<LogEntry> getLogHistory({String? level, int limit = 100}) {
    final filtered = _logHistory
        .where((entry) => level == null || entry.level == level)
        .toList();
    return filtered.length > limit
        ? filtered.sublist(filtered.length - limit)
        : filtered;
  }

  /// Export logs as string
  String exportLogs() {
    return _logHistory.map((e) => e.toString()).join('\n');
  }

  /// Clear log history
  void clearHistory() {
    _logHistory.clear();
    info('📋 Log history cleared');
  }

  /// Get singleton instance
  static LoggingService get instance => _instance;

  /// Check if initialized
  bool get isInitialized => _isInitialized;
}

/// Log entry model
class LogEntry {
  final String level;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    required this.timestamp,
  });

  @override
  String toString() => '[$level] ${timestamp.toIso8601String()} - $message';
}

// Global logging functions for easy access
void log(String message) => LoggingService.instance.info(message);
void logDebug(String message) => LoggingService.instance.debug(message);
void logError(String message, {dynamic error, StackTrace? stackTrace}) =>
    LoggingService.instance.error(message, error: error, stackTrace: stackTrace);
void logWarning(String message) =>
    LoggingService.instance.warning(message);
void logException(LinguaBotException exception, {String? context}) =>
    LoggingService.instance.logException(exception, context: context);
