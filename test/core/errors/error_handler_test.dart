import 'package:flutter_test/flutter_test.dart';
import 'package:linguabot/core/errors/error_handler.dart';
import 'package:linguabot/core/errors/exceptions.dart';

void main() {
  group('ErrorHandler', () {
    group('getUserMessage', () {
      test('returns custom message for LinguaBotException', () {
        final exception = ValidationException.emptyField('Email');
        final message = ErrorHandler.getUserMessage(exception);

        expect(message, equals('Email cannot be empty.'));
      });

      test('returns custom message for NetworkException', () {
        final exception = NetworkException.timeout();
        final message = ErrorHandler.getUserMessage(exception);

        expect(
          message,
          equals(
              'Request timed out. Please check your connection and try again.'),
        );
      });

      test('returns default message for unknown exception', () {
        final exception = Exception('Unknown error');
        final message = ErrorHandler.getUserMessage(exception);

        expect(
          message,
          equals(
              'An unexpected error occurred. Please try again later.'),
        );
      });
    });

    group('getErrorCode', () {
      test('returns error code from LinguaBotException', () {
        final exception = AuthenticationException.invalidCredentials();
        final code = ErrorHandler.getErrorCode(exception);

        expect(code, equals('INVALID_CREDENTIALS'));
      });

      test('returns UNMAPPED_ERROR for unknown exception', () {
        final exception = Exception('Unknown');
        final code = ErrorHandler.getErrorCode(exception);

        expect(code, equals('UNMAPPED_ERROR'));
      });
    });

    group('isRetryable', () {
      test('returns true for NetworkException', () {
        final exception = NetworkException.noConnection();
        expect(ErrorHandler.isRetryable(exception), isTrue);
      });

      test('returns true for rate limit error', () {
        final exception = ApiException.rateLimited();
        expect(ErrorHandler.isRetryable(exception), isTrue);
      });

      test('returns true for service unavailable', () {
        final exception = ApiException.serviceUnavailable();
        expect(ErrorHandler.isRetryable(exception), isTrue);
      });

      test('returns false for ValidationException', () {
        final exception = ValidationException.invalidEmail();
        expect(ErrorHandler.isRetryable(exception), isFalse);
      });

      test('returns false for AuthenticationException', () {
        final exception = AuthenticationException.invalidCredentials();
        expect(ErrorHandler.isRetryable(exception), isFalse);
      });

      test('returns false for 4xx API errors', () {
        final exception = ApiException(
          message: 'Bad request',
          statusCode: 400,
        );
        expect(ErrorHandler.isRetryable(exception), isFalse);
      });
    });

    group('getRecommendation', () {
      test('provides recommendation for NetworkException', () {
        final exception = NetworkException.noConnection();
        final recommendation = ErrorHandler.getRecommendation(exception);

        expect(
          recommendation,
          contains('internet connection'),
        );
      });

      test('provides recommendation for rate limit', () {
        final exception = ApiException.rateLimited();
        final recommendation = ErrorHandler.getRecommendation(exception);

        expect(recommendation, contains('wait'));
      });

      test('provides recommendation for AuthenticationException', () {
        final exception = AuthenticationException.sessionExpired();
        final recommendation = ErrorHandler.getRecommendation(exception);

        expect(recommendation, contains('log in'));
      });

      test('provides generic recommendation for unknown error', () {
        final exception = Exception('Unknown');
        final recommendation = ErrorHandler.getRecommendation(exception);

        expect(recommendation, isNotEmpty);
      });
    });

    group('retry', () {
      test('returns value on success', () async {
        var callCount = 0;
        final result = await ErrorHandler.retry(
          () async {
            callCount++;
            return 'success';
          },
          maxRetries: 3,
        );

        expect(result, equals('success'));
        expect(callCount, equals(1));
      });

      test('retries on failure and eventually succeeds', () async {
        var callCount = 0;
        final result = await ErrorHandler.retry(
          () async {
            callCount++;
            if (callCount < 3) {
              throw NetworkException.noConnection();
            }
            return 'success';
          },
          maxRetries: 3,
          initialDelay: Duration.zero,
          backoffMultiplier: 1.0,
        );

        expect(result, equals('success'));
        expect(callCount, equals(3));
      });

      test('throws after max retries exceeded', () async {
        var callCount = 0;
        expect(
          () => ErrorHandler.retry(
            () async {
              callCount++;
              throw NetworkException.noConnection();
            },
            maxRetries: 3,
            initialDelay: Duration.zero,
            backoffMultiplier: 1.0,
          ),
          throwsA(isA<NetworkException>()),
        );

        expect(callCount, equals(3));
      });

      test('does not retry non-retryable exceptions', () async {
        var callCount = 0;
        expect(
          () => ErrorHandler.retry(
            () async {
              callCount++;
              throw ValidationException.invalidEmail();
            },
            maxRetries: 3,
          ),
          throwsA(isA<ValidationException>()),
        );

        expect(callCount, equals(1));
      });
    });

    group('safeCall', () {
      test('returns value on success', () async {
        final result = await ErrorHandler.safeCall(
          () async => 'success',
        );

        expect(result, equals('success'));
      });

      test('returns default value on error', () async {
        final result = await ErrorHandler.safeCall(
          () async => throw Exception('Error'),
          defaultValue: 'default',
        );

        expect(result, equals('default'));
      });

      test('calls onError callback on failure', () async {
        Exception? captedException;
        await ErrorHandler.safeCall(
          () async => throw NetworkException.noConnection(),
          onError: (e) => captedException = e,
        );

        expect(captedException, isA<NetworkException>());
      });

      test('returns null by default on error', () async {
        final result = await ErrorHandler.safeCall(
          () async => throw Exception('Error'),
        );

        expect(result, isNull);
      });
    });

    group('CustomExceptions', () {
      test('NetworkException has correct fields', () {
        final exception = NetworkException.timeout();

        expect(exception.code, equals('TIMEOUT'));
        expect(exception.message, contains('timed out'));
      });

      test('ValidationException stores field errors', () {
        final exception = ValidationException.multipleErrors({
          'email': 'Invalid format',
          'password': 'Too weak',
        });

        expect(exception.fieldErrors, isNotNull);
        expect(exception.fieldErrors!.length, equals(2));
      });

      test('ApiException stores status code', () {
        final exception = ApiException(
          message: 'Server error',
          statusCode: 500,
        );

        expect(exception.statusCode, equals(500));
      });

      test('LinguaBotException stores stack trace', () {
        final stackTrace = StackTrace.current;
        final exception = UnknownException(
          message: 'Test error',
          stackTrace: stackTrace,
        );

        expect(exception.stackTrace, equals(stackTrace));
      });
    });
  });
}
