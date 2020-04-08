import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:scrobbler/components/album.dart';
import 'package:scrobbler/components/playlist.dart';
import 'package:scrobbler/model/playlist.dart';

import '../test_albums.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // create image file on in-memory file system for testing
  final data = await rootBundle.load('assets/record_sleeve.png');
  final tempDir =
      await MemoryFileSystem().systemTempDirectory.createTemp('images');
  final testImageFile = tempDir.childFile('test.png');
  testImageFile.writeAsBytesSync(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));

  group('Album button', () {
    Future<Playlist> pumpAlbumButton(WidgetTester tester,
        {bool imageFound = true}) async {
      // create mock cache manager
      final cache = MockCacheManager();
      if (imageFound) {
        when(cache.getFile(any)).thenAnswer((invocation) => Stream.value(
            FileInfo(testImageFile, FileSource.Online, DateTime.now(),
                invocation.positionalArguments.first)));
      } else {
        when(cache.getFile(any))
            .thenAnswer((_) => Stream.error(const HttpException('404')));
      }
      CachedAlbumImage.cacheManager = cache;

      final playlist = Playlist();
      // Build our app and trigger a frame.
      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<Playlist>.value(
          value: playlist,
          child: AlbumButton(testAlbum1),
        ),
      ));
      return playlist;
    }

    testWidgets('renders properly', (tester) async {
      await pumpAlbumButton(tester);

      // first shows progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      // then loads and displays image
      expect(find.byKey(ValueKey<int>(testAlbum1.id)), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      // no default data is shown
      expect(find.text(testAlbum1.artist), findsNothing);
      expect(find.text(testAlbum1.title), findsNothing);
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
      expect(playlist.getPlaylistItem(testAlbum1).count, equals(2));
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
      expect(playlist.getPlaylistItem(testAlbum1), isNull);
      // Expect to not find the indicator on screen
      expect(find.byType(PlaylistCountIndicator), findsNothing);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('shows a default image if the album cover cannot be found',
        (tester) async {
      await pumpAlbumButton(tester, imageFound: false);

      // first shows progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      // then loads and displays default image
      expect(find.byKey(ValueKey<int>(testAlbum1.id)), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      // and album data is rendered on top
      expect(find.text(testAlbum1.artist), findsOneWidget);
      expect(find.text(testAlbum1.title), findsOneWidget);
    });
  });
}

class MockCacheManager extends Mock implements BaseCacheManager {}
