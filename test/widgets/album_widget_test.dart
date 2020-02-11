import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drs_app/components/album.dart';
import 'package:drs_app/components/playlist.dart';
import 'package:drs_app/model/discogs.dart';
import 'package:drs_app/model/playlist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'mock_image_http.dart';

final CollectionAlbum _testAlbum1 = CollectionAlbum(
  id: 123,
  releaseId: 456,
  artist: 'Radiohead',
  title: 'OK Computer',
  year: 1997,
  thumbUrl:
      'https://api-img.discogs.com/kAXVhuZuh_uat5NNr50zMjN7lho=/fit-in/300x300/filters:strip_icc():format(jpeg):mode_rgb()/discogs-images/R-249504-1334592212.jpeg.jpg',
  rating: 5,
  dateAdded: '2017-06-22T14:34:40-07:00',
);

Future<void> main() async {
  group('Album button', () {
    Future<Playlist> pumpAlbumButton(WidgetTester tester) async {
      final playlist = Playlist();
      // Build our app and trigger a frame.
      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<Playlist>.value(
          value: playlist,
          child: AlbumButton(_testAlbum1),
        ),
      ));
      return playlist;
    }

    testWidgets('renders properly', (tester) async {
      HttpOverrides.runZoned(() async {
        await pumpAlbumButton(tester);

        expect(find.byKey(ValueKey<int>(_testAlbum1.id)), findsOneWidget);
        expect(find.byType(CachedNetworkImage), findsOneWidget);
      }, createHttpClient: createMockImageHttpClient);
    });

    testWidgets('adds to playlist when tapped', (tester) async {
      final playlist = await pumpAlbumButton(tester);

      // Tap the cover image
      await tester.tap(find.byType(CachedNetworkImage));
      // Rebuild the widget after the state has changed
      await tester.pump();
      // Expect playlist to have one item
      expect(playlist.numberOfItems, equals(1));
      // Expect to find the indicator on screen
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Tap the cover image
      await tester.tap(find.byType(CachedNetworkImage));
      // Rebuild the widget after the state has changed
      await tester.pump();
      // Expect playlist to still have one item
      expect(playlist.numberOfItems, equals(1));
      expect(playlist.getPlaylistItem(_testAlbum1).count, equals(2));
      // Expect to find the indicator on screen
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('removes from playlist when the playlist indicator is tapped',
        (tester) async {
      final playlist = await pumpAlbumButton(tester);

      // Tap the cover image
      await tester.tap(find.byType(CachedNetworkImage));
      // Rebuild the widget after the state has changed
      await tester.pump();
      // Expect playlist to have one item
      expect(playlist.numberOfItems, equals(1));
      // Expect to find the indicator on screen
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Tap the playlist indicator
      await tester.tap(find.byType(PlaylistCountIndicator));
      // Rebuild the widget after the state has changed
      await tester.pump();
      // Expect playlist to be empty
      expect(playlist.numberOfItems, equals(0));
      expect(playlist.getPlaylistItem(_testAlbum1), isNull);
      // Expect to not find the indicator on screen
      expect(find.byType(PlaylistCountIndicator), findsNothing);
      expect(find.byType(Text), findsNothing);
    });
  });
}
