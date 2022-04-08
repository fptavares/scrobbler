import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:scrobbler/components/error.dart';
import 'package:scrobbler/components/rating.dart';
import 'package:scrobbler/components/scrobble.dart';
import 'package:scrobbler/model/discogs.dart';
import 'package:scrobbler/model/lastfm.dart';
import 'package:scrobbler/model/playlist.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/app_review_mock.dart';
import '../mocks/firebase_mocks.dart';
import '../mocks/model_mocks.dart';
import '../test_albums.dart';

void main() {
  group('Scrobble button', () {
    late MockScrobbler scrobbler;
    late MockCollection collection;
    late MockPlaylist playlist;

    Widget createButton() {
      return MultiProvider(
        providers: [
          Provider<Scrobbler>.value(
            value: scrobbler,
          ),
          ChangeNotifierProvider<Collection>.value(
            value: collection,
          ),
          ChangeNotifierProvider<Playlist>.value(
            value: playlist,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: ScrobbleFloatingButton(),
          ),
        ),
      );
    }

    setUp(() {
      replaceFirebaseWithMocks();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      scrobbler = createMockScrobbler();
      playlist = createMockPlaylist();
      when(playlist.isScrobbling).thenReturn(false);
      when(playlist.isScrobblingPaused).thenReturn(false);
      when(playlist.numberOfItems).thenReturn(15);
      when(playlist.maxItemCount()).thenReturn(1);
      collection = createMockCollection();
    });

    testWidgets('renders if playlist has something', (tester) async {
      when(playlist.isEmpty).thenReturn(false);

      await tester.pumpWidget(createButton());

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('hides if playlist is empty', (tester) async {
      when(playlist.isEmpty).thenReturn(true);

      await tester.pumpWidget(createButton());

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('triggers playlist scrobbling on tap', (tester) async {
      when(playlist.isEmpty).thenReturn(false);

      final scrobbleResults = [10, 5];

      when(playlist.scrobble(any, any, any)).thenAnswer((_) => Stream.fromIterable(scrobbleResults));

      await tester.pumpWidget(createButton());

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      verify(playlist.scrobble(scrobbler, collection, any)).called(1);
    });

    // need to dismiss the bottom sheet to dispose its AnimationController
    // https://stackoverflow.com/questions/57580244/flutter-showmodalbottomsheet-ticker-was-not-disposed-during-tests
    testWidgets(
      'allows editing the playlist before submitting',
      (tester) async {
        when(playlist.isEmpty).thenReturn(false);

        late ScrobbleOptions? options;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(),
              floatingActionButton: Builder(
                builder: (context) => FloatingActionButton(
                  child: const Icon(Icons.play_arrow),
                  onPressed: () async {
                    options = await ScrobbleFloatingButton.showPlaylistOptionsDialog(
                        context, [testAlbumDetails1, testAlbumDetails1]);
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(ScrobblePlaylistEditor), findsOneWidget);
        expect(find.text(testAlbumDetails1.title), findsNWidgets(2));
        expect(find.text(testAlbumDetails1.artist), findsNWidgets(2));

        // tap to expand tile
        await tester.tap(find.text(testAlbumDetails1.title).first);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // drag up to expose all child tiles
        await tester.drag(find.text(testAlbumDetails1.title).first, const Offset(0, -300));
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));

        expect(find.byType(CheckboxListTile), findsNWidgets(testAlbumDetails1.tracks.length));
        expect(find.text(testAlbumDetails1.tracks.first.title), findsOneWidget);

        await tester.tap(find.text(testAlbumDetails1.tracks[0].title));
        await tester.pump();

        await tester.tap(find.text(testAlbumDetails1.tracks[1].title));
        await tester.pump();

        await tester.tap(find.text(testAlbumDetails1.tracks[2].title));
        await tester.pump();

        await tester.tap(find.text(testAlbumDetails1.tracks[1].title));
        await tester.pump();

        // show tooltip on tap
        expect(find.text('When?'), findsOneWidget);
        await tester.tap(find.text('When?'));
        await tester.pump(const Duration(seconds: 2)); // faded in

        expect(find.text(ScrobblePlaylistEditor.whenTooltipMessage), findsOneWidget);

        // submit
        await tester.tap(find.byType(TextButton));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(
            options!.inclusionMask,
            equals({
              0: {0: false, 1: true, 2: false}
            }));

        expect(options!.offsetInSeconds, equals(0));

        // reopen options dialog
        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(ScrobblePlaylistEditor), findsOneWidget);

        // change time offset slider to middle value (= 60 minutes)
        await tester.tap(find.byType(Slider));
        await tester.pump();

        // submit
        await tester.tap(find.byType(TextButton));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(options!.inclusionMask, equals({}));
        expect(options!.offsetInSeconds, equals(60 * 60));
      },
    );

    testWidgets('doesn\'t allow tap if playlist is already scrobbling', (tester) async {
      when(playlist.isEmpty).thenReturn(false);
      when(playlist.isScrobbling).thenReturn(true);

      await tester.pumpWidget(createButton());

      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(tester.widget<FloatingActionButton>(find.byType(FloatingActionButton)).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      verifyNever(playlist.scrobble(any, any, any));
    });

    testWidgets('display error if scrobbling fails', (tester) async {
      when(playlist.isEmpty).thenReturn(false);

      final exception = UIException('no connection', const SocketException(''));
      when(playlist.scrobble(any, any, any)).thenThrow(exception);

      await tester.pumpWidget(createButton());

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      verify(playlist.scrobble(scrobbler, collection, any)).called(1);

      expect(find.text('no connection'), findsOneWidget);
    });

    testWidgets('tries to ask for review after scrobbling', (tester) async {
      final review = createMockAppReview();
      ReviewRequester.appReview = review;
      when(playlist.isEmpty).thenReturn(false);
      when(playlist.scrobble(any, any, any)).thenAnswer((_) => Stream.fromIterable([1]));

      await tester.pumpWidget(createButton());

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      verify(review.requestReview());
    });

    testWidgets('does not ask for review after failed scrobbling', (tester) async {
      final review = createMockAppReview();
      ReviewRequester.appReview = review;
      when(playlist.isEmpty).thenReturn(false);
      when(playlist.scrobble(any, any, any)).thenAnswer((_) => Stream.fromIterable([0]));

      await tester.pumpWidget(createButton());

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      verifyNever(review.requestReview());
    });

    testWidgets('catches and ignore errors when trying to ask for review', (tester) async {
      final review = createMockAppReview();
      ReviewRequester.appReview = review;
      when(review.requestReview()).thenThrow(Exception('boom'));
      expect(ReviewRequester.instance.tryToAskForAppReview, returnsNormally); // doesn't throw
    });
  });
}
