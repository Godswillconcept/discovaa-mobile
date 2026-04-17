import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  static HiveService? _instance;
  static HiveService get instance => _instance ??= HiveService._();

  HiveService._();

  late Box _box;

  /// Initialize Hive service
  Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    _box = await Hive.openBox('discovaa_storage');
  }

  /// Store a string value
  Future<void> setString(String key, String value) async {
    await _box.put(key, value);
  }

  /// Get a string value
  String? getString(String key) {
    return _box.get(key);
  }

  /// Store an integer value
  Future<void> setInt(String key, int value) async {
    await _box.put(key, value);
  }

  /// Get an integer value
  int? getInt(String key) {
    return _box.get(key);
  }

  /// Store a double value
  Future<void> setDouble(String key, double value) async {
    await _box.put(key, value);
  }

  /// Get a double value
  double? getDouble(String key) {
    return _box.get(key);
  }

  /// Store a boolean value
  Future<void> setBool(String key, bool value) async {
    await _box.put(key, value);
  }

  /// Get a boolean value
  bool? getBool(String key) {
    return _box.get(key);
  }

  /// Store a list value
  Future<void> setList<T>(String key, List<T> value) async {
    await _box.put(key, value);
  }

  /// Get a list value
  List<T>? getList<T>(String key) {
    return _box.get(key);
  }

  /// Store a map value
  Future<void> setMap(String key, Map<String, dynamic> value) async {
    await _box.put(key, value);
  }

  /// Get a map value
  Map<String, dynamic>? getMap(String key) {
    final value = _box.get(key);
    if (value == null) return null;

    // Hive stores maps as Map<dynamic, dynamic>, so we need to cast it
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  /// Remove a value by key
  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  /// Clear all stored values
  Future<void> clear() async {
    await _box.clear();
  }

  /// Check if a key exists
  bool containsKey(String key) {
    return _box.containsKey(key);
  }

  /// Get all keys
  Iterable<dynamic> getKeys() {
    return _box.keys;
  }

  /// Close the box
  Future<void> close() async {
    await _box.close();
  }

  /// Compact the box to reduce size
  Future<void> compact() async {
    await _box.compact();
  }
}
