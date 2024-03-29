import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bluos.dart';

class Settings extends ChangeNotifier {
  Settings(this.prefs);

  final SharedPreferences prefs;

  bool get isSkipped => prefs.getBool(skippedKey) ?? false;

  String? get discogsUsername => prefs.getString(discogsUsernameKey);

  String? get lastfmUsername => prefs.getString(lastfmUsernameKey);

  String? get lastfmSessionKey => prefs.getString(lastfmSessionKeyKey);

  bool get isBluOSEnabled => prefs.getBool(bluOSEnabledKey) ?? false;

  String? get bluOSMonitorAddress => prefs.getString(bluOSMonitorAddressKey);

  bool get isBluOSWarningShown => prefs.getBool(bluOSWarningShownKey) ?? false;

  BluOSPlayer? get bluOSPlayer {
    final host = prefs.getString(bluOSHostKey);
    final port = prefs.getInt(bluOSPortKey);
    final name = prefs.getString(bluOSNameKey);
    if (host == null || port == null || name == null) {
      return null;
    }
    return BluOSPlayer(name, host, port);
  }

  set isSkipped(bool skipped) {
    prefs.setBool(skippedKey, skipped);
    notifyListeners();
  }

  set discogsUsername(String? newUsername) {
    if (newUsername != discogsUsername) {
      _setOrRemoveString(discogsUsernameKey, newUsername);
      notifyListeners();
    }
  }

  /// Setting a new username also clears the current session key,
  /// so a new session key must only be assigned
  /// after assigning the new username.
  set lastfmUsername(String? newUsername) {
    if (newUsername != lastfmUsername) {
      _setOrRemoveString(lastfmUsernameKey, newUsername);
      prefs.remove(lastfmSessionKeyKey);
      notifyListeners();
    }
  }

  set lastfmSessionKey(String? value) {
    _setOrRemoveString(lastfmSessionKeyKey, value);
    notifyListeners();
  }

  set isBluOSEnabled(bool value) {
    prefs.setBool(bluOSEnabledKey, value);
    notifyListeners();
  }

  set bluOSMonitorAddress(String? value) {
    _setOrRemoveString(bluOSMonitorAddressKey, value);
    notifyListeners();
  }

  set bluOSPlayer(BluOSPlayer? player) {
    if (player == null) {
      return;
    }
    prefs.setString(bluOSHostKey, player.host);
    prefs.setInt(bluOSPortKey, player.port);
    prefs.setString(bluOSNameKey, player.name);
    notifyListeners();
  }

  set isBluOSWarningShown(bool value) {
    prefs.setBool(bluOSWarningShownKey, value);
    notifyListeners();
  }

  Future<bool> _setOrRemoveString(String key, String? value) async {
    if (value == null) {
      return await prefs.remove(key);
    } else {
      return await prefs.setString(key, value);
    }
  }

  @visibleForTesting
  static const String skippedKey = 'skipped';
  @visibleForTesting
  static const String discogsUsernameKey = 'discogsUsername';
  @visibleForTesting
  static const String lastfmUsernameKey = 'lastfmUsername';
  @visibleForTesting
  static const String lastfmSessionKeyKey = 'lastfmSessionKey';
  @visibleForTesting
  static const String bluOSEnabledKey = 'bluOSEnabled';
  @visibleForTesting
  static const String bluOSMonitorAddressKey = 'bluOSMonitorAddress';
  @visibleForTesting
  static const String bluOSHostKey = 'bluOSHost';
  @visibleForTesting
  static const String bluOSPortKey = 'bluOSPort';
  @visibleForTesting
  static const String bluOSNameKey = 'bluOSName';
  @visibleForTesting
  static const String bluOSWarningShownKey = 'bluOSWarningShown';
}
