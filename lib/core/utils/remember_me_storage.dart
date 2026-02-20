import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists "Remember me" email and checkbox state for the login screen.
/// Catches [PlatformException] / [MissingPluginException] so the app does not crash
/// when SharedPreferences is unavailable (e.g. before native init, or in tests).
abstract final class RememberMeStorage {
  static const String _keyRememberMe = 'remember_me';
  static const String _keyRememberMeEmail = 'remember_me_email';

  /// Returns whether "Remember me" was last checked.
  static Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyRememberMe) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Returns the last saved email when "Remember me" was checked, or null.
  static Future<String?> getRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRememberMeEmail);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Saves "Remember me" state and email. Call after successful login when checkbox is checked.
  static Future<void> saveRememberMe({required bool remember, String? email}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRememberMe, remember);
      if (remember && email != null && email.trim().isNotEmpty) {
        await prefs.setString(_keyRememberMeEmail, email.trim());
      } else {
        await prefs.remove(_keyRememberMeEmail);
      }
    } on PlatformException {
      // Plugin unavailable (e.g. channel-error); no-op
    } on MissingPluginException {
      // Plugin unavailable; no-op
    } catch (_) {
      // Any other exception; no-op so login still succeeds
    }
  }

  /// Clears saved remember-me data (e.g. when user unchecks).
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRememberMe);
      await prefs.remove(_keyRememberMeEmail);
    } on PlatformException {
      // Plugin unavailable; no-op
    } on MissingPluginException {
      // Plugin unavailable; no-op
    } catch (_) {
      // Any other exception; no-op
    }
  }
}
