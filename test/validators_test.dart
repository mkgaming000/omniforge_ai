// Unit tests for Validators
import 'package:flutter_test/flutter_test.dart';
import 'package:omniforge_ai/core/validators/validators.dart';

void main() {
  group('Validators', () {
    group('required', () {
      test('returns error for null value', () {
        expect(Validators.required(null), isNotNull);
      });
      test('returns error for empty value', () {
        expect(Validators.required(''), isNotNull);
        expect(Validators.required('   '), isNotNull);
      });
      test('returns null for non-empty value', () {
        expect(Validators.required('hello'), isNull);
      });
    });

    group('email', () {
      test('validates correct emails', () {
        expect(Validators.email('test@example.com'), isNull);
        expect(Validators.email('user.name+tag@sub.example.org'), isNull);
      });
      test('rejects invalid emails', () {
        expect(Validators.email('not-an-email'), isNotNull);
        expect(Validators.email('missing@domain'), isNotNull);
        expect(Validators.email('@example.com'), isNotNull);
      });
      test('allows empty (optional)', () {
        expect(Validators.email(''), isNull);
      });
    });

    group('apiKey', () {
      test('rejects empty key', () {
        expect(Validators.apiKey(''), isNotNull);
        expect(Validators.apiKey('  '), isNotNull);
      });
      test('rejects short key', () {
        expect(Validators.apiKey('sk-short'), isNotNull);
      });
      test('accepts valid key', () {
        expect(
          Validators.apiKey('sk-abcdefghijklmnopqrstuvwxyz0123456789'),
          isNull,
        );
      });
    });

    group('url', () {
      test('validates HTTP URLs', () {
        expect(Validators.url('http://example.com'), isNull);
        expect(Validators.url('https://api.openai.com/v1'), isNull);
      });
      test('rejects non-HTTP schemes', () {
        expect(Validators.url('ftp://example.com'), isNotNull);
        expect(Validators.url('file:///etc/passwd'), isNotNull);
      });
      test('allows empty (optional)', () {
        expect(Validators.url(''), isNull);
      });
    });

    group('minLength', () {
      test('enforces minimum length', () {
        expect(Validators.minLength('ab', 5), isNotNull);
        expect(Validators.minLength('abcde', 5), isNull);
      });
    });

    group('maxLength', () {
      test('enforces maximum length', () {
        expect(Validators.maxLength('abcdef', 5), isNotNull);
        expect(Validators.maxLength('abc', 5), isNull);
      });
    });

    group('numeric', () {
      test('validates numeric strings', () {
        expect(Validators.numeric('123'), isNull);
        expect(Validators.numeric('3.14'), isNull);
        expect(Validators.numeric('-5'), isNull);
      });
      test('rejects non-numeric strings', () {
        expect(Validators.numeric('abc'), isNotNull);
        expect(Validators.numeric('12abc'), isNotNull);
      });
    });

    group('range', () {
      test('validates within range', () {
        expect(Validators.range('5', 0, 10), isNull);
        expect(Validators.range('0', 0, 10), isNull);
        expect(Validators.range('10', 0, 10), isNull);
      });
      test('rejects outside range', () {
        expect(Validators.range('-1', 0, 10), isNotNull);
        expect(Validators.range('11', 0, 10), isNotNull);
      });
    });

    group('prompt', () {
      test('rejects empty prompt', () {
        expect(Validators.prompt(''), isNotNull);
        expect(Validators.prompt('   '), isNotNull);
      });
      test('rejects excessively long prompt', () {
        final long = 'a' * 32001;
        expect(Validators.prompt(long), isNotNull);
      });
      test('accepts valid prompt', () {
        expect(Validators.prompt('Generate an image of a cat'), isNull);
      });
    });
  });
}
