import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  UserModel? _currentUser;
  String? _token;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _currentUser != null;

  static const String _keyToken = 'simanet_jwt_token';
  static const String _keyUser = 'simanet_user_data';
  static const String _keyBiometricEnabled = 'simanet_biometric_enabled';

  Future<void> initSession() async {
    try {
      _token = await _storage.read(key: _keyToken);
      final userJson = await _storage.read(key: _keyUser);
      if (_token != null && userJson != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
        ApiService.instance.setAuthToken(_token);
      }
    } catch (e) {
      debugPrint('[AuthService] Init session error: $e');
    }
  }

  Future<bool> login({required String username, required String password}) async {
    final result = await ApiService.instance.login(username: username, password: password);
    if (result['success'] == true && result['token'] != null) {
      _token = result['token'];
      _currentUser = UserModel.fromJson(result['user']);
      ApiService.instance.setAuthToken(_token);

      await _storage.write(key: _keyToken, value: _token);
      await _storage.write(key: _keyUser, value: jsonEncode(_currentUser!.toJson()));
      await _storage.write(key: _keyBiometricEnabled, value: 'true');
      return true;
    }
    return false;
  }

  Future<bool> register({
    required String nama,
    required String email,
    required String noHp,
    required String password,
    required String negara,
    required String alamat,
    required double lat,
    required double lng,
    required int paketId,
  }) async {
    final result = await ApiService.instance.register(
      nama: nama,
      email: email,
      noHp: noHp,
      password: password,
      negara: negara,
      alamat: alamat,
      lat: lat,
      lng: lng,
      paketId: paketId,
    );
    if (result['success'] == true && result['token'] != null) {
      _token = result['token'];
      _currentUser = UserModel.fromJson(result['user']);
      ApiService.instance.setAuthToken(_token);

      await _storage.write(key: _keyToken, value: _token);
      await _storage.write(key: _keyUser, value: jsonEncode(_currentUser!.toJson()));
      return true;
    }
    return false;
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final isBiometricAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isBiometricAvailable && !isDeviceSupported) {
        debugPrint('[AuthService] Biometrics not available on device');
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Gunakan sidik jari atau biometrik untuk membuka Sima.net',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        // Restore session if exists
        await initSession();
        return isLoggedIn;
      }
    } catch (e) {
      debugPrint('[AuthService] Biometric error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    ApiService.instance.setAuthToken(null);
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
  }

  void updateUserProfile(UserModel updated) {
    _currentUser = updated;
    _storage.write(key: _keyUser, value: jsonEncode(updated.toJson()));
  }
}
