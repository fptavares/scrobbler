import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrobbler/components/album.dart';
import 'package:scrobbler/components/playlist.dart';
import 'package:scrobbler/firebase_options.dart';
import 'package:scrobbler/main.dart';
import 'package:scrobbler/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late final SharedPreferences prefs;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    SharedPreferences.setMockInitialValues({
      Settings.discogsUsernameKey: 'scrobbler_app',
      Settings.skippedKey: false,
      Settings.lastfmUsernameKey: 'someuser',
      Settings.lastfmSessionKeyKey: '',
    });
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('Scrobbler app main use cases work', (tester) async {
    final album1 = find.byTooltip('Graceland by Paul Simon');
    final album1Text = find.text('Paul Simon');
    final album2 = find.byTooltip('Pure Heroine by Lorde');

    // load the App
    await tester.pumpWidget(ScrobblerApp(prefs, 'ScrobblerIntegrationTest'));

    // wait for data to load
    await tester.pumpAndSettle();

    // Check if widgets are displayed
    expect(find.byType(AlbumButton), findsWidgets);

    // take screenshot of home page

    // tap albums to add to playlist
    await tester.tap(album1);
    await tester.pumpAndSettle();
    await tester.tap(album2);
    await tester.pumpAndSettle();
    await tester.tap(album2);
    await tester.pumpAndSettle();

    // check for playlist indicator to show
    expect(find.byType(PlaylistCountIndicator), findsNWidgets(2));
    expect(find.byTooltip('Scrobble'), findsOneWidget);

    // take screenshot of home page with playlist item

    // tap playlist button
    await tester.tap(find.byTooltip('Playlist'));
    await tester.pumpAndSettle();

    // check for playlist page
    expect(find.text('Playlist'), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);

    // take screenshot of playlist page

    // tap back button
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // check for search button
    expect(find.byTooltip('Search'), findsOneWidget);

    // tap search button
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    // check for search page
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);

    // take screenshot of search page

    // enter search query
    await tester.enterText(find.byType(TextField), 'be');
    await tester.pumpAndSettle();

    expect(find.text('be'), findsOneWidget);

    // take screenshot of search page

    // tap back button
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // check for scrobble button
    expect(find.byTooltip('Scrobble'), findsOneWidget);

    // tap scrobble button
    await tester.tap(find.byTooltip('Scrobble'));
    await tester.pumpAndSettle();

    // check for scrobble editor
    expect(find.text('When?'), findsOneWidget);

    // take screenshot of scrobble editor

    // expand list item
    await tester.tap(album1Text);
    await tester.pumpAndSettle();

    // scroll
    await tester.drag(album1Text, const Offset(0, -200));
    await tester.pumpAndSettle();

    // take screenshot of expanded album

    // change time offset slider to middle value (= 60 minutes)
    await tester.tap(find.byType(Slider));
    await tester.pumpAndSettle();

    // check for correct time offset selection
    expect(tester.widget<Slider>(find.byType(Slider)).value, equals(3)); // [0, 15, 30, 60, 120, 240, 300]

    // take screenshot of time selection
  });
}
