// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:scrobbler/main.dart';
import 'package:scrobbler/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  // This line enables the extension.
  enableFlutterDriverExtension();

  WidgetsApp.debugAllowBannerOverride = false; // remove debug banner

  SharedPreferences.setMockInitialValues({
    DiscogsSettings.discogsUsernameKey: 'ftavares',
    DiscogsSettings.skippedKey: null,
    LastfmSettings.lastfmUsernameKey: 'someuser',
    LastfmSettings.sessionKeyKey: '',
  });
  final prefs = await SharedPreferences.getInstance();

  runApp(MyApp(prefs, 'ScrobblerDriverTest'));
}