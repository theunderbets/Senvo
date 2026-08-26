import 'dart:convert';
import 'dart:math';
import '../security/secure_storage_service.dart';

abstract interface class DatabaseKeyManager {
  Future<List<int>> getOrCreateDatabaseKey();
  Future<void> rotateDatabaseKey();
  Future<void> storeDatabaseKey(List<int> key);
  Future<void> deleteDatabaseKey();
}

class SecureDatabaseKeyManager implements DatabaseKeyManager {
  SecureDatabaseKeyManager(this.secureStorage);
  static const keyName = 'senvo_database_encryption_key';
  final SecureStorageService secureStorage;

  @override
  Future<List<int>> getOrCreateDatabaseKey() async {
    final encoded = await secureStorage.read(keyName);
    if (encoded != null) return base64Url.decode(encoded);
    final key = List<int>.generate(
      32,
      (_) => Random.secure().nextInt(256),
      growable: false,
    );
    await secureStorage.write(keyName, base64UrlEncode(key));
    return key;
  }

  @override
  Future<void> rotateDatabaseKey() async {
    final key = List<int>.generate(
      32,
      (_) => Random.secure().nextInt(256),
      growable: false,
    );
    await storeDatabaseKey(key);
  }

  @override
  Future<void> storeDatabaseKey(List<int> key) =>
      secureStorage.write(keyName, base64UrlEncode(key));

  @override
  Future<void> deleteDatabaseKey() => secureStorage.delete(keyName);
}
