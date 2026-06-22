// Unit tests for EncryptionService
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniforge_ai/core/security/encryption_service.dart';

void main() {
  // flutter_secure_storage routes through a method channel; in unit tests
  // the channel handler is not attached by default, so calls would crash.
  // `setMockInitialValues` installs an in-memory mock with the given seed
  // values (here empty) so reads/writes/deletes resolve within the test
  // process. It must be re-installed before each test so state from a
  // prior test cannot leak into the next.
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('EncryptionService', () {
    test('encrypt and decrypt roundtrip returns original plaintext', () async {
      final service = await EncryptionService.create();
      const plaintext = 'sk-test-api-key-12345-secret';

      final encrypted = await service.encrypt(plaintext);
      expect(encrypted, isNot(equals(plaintext)));

      final decrypted = await service.decrypt(encrypted);
      expect(decrypted, equals(plaintext));
    });

    test('storeApiKey and getApiKey persist across calls', () async {
      final service = await EncryptionService.create();
      const provider = 'openai';
      const apiKey = 'sk-my-openai-key-abc';

      await service.storeApiKey(provider, apiKey);
      final retrieved = await service.getApiKey(provider);

      expect(retrieved, equals(apiKey));
    });

    test('deleteApiKey removes the key', () async {
      final service = await EncryptionService.create();
      const provider = 'test_provider';

      await service.storeApiKey(provider, 'some-key');
      await service.deleteApiKey(provider);

      final retrieved = await service.getApiKey(provider);
      expect(retrieved, isNull);
    });

    test('listStoredProviders includes saved providers', () async {
      final service = await EncryptionService.create();
      await service.storeApiKey('test_one', 'key1');
      await service.storeApiKey('test_two', 'key2');

      final providers = await service.listStoredProviders();
      expect(providers, containsAll(['test_one', 'test_two']));
    });
  });
}
