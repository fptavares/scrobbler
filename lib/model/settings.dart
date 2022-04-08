import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscogsSettings extends ChangeNotifier {
  DiscogsSettings(this.prefs);

  final SharedPreferences prefs;

  bool get skipped => prefs.getBool(skippedKey) ?? false;

  String? get username => prefs.getString(discogsUsernameKey);

  set skipped(bool skipped) {
    prefs.setBool(skippedKey, skipped);
    notifyListeners();
  }

  set username(String? newUsername) {
    if (newUsername != username) {
      prefs.setString(discogsUsernameKey, newUsername!);
      notifyListeners();
    }
  }

  @visibleForTesting
  static const String skippedKey = 'skipped';
  @visibleForTesting
  static const String discogsUsernameKey = 'discogsUsername';
}

class LastfmSettings extends ChangeNotifier {
  LastfmSettings(this.prefs);

  final SharedPreferences prefs;

  String? get username => prefs.getString(lastfmUsernameKey);

  String? get sessionKey => prefs.getString(sessionKeyKey);

  /// Setting a new username also clears the current session key,
  /// so a new session key must only be assigned
  /// after assigning the new username.
  set username(String? newUsername) {
    if (newUsername != username) {
      prefs.setString(lastfmUsernameKey, newUsername!);
      prefs.remove(sessionKeyKey);
      notifyListeners();
    }
  }

  set sessionKey(String? value) {
    if (value == null) {
      prefs.remove(sessionKeyKey);
    } else {
      prefs.setString(sessionKeyKey, value);
    }
    notifyListeners();
  }

  @visibleForTesting
  static const String lastfmUsernameKey = 'lastfmUsername';
  @visibleForTesting
  static const String sessionKeyKey = 'lastfmSessionKey';
}
