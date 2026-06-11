/// Functional error handling using Result type
/// Inspired by Rust's Result<T, E> and Dart's Either type

abstract class Result<S, F extends Exception> {
  const Result();

  /// Map success value
  Result<T, F> map<T>(T Function(S) f) => fold(
    onSuccess: (value) => Success(f(value)),
    onFailure: (error) => Failure(error),
  );

  /// FlatMap for chaining operations
  Result<T, F> flatMap<T>(Result<T, F> Function(S) f) => fold(
    onSuccess: f,
    onFailure: (error) => Failure(error),
  );

  /// Handle both success and failure cases
  T fold<T>({
    required T Function(S) onSuccess,
    required T Function(F) onFailure,
  });

  /// Get success value or null
  S? getOrNull() => fold(
    onSuccess: (value) => value,
    onFailure: (_) => null,
  );

  /// Get error or null
  F? getErrorOrNull() => fold(
    onSuccess: (_) => null,
    onFailure: (error) => error,
  );

  /// Check if result is success
  bool isSuccess() => fold(
    onSuccess: (_) => true,
    onFailure: (_) => false,
  );

  /// Check if result is failure
  bool isFailure() => fold(
    onSuccess: (_) => false,
    onFailure: (_) => true,
  );

  /// Get success value or throw error
  S getOrThrow() => fold(
    onSuccess: (value) => value,
    onFailure: (error) => throw error,
  );

  /// Get success value with default fallback
  S getOrElse(S fallback) => fold(
    onSuccess: (value) => value,
    onFailure: (_) => fallback,
  );

  /// Execute side effect on success
  Result<S, F> tap(void Function(S) f) {
    fold(
      onSuccess: f,
      onFailure: (_) => null,
    );
    return this;
  }

  /// Execute side effect on failure
  Result<S, F> tapError(void Function(F) f) {
    fold(
      onSuccess: (_) => null,
      onFailure: f,
    );
    return this;
  }

  /// Convert failure to different type
  Result<S, T> mapError<T extends Exception>(T Function(F) f) => fold(
    onSuccess: (value) => Success(value),
    onFailure: (error) => Failure(f(error)),
  );
}

/// Success result wrapper
class Success<S, F extends Exception> extends Result<S, F> {
  final S value;

  const Success(this.value);

  @override
  T fold<T>({
    required T Function(S) onSuccess,
    required T Function(F) onFailure,
  }) =>
      onSuccess(value);

  @override
  String toString() => 'Success($value)';
}

/// Failure result wrapper
class Failure<S, F extends Exception> extends Result<S, F> {
  final F error;

  const Failure(this.error);

  @override
  T fold<T>({
    required T Function(S) onSuccess,
    required T Function(F) onFailure,
  }) =>
      onFailure(error);

  @override
  String toString() => 'Failure($error)';
}

/// Type alias for common error result
typedef ResultE<S> = Result<S, Exception>;

/// Extension for Future to wrap in Result
extension FutureResultExt<S> on Future<S> {
  /// Convert Future to Result, catching exceptions
  Future<Result<S, Exception>> toResult() async {
    try {
      final value = await this;
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
