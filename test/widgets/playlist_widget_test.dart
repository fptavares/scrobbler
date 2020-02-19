import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scrobbler/components/emtpy.dart';
import 'package:scrobbler/components/playlist.dart';
import 'package:scrobbler/model/playlist.dart';

import '../test_albums.dart';

void main() {
  group('Playlist page', () {
    Playlist playlist;

    Widget createPlaylist() {
      return ChangeNotifierProvider<Playlist>.value(
        value: playlist,
        child: MaterialApp(
          home: PlaylistPage(),
        ),
      );
    }

    setUp(() {
      playlist = Playlist();
      playlist.addAlbum(testAlbum1);
      playlist.addAlbum(testAlbum2);
      playlist.addAlbum(testAlbum2);
    });

    testWidgets('renders and lists all albums in the playlist', (tester) async {
      await tester.pumpWidget(createPlaylist());

      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.text(testAlbum1.artist), findsOneWidget);
      expect(find.text(testAlbum1.title), findsOneWidget);
      expect(find.text(testAlbum2.artist), findsOneWidget);
      expect(find.text(testAlbum2.title), findsOneWidget);
    });

    testWidgets('allows increasing album count in playlist', (tester) async {
      await tester.pumpWidget(createPlaylist());

      expect(find.byType(PlaylistCountIndicator), findsNWidgets(2));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.text(testAlbum1.title));
      await tester.pump();

      expect(find.text('2'), findsNWidgets(2));

      await tester.tap(find.text(testAlbum1.title));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('allows decreasing album count in playlist', (tester) async {
      await tester.pumpWidget(createPlaylist());

      final lastItemCount = find.byType(PlaylistCountIndicator).last;
      Finder lastItemCountWith(int count) =>
          find.descendant(of: lastItemCount, matching: find.text('$count'));

      expect(lastItemCountWith(2), findsOneWidget);

      await tester.tap(lastItemCount);
      await tester.pump();

      expect(lastItemCountWith(1), findsOneWidget);

      await tester.tap(lastItemCount);
      await tester.pump();

      expect(lastItemCountWith(0), findsOneWidget);

      await tester.tap(lastItemCount);
      await tester.pump();

      // doesn't go below 0
      expect(lastItemCountWith(0), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // first one remains unchanged
    });

    testWidgets('allows removing from playlist', (tester) async {
      await tester.pumpWidget(createPlaylist());

      expect(find.byType(Dismissible), findsNWidgets(2));
      final firstItem = find.byType(Dismissible).first;

      Future<void> desmissFirstItem() async {
        await tester.fling(firstItem, const Offset(-500.0, 0.0), 10000.0);

        // below thanks to: https://github.com/flutter/flutter/blob/master/packages/flutter/test/widgets/dismissible_test.dart
        await tester.pump(); // start the slide
        await tester.pump(const Duration(seconds: 1)); // finish the slide and start shrinking...
        await tester.pump(); // first frame of shrinking animation
        await tester.pump(const Duration(seconds: 1)); // finish the shrinking and call the callback...
        await tester.pump(); // rebuild after the callback removes the entry
      }

      expect(find.text(testAlbum1.title), findsOneWidget);
      await desmissFirstItem();
      expect(find.text(testAlbum1.title), findsNothing);

      expect(find.byType(Dismissible), findsOneWidget);

      expect(find.text(testAlbum2.title), findsOneWidget);
      await desmissFirstItem();
      expect(find.text(testAlbum2.title), findsNothing);

      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('allows removing all albums from playlist with one tap', (tester) async {
      await tester.pumpWidget(createPlaylist());

      await tester.tap(find.byTooltip('Remove all'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('handles transition from list to empty state', (tester) async {
      await tester.pumpWidget(createPlaylist());

      await tester.tap(find.byTooltip('Remove all'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNothing);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text(PlaylistPage.emptyHeadlineMessage), findsOneWidget);
      expect(find.text(PlaylistPage.emptySubheadMessage), findsOneWidget);
    });
  });
}
