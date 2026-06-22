// AES-256-GCM encryption service for API keys and sensitive data
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

import '../constants/app_constants.dart';

class EncryptionService {
  EncryptionService._(this._secureStorage, this._key);

  final FlutterSecureStorage _secureStorage;
  final Key _key;

  static const _keyStorageId = 'omniforge_master_key';
  static const _ivLength = 12; // GCM standard

  static Future<EncryptionService> create() async {
    const storage = FlutterSecureStorage();
    var keyBytes = await storage.read(key: _keyStorageId);

    if (keyBytes == null) {
      // Generate new 256-bit key
      final random = _generateSecureBytes(32);
      keyBytes = base64Encode(random);
      await storage.write(key: _keyStorageId, value: keyBytes);
    }

    final key = Key.fromBase64(keyBytes);
    return EncryptionService._(storage, key);
  }

  /// Encrypt a plaintext string and return base64 payload (iv + ciphertext + tag)
  Future<String> encrypt(String plaintext) async {
    final iv = IV.fromSecureRandom(_ivLength);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(_key.bytes),
          128, // tag length in bits
          iv.bytes,
          Uint8List(0), // additional authenticated data
        ),
      );

    final input = utf8.encode(plaintext);
    final output = cipher.process(Uint8List.fromList(input));

    // Combine IV + ciphertext+tag for storage
    final combined = BytesBuilder()
      ..add(iv.bytes)
      ..add(output);
    return base64Encode(combined.toBytes());
  }

  /// Decrypt a base64 payload produced by [encrypt]
  Future<String> decrypt(String ciphertextBase64) async {
    final combined = base64Decode(ciphertextBase64);
    final ivBytes = combined.sublist(0, _ivLength);
    final cipherBytes = combined.sublist(_ivLength);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(_key.bytes),
          128,
          ivBytes,
          Uint8List(0),
        ),
      );

    final decrypted = cipher.process(cipherBytes);
    return utf8.decode(decrypted);
  }

  /// Store an API key encrypted under a provider namespace
  Future<void> storeApiKey(String provider, String apiKey) async {
    final encrypted = await encrypt(apiKey);
    await _secureStorage.write(
      key: '${AppConstants.secureStorageKey}_api_$provider',
      value: encrypted,
    );
  }

  /// Retrieve and decrypt an API key for a provider
  Future<String?> getApiKey(String provider) async {
    final encrypted = await _secureStorage.read(
      key: '${AppConstants.secureStorageKey}_api_$provider',
    );
    if (encrypted == null) return null;
    try {
      return await decrypt(encrypted);
    } catch (_) {
      return null;
    }
  }

  /// Delete a stored API key
  Future<void> deleteApiKey(String provider) async {
    await _secureStorage.delete(
      key: '${AppConstants.secureStorageKey}_api_$provider',
    );
  }

  /// List all providers with stored keys (without decrypting them)
  Future<Set<String>> listStoredProviders() async {
    final all = await _secureStorage.readAll();
    return all.keys
        .where((k) => k.startsWith('${AppConstants.secureStorageKey}_api_'))
        .map((k) => k.substring('${AppConstants.secureStorageKey}_api_'.length))
        .toSet();
  }

  static Uint8List _generateSecureBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }
}
