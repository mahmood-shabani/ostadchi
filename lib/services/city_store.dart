import 'package:shared_preferences/shared_preferences.dart';

class CityStore {
  static const _key = 'selected_city';

  Future<String> getSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'آبادان';
  }

  Future<void> saveSelectedCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, city);
  }
}
