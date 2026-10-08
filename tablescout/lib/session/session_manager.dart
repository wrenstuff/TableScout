import 'package:flutter/foundation.dart';

class SessionManager extends ChangeNotifier {
  //Whether or not user is logged in
  bool _isLoggedIn = false;

  //Info related to currently logged-in user
  int? _userId;
  String? _email;
  String? _username;
  String? _role;

  //Getters
  bool get isLoggedIn => _isLoggedIn;
  int? get userid => _userId;
  String? get email => _email;
  String? get username => _username;
  String? get role => _role;

  //Called after AutherService successfully auth user
  void setSession({
    required int userId,
    required String email,
    required String username,
    required String role,
  }) {
    _userId = userId;
    _email = email;
    _username = username;
    _role = role;

    _isLoggedIn = true;

    //Notify that session has changed
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;

    _userId =null;
    _email = null;
    _username = null;
    _role = null;

    notifyListeners();
  }
}