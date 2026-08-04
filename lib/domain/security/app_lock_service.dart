import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages local PIN passcode and app vault security lock settings.
class AppLockService extends ChangeNotifier {
  static const String keyEnabled = 'edgetal_app_lock_enabled';
  static const String keyPin = 'edgetal_app_lock_pin';

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  bool get isAppLockEnabled => _prefs?.getBool(keyEnabled) ?? false;
  String get passcodePin => _prefs?.getString(keyPin) ?? '';

  Future<void> setPasscode(String pin) async {
    await initialize();
    await _prefs?.setString(keyPin, pin);
    await _prefs?.setBool(keyEnabled, true);
    notifyListeners();
  }

  Future<void> disableAppLock() async {
    await initialize();
    await _prefs?.setBool(keyEnabled, false);
    await _prefs?.remove(keyPin);
    notifyListeners();
  }

  bool verifyPin(String inputPin) {
    return passcodePin.isNotEmpty && passcodePin == inputPin;
  }
}
