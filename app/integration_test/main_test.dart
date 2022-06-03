import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:flutter_cache_manager/src/web/web_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:scrobbler/components/album.dart';
import 'package:scrobbler/components/playlist.dart';
import 'package:scrobbler/firebase_options.dart';
import 'package:scrobbler/main.dart';
import 'package:scrobbler/model/discogs.dart';
import 'package:scrobbler/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_collection.dart';

void main() {
  late final SharedPreferences prefs;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    WidgetsApp.debugAllowBannerOverride = false; // remove debug banner

    SharedPreferences.setMockInitialValues({
      Settings.discogsUsernameKey: 'someuser',
      Settings.skippedKey: false,
      Settings.lastfmUsernameKey: 'someuser',
      Settings.lastfmSessionKeyKey: '',
    });
    prefs = await SharedPreferences.getInstance();

    final config = Config('testCache');
    Collection.cache = CacheManager.custom(config,
        webHelper: WebHelper(CacheStore(config), HttpFileService(httpClient: StaticCollectionHttpClient())));
    await Collection.cache.emptyCache();

    if (Platform.isIOS) {
      // Even though the images used are not eligible for copyright,
      // and thus considered public domain,
      // the iOS app store doesn't approve their use in app screenshots.
      // So on iOS this will hide them and overlay the explanation text.
      AlbumImage.imageBuilder = (image) => AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image(image: image),
                Center(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10.0,
                        sigmaY: 10.0,
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        width: 150.0,
                        height: 150.0,
                        padding: const EdgeInsets.all(5.0),
                        child: const FittedBox(
                          fit: BoxFit.fitWidth,
                          child: Text(
                            'Image hidden\ndue to\ncopyright',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
    }
  });

  testWidgets('Scrobbler app main use cases work', (tester) async {
    final album1 = find.byKey(const ValueKey<int>(454789538));
    final album1Text = find.text('Paul Simon');
    final album2 = find.byKey(const ValueKey<int>(454789997));

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

class StaticCollectionHttpClient extends BaseClient {
  StaticCollectionHttpClient();

  final _client = Client();

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    if (request.url.path.contains('/collection/folders/0/releases')) {
      return StreamedResponse(
        Stream<List<int>>.fromIterable(<List<int>>[fakeCollectionData.codeUnits]),
        200,
      );
    } else {
      return await _client.send(request);
    }
  }
}
