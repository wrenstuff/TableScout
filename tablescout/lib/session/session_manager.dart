import 'package:flutter/foundation.dart';
import 'package:tablescout/services/auth_service.dart';

class SessionManager extends ChangeNotifier {
  //Whether or not user is logged in
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isUpdatingAccount = false;

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
  bool get isUpdatingAccount => _isUpdatingAccount;
  int? get userid => _userId;
  String? get email => _email;
  String? get username => _username;
  String? get role => _role;
  String? get accountStatus => _accountStatus;
  int? get storeId => _storeId;
  String? get storeName => _storeName;
  String? get lastError => _lastError;

  bool get isAdmin => isLoggedIn && _role?.toUpperCase() == 'ADMIN';
  bool get isManager => isLoggedIn && _role?.toUpperCase() == 'MANAGER';
  bool get isUser => isLoggedIn && _role?.toUpperCase() == 'STAFF';

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

  Future<bool> updateAccount({
    required String username,
    required String email,
    required String phoneNumber,
  }) async {
    // Make sure there is an active login session.
    if (!_isLoggedIn || _userId == null) {
      _lastError = 'You must be logged in to update your account.';
      return false;
    }

    // Prevent loverlapping account updates.
    if (_isUpdatingAccount) return false;

    _isUpdatingAccount = true;
    _lastError = null;
    notifyListeners();

    try {
      final data = await AuthService.updateAccount(
        userId: _userId!,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
      );

      final user = data['user'];

      //checking that the backend returned the expected details.
      if (user is! Map ||
          user['id'] != _userId ||
          user['username'] is! String  ||
          user['email'] is! String  ||
          user['phoneNumber'] is! String) {
        _lastError =
          'The server returned incomplete account details.';
        return false;
      }

      //Update the local session only after the backend succeeds.
      _username = (user['username'] as String).trim();
      _email = (user['email'] as String).trim();

      return true;
    } catch (error) {
      //Show a userful error without changing the login session.
      _lastError = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isUpdatingAccount = false;
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