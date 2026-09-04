import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'database_exceptions.dart';
import 'database_key_manager.dart';
import '../security/privacy_logger.dart';
import '../security/secure_storage_service.dart';
import '../../features/vitals_history/data/models/vital_record_model.dart';

class DatabaseManager {
  DatabaseManager({
    required this.keyManager,
    SecureStorageService? secureStorage,
    this.logger = const PrivacyLogger(),
  }) : secureStorage = secureStorage ?? FlutterSecureStorageService();
  static const _nameKey = 'senvo_active_box_name';
  final DatabaseKeyManager keyManager;
  final SecureStorageService secureStorage;
  final PrivacyLogger logger;
  Box<VitalRecordModel>? _box;
  String? _boxName;
  Future<void>? _initializing;

  Future<void> initialize() {
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(VitalRecordAdapter());
      }
      final key = await keyManager.getOrCreateDatabaseKey();
      _boxName = await _readBoxName();
      _box = await Hive.openBox<VitalRecordModel>(
        _boxName!,
        encryptionCipher: HiveAesCipher(key),
      );
      logger.info('Local encrypted database initialized');
    } catch (_) {
      throw const LocalDatabaseException(
        'Local health storage could not be initialized.',
      );
    }
  }

  Future<String> _readBoxName() async =>
      (await _readStoredBoxName()) ?? 'vital_records_v1';
  Future<String?> _readStoredBoxName() => secureStorage.read(_nameKey);
  Box<VitalRecordModel> get box {
    final value = _box;
    if (value == null || !value.isOpen) {
      throw const LocalDatabaseException('Local health storage is not ready.');
    }
    return value;
  }

  Future<void> close() async {
    await _box?.close();
    _box = null;
    _initializing = null;
    logger.info('Local encrypted database closed');
  }

  Future<void> clearDatabase() async {
    await box.clear();
  }

  Future<void> wipeAllLocalData() async {
    final activeBox = _box;
    final activeName = _boxName;
    if (activeBox != null && activeBox.isOpen) {
      await activeBox.clear();
      await activeBox.close();
    }
    if (activeName != null) await Hive.deleteBoxFromDisk(activeName);
    await secureStorage.delete(_nameKey);
    await keyManager.deleteDatabaseKey();
    _box = null;
    _boxName = null;
    _initializing = null;
    logger.info('All local health data wiped');
    await initialize();
  }

  Future<void> rotateDatabaseKey() async {
    final oldBox = box;
    final records = oldBox.values.toList(growable: false);
    final newName =
        'vital_records_${DateTime.now().millisecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
    final newKey = List<int>.generate(
      32,
      (_) => Random.secure().nextInt(256),
      growable: false,
    );
    final newBox = await Hive.openBox<VitalRecordModel>(
      newName,
      encryptionCipher: HiveAesCipher(newKey),
    );
    await newBox.putAll({for (final record in records) record.id: record});
    await newBox.flush();
    await keyManager.storeDatabaseKey(newKey);
    await secureStorage.write(_nameKey, newName);
    await oldBox.close();
    await Hive.deleteBoxFromDisk(_boxName!);
    _box = newBox;
    _boxName = newName;
    logger.info('Local database encryption key rotated');
  }
}
