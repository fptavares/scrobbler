import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:scrobbler/components/scrobble.dart';
import 'package:scrobbler/model/discogs.dart';
import 'package:scrobbler/model/lastfm.dart';
import 'package:scrobbler/model/playlist.dart';


void main() {
  group('Scrobble button', () {
    MockScrobbler scrobbler;
    MockCollection collection;
    MockPlaylist playlist;

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
      playlist = MockPlaylist();
      when(playlist.isScrobbling).thenReturn(false);
      collection = MockCollection();
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
      
      when(playlist.scrobble(any, any)).thenAnswer((_) => Stream.fromIterable(scrobbleResults));

      await tester.pumpWidget(createButton());

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      verify(playlist.scrobble(scrobbler, collection)).called(1);
    });

    testWidgets('display error if scrobbling fails', (tester) async {
      when(playlist.isEmpty).thenReturn(false);

      const exception = SocketException('no connection');
      when(playlist.scrobble(any, any)).thenThrow(exception);

      await tester.pumpWidget(createButton());

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      verify(playlist.scrobble(scrobbler, collection)).called(1);

      expect(find.text(exception.toString()), findsOneWidget);
    });
  });
}

// Mock classes
class MockCollection extends Mock implements Collection {}
class MockScrobbler extends Mock implements Scrobbler {}
class MockPlaylist extends Mock implements Playlist {}
