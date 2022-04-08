import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:scrobbler/components/album.dart';
import 'package:scrobbler/components/emtpy.dart';
import 'package:scrobbler/components/home.dart';
import 'package:scrobbler/components/playlist.dart';
import 'package:scrobbler/components/search.dart';
import 'package:scrobbler/model/discogs.dart';
import 'package:scrobbler/model/playlist.dart';

import '../mocks/firebase_mocks.dart';
import '../mocks/model_mocks.dart';
import '../test_albums.dart';

void main() {
  group('Search page', () {
    late MockCollection collection;
    late Playlist playlist;

    Future<Widget> createAppBar() async {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<Collection>.value(value: collection),
          ChangeNotifierProvider<Playlist>.value(value: playlist),
          ValueListenableProvider<LoadingStatus>.value(value: collection.loadingNotifier),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: <Widget>[HomeAppBar()],
            ),
          ),
        ),
      );
    }

    Future pumpSearchWidget(WidgetTester tester) async {
      await tester.pumpWidget(await createAppBar());

      expect(find.byIcon(Icons.search), findsOneWidget);

      await tester.tap(find.byTooltip('Search'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode!.hasFocus, isTrue);
    }

    setUp(() {
      replaceFirebaseWithMocks();
      playlist = Playlist();
      collection = createMockCollection();
      when(collection.loadingNotifier).thenReturn(ValueNotifier<LoadingStatus>(LoadingStatus.neverLoaded));
      when(collection.isNotEmpty).thenReturn(true);
      when(collection.isNotFullyLoaded).thenReturn(true);
      when(collection.isNotLoading).thenReturn(true);
      when(collection.totalItems).thenReturn(2);
    });

    testWidgets('renders and lists all currently loaded albums', (tester) async {
      // mock search results
      when(collection.search(any)).thenReturn([testAlbum1, testAlbum2]);

      await pumpSearchWidget(tester);

      expect(find.byType(CachedAlbumImage), findsNWidgets(2));

      expect(find.text(testAlbum1.artist), findsOneWidget);
      expect(find.text(testAlbum1.title), findsOneWidget);
      for (final format in testAlbum1.formats) {
        expect(find.text(format.toString()), findsOneWidget);
      }
      expect(find.text('Released in ${testAlbum1.year}'), findsOneWidget);

      expect(find.text(testAlbum2.artist), findsOneWidget);
      expect(find.text(testAlbum2.title), findsOneWidget);
      for (final format in testAlbum2.formats) {
        expect(find.text(format.toString()), findsOneWidget);
      }
      expect(testAlbum2.year, equals(0));
      expect(find.text('Released in 0'), findsNothing);

      // search seems to build suggestions twice when it loads
      verify(collection.search('')).called(lessThanOrEqualTo(2));
      // should not load anything else until there is text input
      verifyNever(collection.loadMoreAlbums());
      verifyNever(collection.loadAllAlbums());
    });

    testWidgets('loads all albums when typing starts', (tester) async {
      // mock search results
      when(collection.search(any)).thenReturn([testAlbum1]);

      await pumpSearchWidget(tester);

      expect(find.byType(ListTile), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();
      // load all albums
      verify(collection.loadAllAlbums()).called(1);
      verify(collection.search('a')).called(1);
      verifyNever(collection.loadMoreAlbums());
    });

    testWidgets('allows adding albums to playlist', (tester) async {
      // mock search results
      when(collection.search(any)).thenReturn([testAlbum1]);

      await pumpSearchWidget(tester);

      expect(find.byType(ListTile), findsOneWidget);

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      // Expect to find the indicator on screen
      expect(find.byType(PlaylistCountIndicator), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      // Expect to find the indicator on screen
      expect(find.byType(PlaylistCountIndicator), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('allows removing albums from playlist', (tester) async {
      // mock search results
      when(collection.search(any)).thenReturn([testAlbum1]);

      await pumpSearchWidget(tester);

      expect(find.byType(ListTile), findsOneWidget);

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(find.byType(PlaylistCountIndicator), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byType(PlaylistCountIndicator));
      await tester.pump();

      // Expect that the indicator is gone
      expect(find.byType(PlaylistCountIndicator), findsNothing);
      expect(find.text('2'), findsNothing);
    });

    testWidgets('re-runs search for every text input changes', (tester) async {
      // mock search results
      when(collection.search(any)).thenReturn([testAlbum1]);

      await pumpSearchWidget(tester);

      expect(find.byType(ListTile), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'r');
      await tester.pump();
      verify(collection.search('r')).called(1);

      // mock loading all albums completion
      when(collection.isFullyLoaded).thenReturn(true);
      when(collection.isNotFullyLoaded).thenReturn(false);

      await tester.enterText(find.byType(TextField), 'ra');
      await tester.pump();
      verify(collection.search('ra')).called(1);

      await tester.enterText(find.byType(TextField), 'rad');
      await tester.pump();
      verify(collection.search('rad')).called(1);

      await tester.enterText(find.byType(TextField), 'radi');
      await tester.pump();
      verify(collection.search('radi')).called(1);

      await tester.enterText(find.byType(TextField), 'radio');
      await tester.pump();
      verify(collection.search('radio')).called(1);

      await tester.enterText(find.byType(TextField), 'radi');
      await tester.pump();
      verify(collection.search('radi')).called(1);

      verifyNever(collection.search(argThat(isNot('')))); // no extra search
      verify(collection.loadAllAlbums()).called(1);
      verifyNever(collection.loadMoreAlbums());
    });

    testWidgets('handles initial empty state', (tester) async {
      // mock empty search results
      when(collection.search(any)).thenReturn([]);

      await pumpSearchWidget(tester);

      expect(find.byType(ListTile), findsNothing);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text(AlbumSearch.emptyHeadlineMessage), findsOneWidget);
      expect(find.text(AlbumSearch.emptySubheadMessage), findsOneWidget);

      // search seems to build suggestions twice when it loads
      verify(collection.search('')).called(lessThanOrEqualTo(2));
      // should not load anything else until there is text input
      verifyNever(collection.loadMoreAlbums());
      verifyNever(collection.loadAllAlbums());
    });

    testWidgets('handles transition from list to empty state', (tester) async {
      // mock search results
      when(collection.search(any)).thenReturn([testAlbum1]);

      await pumpSearchWidget(tester);

      expect(find.byType(ListTile), findsOneWidget);

      // mock empty search results
      when(collection.search(any)).thenReturn([]);

      await tester.enterText(find.byType(TextField), 'x');
      await tester.pumpAndSettle();
      verify(collection.search('x')).called(1);

      // mock loading all albums completion
      when(collection.isFullyLoaded).thenReturn(true);
      when(collection.isNotFullyLoaded).thenReturn(false);

      expect(find.byType(ListTile), findsNothing);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text(AlbumSearch.emptyHeadlineMessage), findsOneWidget);
      expect(find.text(AlbumSearch.emptySubheadMessage), findsOneWidget);

      verifyNever(collection.search(argThat(isNot('')))); // no extra search
      verifyNever(collection.loadMoreAlbums());
      verify(collection.loadAllAlbums()).called(1);
    });

    testWidgets('allows clearing the search query', (tester) async {
      // mock search results
      when(collection.search(any)).thenReturn([testAlbum1]);

      await pumpSearchWidget(tester);

      final textField = tester.widget<TextField>(find.byType(TextField));

      // search seems to build suggestions twice when it loads
      verify(collection.search('')).called(lessThanOrEqualTo(2));

      await tester.enterText(find.byType(TextField), 'radio');
      await tester.pump();
      expect(textField.controller!.text, equals('radio'));
      verify(collection.search('radio')).called(1);

      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();
      expect(textField.controller!.text, equals(''));
      expect(textField.focusNode!.hasFocus, isTrue);
      verify(collection.search('')).called(1);

      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('allows going back to home', (tester) async {
      // mock search results
      when(collection.search(any)).thenReturn([testAlbum1]);

      await pumpSearchWidget(tester);

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);

      // Close search
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNothing);
      expect(find.byType(HomeAppBar), findsOneWidget);
    });
  });
}
