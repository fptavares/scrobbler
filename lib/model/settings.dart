import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscogsSettings with ChangeNotifier {
  final SharedPreferences prefs;

  String get username => prefs.getString(_discogsUsernameKey);

  DiscogsSettings(this.prefs);

  set username (value) {
    prefs.setString(_discogsUsernameKey, value);
    notifyListeners();
  }

  static const String _discogsUsernameKey = 'discogsUsername';
}

class LastfmSettings with ChangeNotifier {
  final SharedPreferences prefs;

  String get username => prefs.getString(_lastfmUsernameKey);
  String get sessionKey => prefs.getString(_sessionKeyKey);

  LastfmSettings(this.prefs);

  set username (value) {
    prefs.setString(_lastfmUsernameKey, value);
    notifyListeners();
  }

  set sessionKey (value) {
    prefs.setString(_sessionKeyKey, value);
    notifyListeners();
  }

  static const String _lastfmUsernameKey = 'lastfmUsername';
  static const String _sessionKeyKey = 'sessionKey';
}
