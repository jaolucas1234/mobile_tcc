import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _userIdKey = 'user_id';
  static const String _userTokenKey = 'user_token';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';

  Future<void> saveUserData(
    String userId,
    String token,
    String email,
    String name,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userTokenKey, token);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userNameKey, name);
    print('💾 Dados salvos: UserID: $userId, Email: $email');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTokenKey);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    final token = prefs.getString(_userTokenKey);
    return userId != null &&
        token != null &&
        userId.isNotEmpty &&
        token.isNotEmpty;
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userTokenKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    print('🗑️ Dados do usuário removidos');
  }
}
