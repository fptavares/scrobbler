import 'package:flutter_driver/flutter_driver.dart';
import 'package:screenshots/screenshots.dart';
import 'package:test/test.dart';

void main() {
  group('App', () {
    FlutterDriver driver;
    final config = Config();

    setUpAll(() async {
      // Connect to a running Flutter application instance.
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null) {
        await driver.close();
      }
    });

    test('renders home page', () async {
      // wait for the albums to load
      await driver.waitFor(find.byType('AlbumButton'));

      // take screenshot of home page
      await screenshot(driver, config, 'home-1');

      // tap albums to add to playlist
      await driver.tap(find.byValueKey(428475133));
      await driver.tap(find.byValueKey(426569645));
      await driver.tap(find.byValueKey(426569645));

      // wait for playlist indicator to show
      await driver.waitFor(find.byType('PlaylistCountIndicator'));
      await driver.waitFor(find.byTooltip('Scrobble'));

      // take screenshot of home page with playlist item
      await screenshot(driver, config, 'home-2');

      // tap playlist button
      await driver.tap(find.byTooltip('Playlist'));

      // wait for playlist page
      await driver.waitFor(find.text('Playlist'));
      await driver.waitFor(find.byType('ListTile'));

      // take screenshot of playlist page
      await screenshot(driver, config, 'playlist');

      // tap back button
      await driver.tap(find.byTooltip('Back'));

      // wait home and search button
      await driver.waitFor(find.byTooltip('Search'));

      // tap search button
      await driver.tap(find.byTooltip('Search'));

      // wait for search page
      await driver.waitFor(find.byType('TextField'));
      await driver.waitFor(find.byType('ListTile'));

      // take screenshot of search page
      await screenshot(driver, config, 'search-1');

      // enter search query
      await driver.enterText('min');
      await driver.waitFor(find.text('min'));

      // take screenshot of search page
      await screenshot(driver, config, 'search-2');

      // increase timeout from 30 seconds for testing
      // on slow running emulators in cloud
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}