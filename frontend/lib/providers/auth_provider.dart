import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _loginErrorMessage;
  String? _registerErrorMessage;
  String? _profileErrorMessage;
  String? _passwordErrorMessage;

  bool get isLoading => _isLoading;
  String? get loginErrorMessage => _loginErrorMessage;
  String? get registerErrorMessage => _registerErrorMessage;
  String? get profileErrorMessage => _profileErrorMessage;
  String? get passwordErrorMessage => _passwordErrorMessage;
  bool get isAuthenticated => _authService.isAuthenticated;
  User? get currentUser => _authService.currentUser;
  String? get token => _authService.accessToken;
  String? get accessToken => _authService.accessToken;
  bool get mustChangePassword => _authService.mustChangePassword;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _authService.init();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setLoginErrorMessage(null);
    
    final result = await _authService.login(
      email: email,
      password: password,
    );
    
    if (result.success && result.data != null) {
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setLoginErrorMessage(result.message ?? 'Login failed');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    int? preferredParishId,
  }) async {
    _setLoading(true);
    _setRegisterErrorMessage(null);

    final result = await _authService.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      preferredParishId: preferredParishId,
    );

    if (result.success && result.data != null) {
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setRegisterErrorMessage(result.message ?? 'Registration failed');
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _setLoginErrorMessage(null);
    
    final result = await _authService.signInWithGoogle();
    
    if (result.success && result.data != null) {
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setLoginErrorMessage(result.message ?? 'Google sign-in failed');
      notifyListeners();
      return false;
    }
  }

  //fix this part of the code to manually erase the
  // user's data before we refresh the screen
  Future<void> logout() async {
    //1. Tell the server we are logging out
    await _authService.logout();

    //2. Erase local data
    //added this to kill the zombie state
    _isLoading = false;
    _loginErrorMessage = null;
    _registerErrorMessage = null;
    _profileErrorMessage = null;
    _passwordErrorMessage = null;

    //3. Notify the app to rebuild UI
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    _setLoading(true);
    _setProfileErrorMessage(null);
    
    final result = await _authService.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      address: address,
    );
    
    if (result.success) {
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setProfileErrorMessage(result.message ?? 'Failed to update profile');
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _setPasswordErrorMessage(null);
    
    final result = await _authService.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    
    if (result.success) {
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setPasswordErrorMessage(result.message ?? 'Failed to change password');
      notifyListeners();
      return false;
    }
  }

  // Force password change on first login
  Future<bool> forcePasswordChange({
    required String newPassword,
  }) async {
    _setLoading(true);
    _setPasswordErrorMessage(null);
    
    final result = await _authService.forcePasswordChange(
      newPassword: newPassword,
    );
    
    if (result.success) {
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setLoading(false);
      _setPasswordErrorMessage(result.message ?? 'Failed to change password');
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoginErrorMessage(String? message) {
    _loginErrorMessage = message;
    notifyListeners();
  }

  void _setRegisterErrorMessage(String? message) {
    _registerErrorMessage = message;
    notifyListeners();
  }


  void _setProfileErrorMessage(String? message) {
    _profileErrorMessage = message;
    notifyListeners();
  }

  void _setPasswordErrorMessage(String? message) {
    _passwordErrorMessage = message;
    notifyListeners();
  }

  Future<void> clearLoginErrorMessage() async {
    _setLoginErrorMessage(null);
    notifyListeners();
  }

  Future<void> clearRegisterErrorMessage() async {
    _setRegisterErrorMessage(null);
    notifyListeners();
  }

  Future<void> clearProfileErrorMessage() async {
    _setProfileErrorMessage(null);
    notifyListeners();
  }

  Future<void> clearPasswordErrorMessage() async {
    _setPasswordErrorMessage(null);
    notifyListeners();
  }
}