import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'exceptions.dart';

/// Central error handling with retry logic, logging, and user-friendly messages
class ErrorHandler {
  static const int _defaultMaxRetries = 3;
  static const Duration _defaultInitialDelay = Duration(milliseconds: 500);

  /// Map exceptions to user-friendly messages
  static String getUserMessage(Exception exception) {
    if (exception is LinguaBotException) {
      return exception.message;
    }

    if (exception is TimeoutException) {
      return 'The request took too long. Please check your connection and try again.';
    }

    if (exception is SocketException) {
      return 'Network connection failed. Please check your internet connection.';
    }

    return 'An unexpected error occurred. Please try again later.';
  }

  /// Get error code for logging/analytics
  static String getErrorCode(Exception exception) {
    if (exception is LinguaBotException) {
      return exception.code ?? 'UNKNOWN';
    }
    return 'UNMAPPED_ERROR';
  }

  /// Log error with context
  static void logError(
    Exception exception, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalInfo,
  }) {
    if (kDebugMode) {
      debugPrint(
        '❌ ERROR [${getErrorCode(exception)}]: ${exception.toString()}',
      );
      if (context != null) {
        debugPrint('   Context: $context');
      }
      if (additionalInfo != null) {
        debugPrint('   Info: $additionalInfo');
      }
      if (stackTrace != null) {
        debugPrint('   Stack: $stackTrace');
      }
    }

    // In production, send to Sentry/Crashlytics
    // FirebaseCrashlytics.instance.recordError(exception, stackTrace);
  }

  /// Retry a function with exponential backoff
  static Future<T> retry<T>(
    Future<T> Function() fn, {
    int maxRetries = _defaultMaxRetries,
    Duration initialDelay = _defaultInitialDelay,
    double backoffMultiplier = 2.0,
    bool Function(Exception)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await fn();
      } on Exception catch (e) {
        attempt++;

        // Don't retry if max attempts reached
        if (attempt >= maxRetries) {
          rethrow;
        }

        // Custom retry logic
        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }

        // Don't retry validation or auth errors
        if (e is ValidationException || e is AuthenticationException) {
          rethrow;
        }

        // Log retry attempt
        if (kDebugMode) {
          debugPrint(
            '⏳ Retry attempt $attempt/$maxRetries after ${delay.inMilliseconds}ms',
          );
        }

        // Wait before retry
        await Future.delayed(delay);

        // Increase delay exponentially
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).toInt(),
        );
      }
    }
  }

  /// Wrap a function to handle errors gracefully
  static Future<T?> safeCall<T>(
    Future<T> Function() fn, {
    T? defaultValue,
    void Function(Exception)? onError,
    String? errorContext,
  }) async {
    try {
      return await fn();
    } on Exception catch (e) {
      logError(e, context: errorContext);
      onError?.call(e);
      return defaultValue;
    }
  }

  /// Wrap sync function to handle errors
  static T? safeSyncCall<T>(
    T Function() fn, {
    T? defaultValue,
    void Function(Exception)? onError,
    String? errorContext,
  }) {
    try {
      return fn();
    } on Exception catch (e) {
      logError(e, context: errorContext);
      onError?.call(e);
      return defaultValue;
    }
  }

  /// Combine multiple futures and collect errors
  static Future<List<T>> tryAll<T>(List<Future<T> Function()> futures) async {
    final results = <T>[];
    final errors = <Exception>[];

    for (final futureFactory in futures) {
      try {
        results.add(await futureFactory());
      } on Exception catch (e) {
        errors.add(e);
      }
    }

    if (errors.isNotEmpty && results.isEmpty) {
      throw UnknownException(
        message: 'All operations failed',
        originalException: errors.first,
      );
    }

    return results;
  }

  /// Handle stream errors
  static Stream<T> handleStreamErrors<T>(
    Stream<T> stream, {
    void Function(Exception)? onError,
    T? Function(Exception)? recover,
  }) {
    return stream.handleError((dynamic error, StackTrace stackTrace) {
      if (error is Exception) {
        logError(error, stackTrace: stackTrace);
        onError?.call(error);
        final recovery = recover?.call(error);
        if (recovery != null) {
          // Emit recovered value
        }
      }
    });
  }

  /// Check if error is retryable
  static bool isRetryable(Exception exception) {
    // Retryable errors
    if (exception is NetworkException) return true;
    if (exception is ApiException &&
        exception.statusCode != null &&
        (exception.statusCode == 429 ||
            exception.statusCode == 503 ||
            exception.statusCode == 504)) {
      return true;
    }
    if (exception is TimeoutException) return true;

    // Non-retryable errors
    if (exception is ValidationException) return false;
    if (exception is AuthenticationException) return false;
    if (exception is ApiException &&
        exception.statusCode != null &&
        exception.statusCode! < 500) {
      return false;
    }

    return false;
  }

  /// Get user action recommendation
  static String getRecommendation(Exception exception) {
    if (exception is NetworkException) {
      return 'Please check your internet connection and try again.';
    }

    if (exception is AuthenticationException) {
      return 'Please log in again.';
    }

    if (exception is ValidationException) {
      return 'Please check your input and try again.';
    }

    if (exception is ApiException) {
      if (exception.statusCode == 429) {
        return 'Please wait a moment before trying again.';
      }
      if (exception.statusCode == 503) {
        return 'The service is temporarily unavailable. Please try again in a few moments.';
      }
    }

    if (exception is AudioException) {
      return 'Please check your audio settings or try again.';
    }

    return 'Please try again later or contact support if the problem persists.';
  }
}

/// Extension for easy error handling on Future
extension FutureErrorHandling<T> on Future<T> {
  /// Retry on failure
  Future<T> withRetry({
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) =>
      ErrorHandler.retry(
        () => this,
        maxRetries: maxRetries,
        initialDelay: initialDelay,
      );

  /// Handle errors safely
  Future<T?> withErrorHandler({
    T? defaultValue,
    void Function(Exception)? onError,
  }) =>
      ErrorHandler.safeCall(
        () => this,
        defaultValue: defaultValue,
        onError: onError,
      );
}

/// Exception with user-friendly message
class UserFriendlyException extends LinguaBotException {
  final String userMessage;
  final String? recommendation;

  UserFriendlyException({
    required this.userMessage,
    required String message,
    String? code,
    this.recommendation,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalException: originalException,
    stackTrace: stackTrace,
  );
}
