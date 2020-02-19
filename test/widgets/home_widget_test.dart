import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:scrobbler/components/accounts.dart';
import 'package:scrobbler/components/album.dart';
import 'package:scrobbler/components/home.dart';
import 'package:scrobbler/model/discogs.dart';
import 'package:scrobbler/model/playlist.dart';
import 'package:scrobbler/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_albums.dart';

Future<void> main() async {
  SharedPreferences.setMockInitialValues(<String, dynamic>{
    DiscogsSettings.discogsUsernameKey: 'test-user',
    DiscogsSettings.skippedKey: null,
    LastfmSettings.lastfmUsernameKey: 'test-user',
    LastfmSettings.sessionKeyKey: 'test',
  });
  final prefs = await SharedPreferences.getInstance();

  group('Home page', () {
    MockCollection collection;
    Playlist playlist;

    Widget createHome() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<DiscogsSettings>(
            create: (_) => DiscogsSettings(prefs),
          ),
          ChangeNotifierProvider<LastfmSettings>(
            create: (_) => LastfmSettings(prefs),
          ),
          ChangeNotifierProvider<Collection>.value(value: collection),
          ChangeNotifierProvider<Playlist>.value(value: playlist),
        ],
        child: MaterialApp(
          home: Scaffold(body: HomePage()),
          routes: <String, WidgetBuilder>{
            '/playlist': (_) => Container(
                  child: const Text('Playlist test'),
                ),
          },
        ),
      );
    }

    setUp(() {
      playlist = Playlist();
      collection = MockCollection();

      // mock album list
      when(collection.albums).thenReturn([testAlbum1, testAlbum2]);
      when(collection.isUserEmpty).thenReturn(false);
      when(collection.isEmpty).thenReturn(false);
      when(collection.isNotEmpty).thenReturn(true);
      when(collection.isNotFullyLoaded).thenReturn(true);
      when(collection.isNotLoading).thenReturn(true);
      when(collection.isLoading).thenReturn(false);
    });

    testWidgets('renders properly', (tester) async {
      await tester.pumpWidget(createHome());

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('Record Scrobbler'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.playlist_play), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byType(AlbumButton), findsNWidgets(2));

      verify(collection.albums);
    });

    testWidgets('opens drawer on menu button tap', (tester) async {
      await tester.pumpWidget(createHome());

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump();

      expect(find.text('Account Settings'), findsOneWidget);
      expect(find.byType(AccountsForm), findsOneWidget);
    });

    testWidgets('playlist button is disabled when playlist is empty',
        (tester) async {
      playlist.clearAlbums();

      await tester.pumpWidget(createHome());

      expect(
          tester
              .widget<IconButton>(find.ancestor(
                  of: find.byIcon(Icons.playlist_play),
                  matching: find.byType(IconButton)))
              .onPressed,
          isNull);

      await tester.tap(find.byIcon(Icons.playlist_play));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('Playlist test'), findsNothing);
    });

    testWidgets('opens playlist on playlist button tap', (tester) async {
      playlist.addAlbum(testAlbum1);

      await tester.pumpWidget(createHome());

      await tester.tap(find.byIcon(Icons.playlist_play));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('Playlist test'), findsOneWidget);
    });

    testWidgets('loads more albums when scrolling to the bottom',
        (tester) async {
      when(collection.albums).thenReturn(
          List.generate(20, (index) => testAlbum1.copyWith(id: index)));

      await tester.pumpWidget(createHome());

      await tester.drag(
          find.byKey(const ValueKey<int>(1)), const Offset(0.0, -1000.0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      verify(collection.loadMoreAlbums());
    });

    testWidgets('reloads collection on drag beyond the top',
            (tester) async {
          when(collection.albums).thenReturn(
              List.generate(20, (index) => testAlbum1.copyWith(id: index)));

          await tester.pumpWidget(createHome());

          await tester.drag(
              find.text('Record Scrobbler'), const Offset(0.0, 250.0));
          await tester.pump();
          await tester.pump(const Duration(seconds: 3));

          verify(collection.reload());
        });
  });
}

// Mock classes
class MockCollection extends Mock implements Collection {
  @override
  Loading get loadingNotifier => MockLoading();
}

class MockLoading extends Mock implements Loading {}
