// Unit tests for Failure types
import 'package:flutter_test/flutter_test.dart';
import 'package:omniforge_ai/core/errors/failures.dart';

void main() {
  group('Failures', () {
    test('NetworkFailure has correct user message', () {
      const failure = NetworkFailure();
      expect(
        failure.userMessage,
        contains('Network error'),
      );
    });

    test('NetworkFailure preserves custom message', () {
      const failure = NetworkFailure(message: 'Custom error');
      expect(failure.userMessage, equals('Custom error'));
    });

    test('UnauthorizedFailure mentions API key', () {
      const failure = UnauthorizedFailure();
      expect(
        failure.userMessage.toLowerCase(),
        contains('api key'),
      );
    });

    test('RateLimitFailure mentions rate limit', () {
      const failure = RateLimitFailure();
      expect(
        failure.userMessage.toLowerCase(),
        contains('rate limit'),
      );
    });

    test('TimeoutFailure mentions timeout', () {
      const failure = TimeoutFailure();
      expect(
        failure.userMessage.toLowerCase(),
        contains('timed out'),
      );
    });

    test('NotFoundFailure mentions not found', () {
      const failure = NotFoundFailure();
      expect(
        failure.userMessage.toLowerCase(),
        contains('not found'),
      );
    });

    test('ValidationFailure uses default when no message', () {
      const failure = ValidationFailure();
      expect(
        failure.userMessage.toLowerCase(),
        contains('invalid'),
      );
    });

    test('SecurityFailure mentions verification', () {
      const failure = SecurityFailure();
      expect(
        failure.userMessage.toLowerCase(),
        contains('security'),
      );
    });

    test('ProviderFailure mentions trying another model', () {
      const failure = ProviderFailure();
      expect(
        failure.userMessage.toLowerCase(),
        contains('model'),
      );
    });

    test('failures support equality', () {
      const f1 = NetworkFailure(message: 'test', code: '500');
      const f2 = NetworkFailure(message: 'test', code: '500');
      expect(f1, equals(f2));
      expect(f1.hashCode, equals(f2.hashCode));
    });

    test('failures preserve originalError and stackTrace', () {
      final error = Exception('boom');
      final stack = StackTrace.current;
      final failure = UnknownFailure(
        message: 'test',
        originalError: error,
        stackTrace: stack,
      );
      expect(failure.originalError, equals(error));
      expect(failure.stackTrace, equals(stack));
    });
  });
}
