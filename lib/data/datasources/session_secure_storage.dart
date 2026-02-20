import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/my_user.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/user.dart';
import '../../domain/storage/session_storage.dart';

const String _keyToken = 'session_token';
const String _keyRefreshToken = 'session_refresh_token';
const String _keyUserId = 'session_user_id';
const String _keyUserJson = 'session_user_json';

/// Persists [Session] using platform secure storage (Keychain / KeyStore).
/// If the plugin is unavailable (e.g. web, or before native registration),
/// operations no-op / return null so the app does not crash.
class SessionSecureStorage implements SessionStorage {
  SessionSecureStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  @override
  Future<Session?> getSession() async {
    try {
      final token = await _storage.read(key: _keyToken);
      final refreshToken = await _storage.read(key: _keyRefreshToken);
      final userId = await _storage.read(key: _keyUserId);
      final userJsonStr = await _storage.read(key: _keyUserJson);
      if (token == null || token.isEmpty) return null;

      User? user;
      if (userJsonStr != null && userJsonStr.isNotEmpty) {
        try {
          final userMap = json.decode(userJsonStr) as Map<String, dynamic>?;
          user = User.fromJson(userMap);
        } catch (_) {
          // ignore invalid stored user json
        }
      }

      return Session(
        token: token,
        refreshToken: (refreshToken == null || refreshToken.isEmpty) ? null : refreshToken,
        user: user,
        userId: userId ?? user?.id ?? '',
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> saveSession(Session session) async {
    try {
      await _storage.write(key: _keyToken, value: session.token);
      await _storage.write(key: _keyUserId, value: session.userId);
      if (session.refreshToken != null && session.refreshToken!.isNotEmpty) {
        await _storage.write(key: _keyRefreshToken, value: session.refreshToken);
      } else {
        await _storage.delete(key: _keyRefreshToken);
      }
      if (session.user != null) {
        await _storage.write(key: _keyUserJson, value: json.encode(session.user!.toJson()));
      } else {
        await _storage.delete(key: _keyUserJson);
      }
    } on MissingPluginException {
      // No-op when plugin not available (e.g. web).
    } on PlatformException {
      // No-op on platform errors.
    }
  }

  @override
  Future<void> saveUserAndToken(MyUser user) async {
    try {
      await _storage.write(key: _keyToken, value: user.token);
      await _storage.write(key: _keyUserId, value: user.id);
      if (user.refreshToken != null && user.refreshToken!.isNotEmpty) {
        await _storage.write(key: _keyRefreshToken, value: user.refreshToken);
      } else {
        await _storage.delete(key: _keyRefreshToken);
      }
      await _storage.write(key: _keyUserJson, value: json.encode(user.toJson()));
    } on MissingPluginException {
      // No-op when plugin not available.
    } on PlatformException {
      // No-op on platform errors.
    }
  }

  @override
  Future<MyUser?> getStoredUser() async {
    try {
      final token = await _storage.read(key: _keyToken);
      final refreshToken = await _storage.read(key: _keyRefreshToken);
      final userJsonStr = await _storage.read(key: _keyUserJson);
      if (token == null || token.isEmpty) return null;
      if (userJsonStr == null || userJsonStr.isEmpty) {
        return MyUser(
          id: await _storage.read(key: _keyUserId) ?? '',
          name: '',
          email: '',
          token: token,
          refreshToken: (refreshToken == null || refreshToken.isEmpty) ? null : refreshToken,
        );
      }
      final userMap = json.decode(userJsonStr) as Map<String, dynamic>?;
      if (userMap == null) return null;
      userMap['token'] = token;
      if (refreshToken != null && refreshToken.isNotEmpty) userMap['refreshToken'] = refreshToken;
      return MyUser.fromJson(userMap);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyUserJson);
    } on MissingPluginException {
      // No-op when plugin not available.
    } on PlatformException {
      // No-op on platform errors.
    }
  }
}
