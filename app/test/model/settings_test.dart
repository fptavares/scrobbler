import 'package:flutter_test/flutter_test.dart';
import 'package:scrobbler/model/bluos.dart';
import 'package:scrobbler/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  group('Settings', () {
    test('loads data from empty local storage', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();

      final settings = Settings(prefs);
      expect(settings.discogsUsername, isNull);
      expect(settings.isSkipped, isFalse);
      expect(settings.lastfmUsername, isNull);
      expect(settings.lastfmSessionKey, isNull);
      expect(settings.isBluOSEnabled, isFalse);
      expect(settings.bluOSPlayer, isNull);
      expect(settings.bluOSMonitorAddress, isNull);
      expect(settings.isBluOSWarningShown, isFalse);
    });

    test('saves data', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();

      final settings = Settings(prefs);

      expect(settings.discogsUsername, isNull);
      settings.discogsUsername = 'test-user';
      expect(settings.discogsUsername, equals('test-user'));

      expect(settings.isSkipped, isFalse);
      settings.isSkipped = true;
      expect(settings.isSkipped, isTrue);

      expect(settings.lastfmUsername, isNull);
      settings.lastfmUsername = 'test-user';
      expect(settings.lastfmUsername, 'test-user');

      expect(settings.lastfmSessionKey, isNull);
      settings.lastfmSessionKey = 'test';
      expect(settings.lastfmSessionKey, 'test');

      expect(settings.isBluOSEnabled, isFalse);
      settings.isBluOSEnabled = true;
      expect(settings.isBluOSEnabled, isTrue);

      expect(settings.bluOSPlayer, isNull);
      settings.bluOSPlayer = const BluOSPlayer('Test player', 'test', 1234);
      expect(settings.bluOSPlayer!.name, equals('Test player'));
      expect(settings.bluOSPlayer!.host, equals('test'));
      expect(settings.bluOSPlayer!.port, equals(1234));

      expect(settings.bluOSMonitorAddress, isNull);
      settings.bluOSMonitorAddress = 'monitor:9876';
      expect(settings.bluOSMonitorAddress, equals('monitor:9876'));

      expect(settings.isBluOSWarningShown, isFalse);
      settings.isBluOSWarningShown = true;
      expect(settings.isBluOSWarningShown, isTrue);
    });

    test('loads data from local storage', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        Settings.discogsUsernameKey: 'test-user',
        Settings.skippedKey: true,
        Settings.lastfmUsernameKey: 'test-user',
        Settings.lastfmSessionKeyKey: 'test',
        Settings.bluOSEnabledKey: true,
        Settings.bluOSHostKey: 'test',
        Settings.bluOSPortKey: 1234,
        Settings.bluOSNameKey: 'Test player',
        Settings.bluOSMonitorAddressKey: 'monitor:9876',
        Settings.bluOSWarningShownKey: true,
      });
      final prefs = await SharedPreferences.getInstance();

      final settings = Settings(prefs);
      expect(settings.discogsUsername, equals('test-user'));
      expect(settings.isSkipped, isTrue);
      expect(settings.lastfmUsername, 'test-user');
      expect(settings.lastfmSessionKey, 'test');
      expect(settings.isBluOSEnabled, isTrue);
      expect(settings.bluOSPlayer!.name, equals('Test player'));
      expect(settings.bluOSPlayer!.host, equals('test'));
      expect(settings.bluOSPlayer!.port, equals(1234));
      expect(settings.bluOSMonitorAddress, equals('monitor:9876'));
      expect(settings.isBluOSWarningShown, isTrue);
    });
  });
}
