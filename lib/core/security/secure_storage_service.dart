import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../models/converted_file.dart';

class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _historyKey = 'conversion_history';

  Future<List<ConvertedFile>> getHistory() async {
    try {
      final raw = await _storage.read(key: _historyKey);
      if (raw == null) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => ConvertedFile.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addToHistory(ConvertedFile file) async {
    final history = await getHistory();
    history.insert(0, file);
    final trimmed = history.take(50).toList();
    await _storage.write(
        key: _historyKey,
        value: jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  Future<void> removeFromHistory(String id) async {
    final history = await getHistory();
    history.removeWhere((f) => f.id == id);
    await _storage.write(
        key: _historyKey,
        value: jsonEncode(history.map((e) => e.toJson()).toList()));
  }

  Future<void> updateFileName(String id, String newName) async {
    final history = await getHistory();
    final idx = history.indexWhere((f) => f.id == id);
    if (idx == -1) return;
    history[idx] = history[idx].copyWith(fileName: newName);
    await _storage.write(
        key: _historyKey,
        value: jsonEncode(history.map((e) => e.toJson()).toList()));
  }

  Future<void> clearHistory() async {
    await _storage.delete(key: _historyKey);
  }
}
