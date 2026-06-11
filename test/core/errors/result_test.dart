import 'package:flutter_test/flutter_test.dart';
import 'package:linguabot/core/errors/result.dart';

// ignore: unused_element
class _CustomException implements Exception {
  final String code;
  _CustomException(this.code);

  @override
  String toString() => 'CustomException: $code';
}

void main() {
  group('Result Type', () {
    group('Success<T, E>', () {
      test('creates success result', () {
        final result = Success<String, Exception>('value');

        expect(result, isA<Success>());
        expect(result.getOrNull(), equals('value'));
      });

      test('isSuccess returns true', () {
        final result = Success<String, Exception>('value');
        expect(result.isSuccess(), isTrue);
        expect(result.isFailure(), isFalse);
      });

      test('fold executes success branch', () {
        final result = Success<String, Exception>('value');

        final folded = result.fold(
          onSuccess: (value) => value.toUpperCase(),
          onFailure: (_) => 'error',
        );

        expect(folded, equals('VALUE'));
      });

      test('map transforms the value', () {
        final result = Success<String, Exception>('hello');

        final mapped = result.map((value) => value.length);

        expect(mapped.getOrNull(), equals(5));
      });

      test('tap executes side effect and returns self', () {
        var sideEffectExecuted = false;
        final result = Success<String, Exception>('value');

        final returned = result.tap((value) {
          sideEffectExecuted = true;
        });

        expect(sideEffectExecuted, isTrue);
        expect(returned, equals(result));
      });

      test('getOrElse returns success value', () {
        final result = Success<String, Exception>('value');
        final value = result.getOrElse('fallback');

        expect(value, equals('value'));
      });

      test('getOrThrow returns value', () {
        final result = Success<String, Exception>('value');
        expect(result.getOrThrow(), equals('value'));
      });
    });

    group('Failure<T, E>', () {
      test('creates failure result', () {
        final error = Exception('error message');
        final result = Failure<String, Exception>(error);

        expect(result, isA<Failure>());
        expect(result.getErrorOrNull(), equals(error));
      });

      test('isFailure returns true', () {
        final result = Failure<String, Exception>(Exception('error'));
        expect(result.isFailure(), isTrue);
        expect(result.isSuccess(), isFalse);
      });

      test('fold executes failure branch', () {
        final error = Exception('error');
        final result = Failure<String, Exception>(error);

        final folded = result.fold(
          onSuccess: (_) => 'success',
          onFailure: (e) => e.toString(),
        );

        expect(folded, contains('error'));
      });

      test('map does not transform on failure', () {
        final error = Exception('error');
        final result = Failure<String, Exception>(error);

        final mapped = result.map((value) => value.length);

        expect(mapped.getOrNull(), isNull);
        expect(mapped.getErrorOrNull(), equals(error));
      });

      test('tapError executes side effect and returns self', () {
        var sideEffectExecuted = false;
        final error = Exception('error');
        final result = Failure<String, Exception>(error);

        final returned = result.tapError((e) {
          sideEffectExecuted = true;
        });

        expect(sideEffectExecuted, isTrue);
        expect(returned, equals(result));
      });

      test('getOrElse returns fallback value', () {
        final result = Failure<String, Exception>(Exception('error'));
        final value = result.getOrElse('fallback');

        expect(value, equals('fallback'));
      });

      test('getOrThrow throws error', () {
        final error = Exception('error message');
        final result = Failure<String, Exception>(error);

        expect(() => result.getOrThrow(), throwsException);
      });
    });

    group('flatMap', () {
      test('chains successful results', () {
        final result = Success<String, Exception>('hello');

        final chained = result.flatMap((value) {
          return Success<int, Exception>(value.length);
        });

        expect(chained.getOrNull(), equals(5));
      });

      test('returns failure if operation fails', () {
        final result = Success<String, Exception>('hello');
        final error = Exception('error');

        final chained = result.flatMap((value) {
          return Failure<int, Exception>(error);
        });

        expect(chained.getErrorOrNull(), equals(error));
      });

      test('propagates existing failure', () {
        final error = Exception('original error');
        final result = Failure<String, Exception>(error);

        final chained = result.flatMap((value) {
          return Success<int, Exception>(value.length);
        });

        expect(chained.getErrorOrNull(), equals(error));
      });
    });

    group('mapError', () {
      test('transforms error type on failure', () {
        class TransformedException extends Exception {
          final String message;
          TransformedException(this.message);
        }

        final originalError = Exception('original');
        final result = Failure<String, Exception>(originalError);

        final transformed = result.mapError<TransformedException>(
          (e) => TransformedException('transformed: ${e.toString()}'),
        );

        expect(transformed.getErrorOrNull(), isA<TransformedException>());
      });

      test('preserves success value', () {
        class CustomException extends Exception {
          final String message;
          CustomException(this.message);
        }

        final result = Success<String, Exception>('value');

        final transformed = result.mapError<CustomException>(
          (e) => CustomException('error'),
        );

        expect(transformed.getOrNull(), equals('value'));
      });
    });

    group('getOrNull', () {
      test('returns value on success', () {
        final result = Success<String, Exception>('value');
        expect(result.getOrNull(), equals('value'));
      });

      test('returns null on failure', () {
        final result = Failure<String, Exception>(Exception('error'));
        expect(result.getOrNull(), isNull);
      });
    });

    group('getErrorOrNull', () {
      test('returns null on success', () {
        final result = Success<String, Exception>('value');
        expect(result.getErrorOrNull(), isNull);
      });

      test('returns error on failure', () {
        final error = Exception('error');
        final result = Failure<String, Exception>(error);
        expect(result.getErrorOrNull(), equals(error));
      });
    });

    group('Type safety', () {
      test('preserves type information', () {
        final stringResult = Success<String, Exception>('hello');
        final intResult = Success<int, Exception>(42);

        expect(stringResult.getOrNull(), isA<String>());
        expect(intResult.getOrNull(), isA<int>());
      });

      test('works with custom exception types', () {
        class CustomException extends Exception {
          final String code;
          CustomException(this.code);
        }

        final error = CustomException('ERROR_CODE');
        final result = Failure<String, CustomException>(error);

        expect(result.getErrorOrNull(), isA<CustomException>());
        expect(result.getErrorOrNull()?.code, equals('ERROR_CODE'));
      });
    });
  });
}
