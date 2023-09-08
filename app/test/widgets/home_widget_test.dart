import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:scrobbler/components/accounts.dart';
import 'package:scrobbler/components/album.dart';
import 'package:scrobbler/components/emtpy.dart';
import 'package:scrobbler/components/home.dart';
import 'package:scrobbler/model/bluos.dart';
import 'package:scrobbler/model/discogs.dart';
import 'package:scrobbler/model/playlist.dart';
import 'package:scrobbler/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/firebase_mocks.dart';
import '../mocks/model_mocks.dart';
import '../discogs_test_data.dart';

Future<void> main() async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    Settings.discogsUsernameKey: 'test-user',
    Settings.skippedKey: false,
    Settings.lastfmUsernameKey: 'test-user',
    Settings.lastfmSessionKeyKey: 'test',
  });
  final prefs = await SharedPreferences.getInstance();

  group('Home page', () {
    late MockCollection collection;
    late MockBluOS bluos;
    late Playlist playlist;

    Widget createHome() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<Settings>(
            create: (_) => Settings(prefs),
          ),
          ChangeNotifierProvider<Collection>.value(value: collection),
          ChangeNotifierProvider<BluOS>.value(value: bluos),
          ChangeNotifierProvider<Playlist>.value(value: playlist),
        ],
        child: MaterialApp(
          home: const Scaffold(body: HomePage()),
          routes: <String, WidgetBuilder>{
            '/playlist': (_) => const Text('Playlist test'),
          },
        ),
      );
    }

    setUp(() {
      replaceFirebaseWithMocks();

      playlist = Playlist();
      collection = createMockCollection();
      bluos = createMockBluOSMonitor();

      // mock album list
      when(collection.loadingNotifier).thenReturn(ValueNotifier<LoadingStatus>(LoadingStatus.neverLoaded));
      when(collection.albums).thenReturn([testAlbum1, testAlbum2]);
      when(collection.isUserEmpty).thenReturn(false);
      when(collection.isEmpty).thenReturn(false);
      when(collection.isNotEmpty).thenReturn(true);
      when(collection.isNotFullyLoaded).thenReturn(true);
      when(collection.isNotLoading).thenReturn(true);
      when(collection.isLoading).thenReturn(false);
      when(collection.hasMorePages).thenReturn(true);
      when(collection.totalItems).thenReturn(50);
      when(collection.nextPage).thenReturn(2);
    });

    testWidgets('renders properly', (tester) async {
      await tester.pumpWidget(createHome());

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('scrobbler.'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.playlist_play), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byType(AlbumButton), findsNWidgets(2));

      verify(collection.albums);
    });

    testWidgets('shows progress indicator when loading ', (tester) async {
      when(collection.albums).thenReturn([]);
      when(collection.isEmpty).thenReturn(true);
      when(collection.isNotLoading).thenReturn(false);
      when(collection.isLoading).thenReturn(true);

      await tester.pumpWidget(createHome());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      verify(collection.isLoading);
    });

    testWidgets('opens drawer on menu button tap', (tester) async {
      await tester.pumpWidget(createHome());

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(AccountsForm), findsOneWidget);
    });

    testWidgets('playlist button is disabled when playlist is empty', (tester) async {
      playlist.clearAlbums();

      await tester.pumpWidget(createHome());

      expect(
          tester
              .widget<IconButton>(
                  find.ancestor(of: find.byIcon(Icons.playlist_play), matching: find.byType(IconButton)))
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

    testWidgets('loads more albums when scrolling to the bottom', (tester) async {
      when(collection.albums).thenReturn(List.generate(20, (index) => testAlbum1.copyWith(id: index)));

      await tester.pumpWidget(createHome());

      await tester.drag(find.byKey(const ValueKey<int>(1)), const Offset(0.0, -1000.0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      verify(collection.loadMoreAlbums());
    });

    testWidgets('reloads collection on drag beyond the top', (tester) async {
      when(collection.albums).thenReturn(List.generate(20, (index) => testAlbum1.copyWith(id: index)));

      await tester.pumpWidget(createHome());

      expect(find.byIcon(Icons.refresh), findsNothing); // no refresh button on mobile platforms

      await tester.drag(find.byKey(const ValueKey<int>(0)), const Offset(0.0, 250.0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      verify(collection.reload(emptyCache: true));
    }, variant: TargetPlatformVariant.mobile());

    testWidgets('reloads collection on refresh button tap', (tester) async {
      when(collection.albums).thenReturn(List.generate(20, (index) => testAlbum1.copyWith(id: index)));

      await tester.pumpWidget(createHome());

      expect(find.byIcon(Icons.refresh), findsOneWidget); // refresh button available on desktop platforms

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      verify(collection.reload(emptyCache: true));
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('scroll to top when user taps the app bar title', (tester) async {
      when(collection.albums).thenReturn(List.generate(50, (index) => testAlbum1.copyWith(id: index)));

      await tester.pumpWidget(createHome());

      final firstAlbumFinder = find.byKey(const ValueKey<int>(0));
      final lastAlbumFinder = find.byKey(const ValueKey<int>(49));

      expect(firstAlbumFinder, findsOneWidget);
      expect(lastAlbumFinder, findsNothing);

      await tester.drag(firstAlbumFinder, const Offset(0.0, -1000.0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(firstAlbumFinder, findsNothing);
      expect(lastAlbumFinder, findsOneWidget);

      await tester.tap(find.byKey(const Key('logo')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(firstAlbumFinder, findsOneWidget);
      expect(lastAlbumFinder, findsNothing);
    });

    testWidgets('handles empty state error', (tester) async {
      when(collection.hasLoadingError).thenReturn(true);
      when(collection.isEmpty).thenReturn(true);
      when(collection.isNotLoading).thenReturn(true);
      when(collection.errorMessage).thenReturn('My test error message');
      when(collection.albums).thenReturn([]);

      await tester.pumpWidget(createHome());

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Whoops!'), findsOneWidget);
      expect(find.text('My test error message'), findsOneWidget);
    });

    testWidgets('doesn\'t show empty state on error if collection isn\'t empty', (tester) async {
      when(collection.hasLoadingError).thenReturn(true);
      when(collection.isEmpty).thenReturn(false);
      when(collection.isNotLoading).thenReturn(true);
      when(collection.errorMessage).thenReturn('My test error message');
      when(collection.albums).thenReturn([testAlbum1]);

      await tester.pumpWidget(createHome());

      expect(find.byType(EmptyState), findsNothing);
      expect(find.text('Whoops!'), findsNothing);
      expect(find.text('My test error message'), findsNothing);
    });
  });
}
