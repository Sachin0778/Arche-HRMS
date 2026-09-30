import 'package:hive/hive.dart';

/// Holds the demo credential list and the persisted session.
///
/// Credentials are deliberately static: the assignment calls for dummy
/// logins with no backend. In a real build these would never ship in code.
class AuthLocalDataSource {
  AuthLocalDataSource(this._box);

  static const String boxName = 'session';
  static const String _userKey = 'currentUserId';

  static const Map<String, String> demoCredentials = {
    'emp001': 'password123',
    'emp002': 'password123',
    'emp105': 'manager123',
  };

  final Box<String> _box;

  bool verify(String employeeId, String password) =>
      demoCredentials[employeeId.toLowerCase()] == password;

  String? get currentUserId => _box.get(_userKey);

  Future<void> saveSession(String employeeId) => _box.put(_userKey, employeeId);

  Future<void> clearSession() => _box.delete(_userKey);
}