import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscogsSettings extends ChangeNotifier {
  DiscogsSettings(this.prefs);

  final SharedPreferences prefs;

  bool get skipped => prefs.getBool(_skippedKey) ?? false;

  String get username => prefs.getString(_discogsUsernameKey);

  set skipped(bool skipped) {
    prefs.setBool(_skippedKey, skipped);
    notifyListeners();
  }

  set username(String newUsername) {
    if (newUsername != username) {
      prefs.setString(_discogsUsernameKey, newUsername);
      notifyListeners();
    }
  }

  static const String _skippedKey = 'skipped';
  static const String _discogsUsernameKey = 'discogsUsername';
}

class LastfmSettings extends ChangeNotifier {
  LastfmSettings(this.prefs);

  final SharedPreferences prefs;

  String get username => prefs.getString(_lastfmUsernameKey);

  String get sessionKey => prefs.getString(_sessionKeyKey);

  /// Setting a new username also clears the current session key,
  /// so a new session key must only be assigned
  /// after assigning the new username.
  set username(String newUsername) {
    if (newUsername != username) {
      prefs.setString(_lastfmUsernameKey, newUsername);
      prefs.remove(_sessionKeyKey);
      notifyListeners();
    }
  }

  set sessionKey(String value) {
    prefs.setString(_sessionKeyKey, value);
    notifyListeners();
  }

  static const String _lastfmUsernameKey = 'lastfmUsername';
  static const String _sessionKeyKey = 'sessionKey';
}
