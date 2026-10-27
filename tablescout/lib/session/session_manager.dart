import 'package:flutter/foundation.dart';
import 'package:tablescout/services/auth_service.dart';

class SessionManager extends ChangeNotifier {
  //Whether or not user is logged in
  bool _isLoggedIn = false;
  bool _isLoading = false;

  //Info related to currently logged-in user
  int? _userId;
  String? _email;
  String? _username;
  String? _role;
  String? _accountStatus;
  int? _storeId;
  String? _storeName;
  String? _lastError;

  //Getters
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  int? get userid => _userId;
  String? get email => _email;
  String? get username => _username;
  String? get role => _role;
  String? get accountStatus => _accountStatus;
  int? get storeId => _storeId;
  String? get storeName => _storeName;
  String? get lastError => _lastError;

  //Authenticate through the backend and create a session
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    //Preventing overlapping attempts or replacing an active session
    if (_isLoading || _isLoggedIn) return false;

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final data = await AuthService.login(
        email: email.trim(),
        password: password,
      );

      final user = data['user'];

      if (user is! Map ||
          user['id'] is! int||
          (user['id'] as int) <= 0 ||
          user['email'] is! String ||
          (user['email'] as String).trim().isEmpty ||
          user['username'] is! String ||
          (user['username'] as String).trim().isEmpty ||
          user['role'] is! String ||  
          (user['role'] as String).trim().isEmpty)  {
        _lastError = 'The server returned incomplete user details.';
        return false;
      }

      //Only create the session after the backend confirms login.
      _userId = user['id'] as int;
      _email = (user['email'] as String).trim();
      _username = (user['username'] as String).trim();
      _role = (user['role'] as String).trim();
      _accountStatus = user['accountStatus'] as String;
      _storeId = user['storeId'] as int?;
      _storeName = user['storeName'] as String?;
      _isLoggedIn = true;

      return true;
    } catch (_) {
      // Avoiding exposing raw internal exceptions to the interface.
      _lastError = 
        'Unable to sign in. Check your details and try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  void logout() {
    _isLoggedIn = false;
    _userId =null;
    _email = null;
    _username = null;
    _role = null;
    _accountStatus = null;
    _storeId = null;
    _storeName = null;
    _lastError = null;

    notifyListeners();
  }
}