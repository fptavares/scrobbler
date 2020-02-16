import 'package:drs_app/model/discogs.dart';
import 'package:drs_app/model/lastfm.dart';
import 'package:drs_app/model/playlist.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../test_albums.dart';

void main() {
  group('Playlist', () {
    Playlist playlist;

    setUp(() {
      playlist = Playlist();
    });

    test('starts empty', () {
      expect(playlist.numberOfItems, equals(0));
      expect(playlist.isEmpty, equals(true));
      expect(playlist.isNotEmpty, equals(false));
    });

    test('can add a new album', () {
      playlist.addAlbum(testAlbum1);

      expect(playlist.numberOfItems, equals(1));
      expect(playlist.isEmpty, equals(false));
      expect(playlist.isNotEmpty, equals(true));

      final item = playlist.getPlaylistItem(testAlbum1);
      expect(item.count, equals(1));
    });

    test('can add the same album multiple times', () {
      playlist.addAlbum(testAlbum1);

      expect(playlist.numberOfItems, equals(1));
      expect(playlist.isEmpty, isFalse);
      expect(playlist.isNotEmpty, isTrue);

      playlist.addAlbum(testAlbum1);

      expect(playlist.numberOfItems, equals(1));
      expect(playlist.isEmpty, isFalse);
      expect(playlist.isNotEmpty, isTrue);

      final item = playlist.getPlaylistItem(testAlbum1);
      expect(item.count, equals(2));
    });

    test('can add a second album', () {
      playlist.addAlbum(testAlbum1);

      expect(playlist.numberOfItems, equals(1));
      expect(playlist.isEmpty, isFalse);
      expect(playlist.isNotEmpty, isTrue);

      playlist.addAlbum(testAlbum2);

      expect(playlist.numberOfItems, equals(2));
      expect(playlist.isEmpty, isFalse);
      expect(playlist.isNotEmpty, isTrue);

      var item = playlist.getPlaylistItem(testAlbum1);
      expect(item.count, equals(1));

      item = playlist.getPlaylistItem(testAlbum2);
      expect(item.count, equals(1));
    });

    test('can remove only album in the playlist', () {
      playlist.addAlbum(testAlbum1);

      expect(playlist.numberOfItems, equals(1));

      playlist.removeAlbum(testAlbum1);

      expect(playlist.numberOfItems, equals(0));
      expect(playlist.isEmpty, isTrue);

      final item = playlist.getPlaylistItem(testAlbum1);
      expect(item, isNull);
    });

    test('can remove one album of two in the playlist', () {
      playlist.addAlbum(testAlbum1);
      playlist.addAlbum(testAlbum2);

      expect(playlist.numberOfItems, equals(2));

      playlist.removeAlbum(testAlbum2);

      expect(playlist.numberOfItems, equals(1));
      expect(playlist.getPlaylistItems().map((i) => i.album.releaseId),
          [testAlbum1.releaseId]);

      final item = playlist.getPlaylistItem(testAlbum2);
      expect(item, isNull);
    });

    test('can increase and decrease the count of playlist item', () {
      playlist.addAlbum(testAlbum1);

      final item = playlist.getPlaylistItem(testAlbum1);
      expect(item.count, equals(1));
      item.increase();
      expect(item.count, equals(2));
      item.increase();
      expect(item.count, equals(3));
      item.decrease();
      expect(item.count, equals(2));
      item.decrease();
      expect(item.count, equals(1));
      item.decrease();
      expect(item.count, equals(0));
      item.decrease();
      expect(item.count, equals(0));
      item.increase();
      expect(item.count, equals(1));
    });

    test('can scrobble the albums', () async {
      // add albums
      playlist.addAlbum(testAlbum1);
      playlist.addAlbum(testAlbum2);
      playlist.addAlbum(testAlbum1);
      expect(playlist.numberOfItems, equals(2));

      final scrobbleResults = [10, 5];

      // create mocks
      final scrobbler = MockScrobbler();
      when(scrobbler.isNotAuthenticated).thenReturn(false);
      when(scrobbler.scrobbleAlbums(argThat(isList)))
          .thenAnswer((_) => Stream.fromIterable(scrobbleResults));

      final collection = MockCollection();
      when(collection.getAlbumDetails(any)).thenAnswer(
          (i) => Future.value(FakeAlbumDetails(i.positionalArguments.first)));

      // scrobble
      final accepted = await playlist.scrobble(scrobbler, collection).toList();

      // check that get album details is called exactly twice for the right IDs
      var verification = verify(collection.getAlbumDetails(captureAny));
      verification.called(2);
      expect(
          verification.captured, [testAlbum1.releaseId, testAlbum2.releaseId]);

      // check scrobble that results are passed through
      expect(accepted, equals(scrobbleResults));
      verification = verify(scrobbler.scrobbleAlbums(captureAny));
      verification.called(1);
      expect(
        verification.captured.first.map((a) => a.releaseId),
        [testAlbum1.releaseId, testAlbum1.releaseId, testAlbum2.releaseId],
      );
    });
  });
}

// Mock classes
class MockScrobbler extends Mock implements Scrobbler {}

class MockCollection extends Mock implements Collection {}

class FakeAlbumDetails extends Fake implements AlbumDetails {
  FakeAlbumDetails(this._id);

  final int _id;

  @override
  int get releaseId => _id;
}
