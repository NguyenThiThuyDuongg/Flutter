import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  StreamSubscription? _authSub;
  User? user;
  UserModel? userModel;
  bool isLoading = true;
  String? errorMessage;

  String? get role => userModel?.role;

  AuthViewModel() {
    _authSub = _authService.authStateChanges.listen((firebaseUser) async {
      user = firebaseUser;
      if (firebaseUser != null) {
        // Dùng ??= thay if-null (fix prefer_conditional_assignment)
        userModel = await _authService.getUserData(firebaseUser.uid);
      } else {
        userModel = null;
      }
      isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel(); // fix: cancel subscription để tránh memory leak
    super.dispose();
  }

  Future<bool> login(String email, String password) async {
    try {
      errorMessage = null;
      isLoading = true;
      notifyListeners();
      userModel = await _authService.login(email: email, password: password);
      user = _authService.currentUser;
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _mapError(e.code);
      return false;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(
    String email,
    String password,
    String fullName,
    String role,
  ) async {
    try {
      errorMessage = null;
      isLoading = true;
      notifyListeners();
      userModel = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      user = _authService.currentUser;
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _mapError(e.code);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    userModel = null;
    user = null;
    notifyListeners();
  }

  Future<bool> loginWithGoogle() async {
    try {
      errorMessage = null;
      isLoading = true;
      notifyListeners();

      userModel = await _authService.signInWithGoogle();

      if (userModel == null) {
        errorMessage = 'Đăng nhập đã bị hủy';
        return false;
      }

      user = _authService.currentUser;

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');

      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'wrong-password':
        return 'Sai mật khẩu';
      case 'user-not-found':
        return 'Tài khoản không tồn tại';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      default:
        return 'Đã có lỗi xảy ra ($code)';
    }
  }
}
