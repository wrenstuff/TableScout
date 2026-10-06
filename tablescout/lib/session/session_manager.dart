import 'package:flutter/foundation.dart';

class SessionManager extends ChangeNotifier {
  bool _isLoggedIn = false;

  String? _username;
  String? _role;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get role => _role;

  Future<bool> login(String username, String password) async {
    // Authentication connection here
    return false;
  }

  void logout() {
    _isLoggedIn = false;
    _username = null;
    _role = null;

    notifyListeners();
  }
}