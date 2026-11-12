import 'package:shared_preferences/shared_preferences.dart';

class PantryStorage {
  static const _storageKey = 'home_pantry.data.v1';

  Future<String?> read() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_storageKey);
  }

  Future<void> write(String value) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_storageKey, value);
    if (!saved) {
      throw StateError('Не вдалося зберегти дані комори на пристрої.');
    }
  }
}
