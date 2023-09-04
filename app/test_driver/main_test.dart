import 'package:emulators/emulators.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

Future<void> main() async {
  // Connect to flutter driver
  final driver = await FlutterDriver.connect();

  // Setup emulators package
  final emu = await Emulators.build();
  final screenshotHelper = emu.screenshotHelper(
    androidPath: Environment.getString('androidPath') ?? '',
    iosPath: Environment.getString('iosPath') ?? '',
  );

  setUpAll(() async {
    await driver.waitUntilFirstFrameRasterized();

    // Clean up the status bar for the device
    await screenshotHelper.cleanStatusBar();
  });

  // Close the connection to the driver after the tests have completed.
  tearDownAll(() async {
    await driver.close();
  });

  Future<void> screenshot(final String name) async {
    await screenshotHelper.capture(name);
  }

  group('App', () {
    test('renders home page', () async {
      final album1 = find.byValueKey(454789538);
      final album1Text = find.text('Paul Simon');
      final album2 = find.byValueKey(454789997);

      // wait for the albums to load
      await driver.waitFor(find.byType('AlbumButton'));

      // take screenshot of home page
      await screenshot('1.1-collection');

      // tap albums to add to playlist
      await driver.tap(album1);
      await driver.tap(album2);
      await driver.tap(album2);

      // wait for playlist indicator to show
      await driver.waitFor(find.byType('PlaylistCountIndicator'));
      await driver.waitFor(find.byTooltip('Scrobble'));

      // take screenshot of home page with playlist item
      await screenshot('1.2-selection');

      // tap playlist button
      await driver.tap(find.byTooltip('Playlist'));

      // wait for playlist page
      await driver.waitFor(find.text('Playlist'));
      await driver.waitFor(find.byType('ListTile'));

      // take screenshot of playlist page
      await screenshot('2-playlist');

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
      await screenshot('3.1-search');

      // enter search query
      await driver.enterText('be');
      await driver.waitFor(find.text('be'));

      // take screenshot of search page
      await screenshot('3.2-search');

      // tap back button
      await driver.tap(find.byTooltip('Back'));

      // wait home and search button
      await driver.waitFor(find.byTooltip('Scrobble'));

      // tap scrobble button
      await driver.tap(find.byTooltip('Scrobble'));

      // wait for scrobble editor
      await driver.waitFor(find.text('When?'));

      // take screenshot of scrobble editor
      await screenshot('4.1-scrobble');

      // expand list item
      await driver.tap(album1Text);

      // wait for scrobble editor
      await driver.scroll(album1Text, 0, -200, const Duration(milliseconds: 200));

      // take screenshot of expanded album
      await screenshot('4.2-finetune');

      // set slider to middle value
      final scrolling = driver.scroll(find.byType('Slider'), 0, 0, const Duration(seconds: 2));

      // take screenshot of time selection
      await screenshot('4.3-time');

      await scrolling;

      // increase timeout from 30 seconds for testing
      // on slow running emulators in cloud
    }, timeout: const Timeout(Duration(seconds: 120)));
  });
}
