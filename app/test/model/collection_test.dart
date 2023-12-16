import 'dart:io';

import 'package:file/file.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:scrobbler/components/error.dart';
import 'package:scrobbler/model/discogs.dart';
import 'package:scrobbler/secrets.dart';

import '../mocks/cache_mocks.dart';
import 'collection_test_data.dart';

const userAgent = 'test user-agent';
const username = 'test_user';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Collection collection;
  late MockCacheManager cache;
  final fallbackClient = MockClient();

  void initializeCollectionMockCache() {
    final pages = [
      jsonForCollectionPageOneWithTwoAlbums,
      jsonForCollectionPageTwoWithTwoAlbums,
      jsonForCollectionLastPageWithOneAlbum,
    ];

    final collectionFile = createMockFile(() => pages.removeAt(0));
    final albumFile = createMockFile(() => jsonForRelease);
    final albumWithSubtracksFile = createMockFile(() => jsonForReleaseWithSubtracks);
    final albumWithTwoArtists = createMockFile(() => jsonForReleaseWithTwoArtists);

    cache = createMockCacheManager({
      equals('https://api.discogs.com/releases/249504'): (_) => Future<File>.value(albumFile),
      equals('https://api.discogs.com/releases/1287017'): (_) => Future<File>.value(albumWithSubtracksFile),
      equals('https://api.discogs.com/releases/6895819'): (_) => Future<File>.value(albumWithTwoArtists),
      contains('/collection/folders/0/releases'): (_) {
        expect(collection.isLoading, isTrue);
        expect(collection.isNotLoading, isFalse);
        return Future<File>.value(collectionFile);
      }
    });
    when(cache.emptyCache()).thenAnswer((_) => Future.value(null));

    Collection.cache = cache;
    collection.fallbackClient = fallbackClient;
  }

  void verifyHeaders(Map<String, String>? headers) {
    expect(
        headers,
        allOf([
          containsPair('User-Agent', userAgent),
          containsPair('Authorization', 'Discogs key=$discogsConsumerKey, secret=$discogsConsumerSecret'),
        ]));
  }

  void verifyNoMoreCacheOperations() {
    verifyNoMoreInteractions(Collection.cache);
  }

  void verifyCollectionRequests(List<int> expectedPageNumbers) {
    final args = verify(cache.getSingleFile(captureAny, headers: captureAnyNamed('headers'))).captured;
    for (var i = 0; i < expectedPageNumbers.length; i++) {
      expect(
          args[i * 2],
          allOf([
            startsWith('https://api.discogs.com/users/$username/collection/folders/0/releases'),
            contains('page=${expectedPageNumbers[i]}')
          ]));
      verifyHeaders(args[i * 2 + 1]);
    }
  }

  void verifyCollectionRequest(int expectedPageNumber) {
    verifyCollectionRequests([expectedPageNumber]);
  }

  void verifyCollectionTotals() {
    expect(collection.totalItems, equals(5));
    expect(collection.totalPages, equals(3));
  }

  void verifyAlbumRequest(int albumId) {
    final args = verify(cache.getSingleFile(captureAny, headers: captureAnyNamed('headers'))).captured;
    expect(args[0], equals('https://api.discogs.com/releases/$albumId'));
    verifyHeaders(args[1]);
  }

  void setExceptionForMock(Exception exception) {
    when(cache.getSingleFile(any, headers: anyNamed('headers'))).thenThrow(exception);
  }

  Future<T> verifyThrows<T extends Exception>(Future<dynamic> Function() function) async {
    try {
      await function();
      fail('Exception not thrown on: $function');
    } on Exception catch (e) {
      expect(e, isA<T>());
      return Future.value(e as T);
    }
  }

  setUp(() {
    collection = Collection(userAgent);
    // mock cache manager
    initializeCollectionMockCache();
  });

  group('Discogs collection', () {
    test('loads the initial page for a valid username', () async {
      expect(collection.isEmpty, isTrue);
      expect(collection.isUserEmpty, isTrue);

      await collection.updateUsername(username);

      verifyCollectionRequest(1);

      expect(collection.albums.length, 2);
      expect(collection.isFullyLoaded, equals(false));
      verifyCollectionTotals();

      expect(collection.isEmpty, isFalse);
      expect(collection.isNotEmpty, isTrue);
      expect(collection.isUserEmpty, isFalse);

      verifyNoMoreCacheOperations();
    });

    test('loads the next page for a valid username', () async {
      // page 1
      await collection.updateUsername(username);
      verifyCollectionRequest(1);
      expect(collection.albums.length, 2);

      // page 2
      await collection.loadMoreAlbums();
      verifyCollectionRequest(2);
      expect(collection.albums.length, 4);
      expect(collection.isFullyLoaded, equals(false));
      verifyCollectionTotals();
    });

    test('loads the last page for a valid username', () async {
      expect(collection.nextPage, equals(1));
      expect(collection.hasMorePages, isFalse);

      // page 1
      await collection.updateUsername(username);
      verifyCollectionRequest(1);
      expect(collection.albums.length, 2);
      expect(collection.nextPage, equals(2));
      expect(collection.hasMorePages, isTrue);

      // page 2
      await collection.loadMoreAlbums();
      verifyCollectionRequest(2);
      expect(collection.albums.length, 4);
      expect(collection.nextPage, equals(3));
      expect(collection.hasMorePages, isTrue);

      // last page (3)
      await collection.loadMoreAlbums();
      verifyCollectionRequest(3);
      expect(collection.albums.length, 5);
      expect(collection.isFullyLoaded, isTrue);
      expect(collection.hasMorePages, isFalse);
      verifyCollectionTotals();
      verifyNoMoreCacheOperations();
    });

    test('loads all albums for a valid username (for search)', () async {
      // initialize
      await collection.updateUsername(username);
      verifyCollectionRequest(1);
      expect(collection.albums.length, 2);

      // load all
      await collection.loadAllAlbums();
      verifyCollectionRequests([2, 3]);
      expect(collection.albums.length, 5);
      expect(collection.isFullyLoaded, equals(true));
      verifyCollectionTotals();
      verifyNoMoreCacheOperations();
    });

    test('reloads albums for a valid username', () async {
      // initialize
      await collection.updateUsername(username);
      verifyCollectionRequest(1);
      expect(collection.albums.length, 2);
      verifyNever(Collection.cache.emptyCache());

      // load all
      await collection.loadAllAlbums();
      verifyCollectionRequests([2, 3]);
      expect(collection.albums.length, 5);
      expect(collection.isFullyLoaded, equals(true));
      verifyNever(Collection.cache.emptyCache());

      verifyNoMoreCacheOperations();

      initializeCollectionMockCache();

      // refresh
      await collection.reload(emptyCache: true);
      verifyCollectionRequest(1);
      expect(collection.albums.length, 2);
      expect(collection.isFullyLoaded, equals(false));
      verifyCollectionTotals();
      verify(Collection.cache.emptyCache()).called(1);

      verifyNoMoreCacheOperations();
    });

    test('search works', () async {
      // initialize
      await collection.updateUsername(username);
      verifyCollectionRequest(1);
      // load all
      await collection.loadAllAlbums();
      verifyCollectionRequests([2, 3]);
      expect(collection.isFullyLoaded, equals(true));

      // search
      var results = collection.search('cranberries');
      expect(results.length, equals(1));
      expect(results[0].id, 428475133);

      results = collection.search('blu');
      expect(results.length, equals(1));
      expect(results[0].id, 426578531);

      results = collection.search('blux');
      expect(results.length, equals(0));

      results = collection.search('bear grizzly vecka');
      expect(results.length, equals(1));
      expect(results[0].id, 32925711);

      results = collection.search('');
      expect(results.length, equals(5));

      results = collection.search('be');
      expect(results.length, equals(2));
      expect(results.map((album) => album.id), equals([428475133, 32925711]));

      verifyNoMoreCacheOperations();
    });

    test('search ignores accents and diacritical signs', () async {
      // initialize
      await collection.updateUsername(username);
      verifyCollectionRequest(1);
      // load all
      await collection.loadAllAlbums();
      verifyCollectionRequests([2, 3]);
      expect(collection.isFullyLoaded, equals(true));

      // search
      var results = collection.search('Chloé');
      expect(results.length, equals(1));
      expect(results[0].releaseId, 1287017);

      results = collection.search('chloe');
      expect(results.length, equals(1));
      expect(results[0].releaseId, 1287017);

      results = collection.search('chlöe');
      expect(results.length, equals(1));
      expect(results[0].releaseId, 1287017);

      results = collection.search('čråñbérrîës');
      expect(results.length, equals(1));
      expect(results[0].id, 428475133);

      verifyNoMoreCacheOperations();
    });
  });

  group('Discogs album', () {
    test('loads album details', () async {
      final album = await collection.loadAlbumDetails(249504);
      verifyAlbumRequest(249504);
      expect(album.releaseId, equals(249504));
      expect(album.artist, equals('Rick Astley'));
      expect(album.title, equals('Never Gonna Give You Up'));
      expect(album.tracks.length, equals(2));
      expect(album.tracks[0].position, equals('A'));
      expect(album.tracks[0].artist, isNull);
      expect(album.tracks[0].title, equals('Never Gonna Give You Up'));
      expect(album.tracks[0].duration, equals(3 * 60 + 32)); // '3:32'
      expect(album.tracks[1].position, equals('B'));
      expect(album.tracks[1].artist, isNull);
      expect(album.tracks[1].title, equals('Never Gonna Give You Up (Instrumental)'));
      expect(album.tracks[1].duration, equals(3 * 60 + 30)); // '3:30'
      verifyNoMoreCacheOperations();
    });

    test('loads album details with multiple artists', () async {
      final album = await collection.loadAlbumDetails(6895819);
      verifyAlbumRequest(6895819);
      expect(album.releaseId, equals(6895819));
      expect(album.artist, equals('Former Ghosts')); // first one picked
      expect(album.title, equals('Split'));
      expect(album.tracks.length, equals(4));
      expect(album.tracks[0].position, equals('A1'));
      expect(album.tracks[0].artist, equals('Former Ghosts'));
      expect(album.tracks[0].title, equals('Last Hour\'s Bow'));
      expect(album.tracks[0].duration, isNull);
      expect(album.tracks[1].position, equals('A2'));
      expect(album.tracks[1].artist, equals('Former Ghosts'));
      expect(album.tracks[1].title, equals('Past Selves'));
      expect(album.tracks[1].duration, isNull);
      expect(album.tracks[2].position, equals('B1'));
      expect(album.tracks[2].artist, equals('Funeral Advantage'));
      expect(album.tracks[2].title, equals('Wedding'));
      expect(album.tracks[2].duration, isNull);
      expect(album.tracks[3].position, equals('B2'));
      expect(album.tracks[3].artist, equals('Funeral Advantage'));
      expect(album.tracks[3].title, equals('I Know Him'));
      expect(album.tracks[3].duration, isNull);
      verifyNoMoreCacheOperations();
    });

    test('loads album details with subtracks', () async {
      final album = await collection.loadAlbumDetails(1287017);
      verifyAlbumRequest(1287017);
      expect(album.releaseId, equals(1287017));
      expect(album.tracks[2].title, equals('Rapsodie Espagnole'));

      final track3sub = album.tracks[2].subTracks!;
      expect(track3sub.length, 4);
      expect(track3sub[3].title, 'Feria');
      expect(track3sub[3].duration, equals(6 * 60 + 25)); // '6:25'
      expect(track3sub[3].position, equals('B3'));

      expect(album.tracks[3].subTracks!.length, 3);

      expect(album.tracks.length, equals(4));

      verifyNoMoreCacheOperations();
    });
  });

  group('Discogs error handling', () {
    test('throws UI exception on server error', () async {
      setExceptionForMock(const HttpExceptionWithStatus(400, ''));

      expect(collection.isLoading, isFalse);
      await verifyThrows<UIException>(() => collection.updateUsername('something-else'));
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);
      expect(collection.errorMessage, isNotNull);

      // allow one successful request to fill totalPages
      initializeCollectionMockCache();
      await collection.updateUsername(username);
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isFalse);
      expect(collection.errorMessage, isNull);

      setExceptionForMock(const HttpExceptionWithStatus(400, ''));

      await verifyThrows<UIException>(collection.loadMoreAlbums);
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);
      expect(collection.errorMessage, isNotNull);

      await verifyThrows<UIException>(collection.loadAllAlbums);
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);
      expect(collection.errorMessage, isNotNull);

      await verifyThrows<UIException>(collection.reload);
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);
      expect(collection.errorMessage, isNotNull);

      await verifyThrows<UIException>(() => collection.loadAlbumDetails(249504));
    });

    test('throws a different UI exception on 404 not found and 401 unauthorized', () async {
      setExceptionForMock(const HttpExceptionWithStatus(404, ''));

      final exception404 = await verifyThrows<UIException>(() => collection.updateUsername(username));
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);
      expect(collection.errorMessage, isNotNull);

      setExceptionForMock(const HttpExceptionWithStatus(401, ''));

      final exception401 = await verifyThrows<UIException>(() => collection.updateUsername(username));
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);
      expect(collection.errorMessage, isNotNull);

      setExceptionForMock(const HttpExceptionWithStatus(500, ''));

      final exception500 = await verifyThrows<UIException>(() => collection.reload());

      expect(exception404.message, isNot(equals(exception500.message)));
      expect(exception401.message, isNot(equals(exception500.message)));
      expect(exception404.message, isNot(equals(exception401.message)));
    });

    test('throws UI exception on network error', () async {
      setExceptionForMock(const SocketException(''));

      expect(collection.isLoading, isFalse);
      await verifyThrows<UIException>(() => collection.updateUsername('something-else'));
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);
      expect(collection.errorMessage, isNotNull);

      // allow one successful request to fill totalPages
      initializeCollectionMockCache();
      await collection.updateUsername(username);
      expect(collection.hasLoadingError, isFalse);
      expect(collection.errorMessage, isNull);

      setExceptionForMock(const SocketException(''));

      expect(collection.isLoading, isFalse);
      await verifyThrows<UIException>(collection.loadMoreAlbums);
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);
      expect(collection.errorMessage, isNotNull);

      expect(collection.isLoading, isFalse);
      await verifyThrows<UIException>(collection.loadAllAlbums);
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);
      expect(collection.errorMessage, isNotNull);

      expect(collection.isLoading, isFalse);
      await verifyThrows<UIException>(collection.reload);
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);
      expect(collection.errorMessage, isNotNull);

      setExceptionForMock(const SocketException(''));

      await verifyThrows<UIException>(() => collection.loadAlbumDetails(249504));
    });

    test('doesn\'t allow loading all albums before loading first page', () async {
      setExceptionForMock(const HttpExceptionWithStatus(401, ''));

      await verifyThrows<UIException>(() => collection.updateUsername(username));
      expect(collection.isEmpty, isTrue);
      expect(collection.isUserEmpty, isFalse);

      await verifyThrows<UIException>(collection.loadAllAlbums);
      expect(collection.isEmpty, isTrue);
      expect(collection.isLoading, isFalse);
    });

    test('bypasses the cache manager on file system error', () async {
      setExceptionForMock(const FileSystemException(''));

      when(fallbackClient.get(any, headers: anyNamed('headers'))).thenAnswer((_) => Future.value(http.Response(
          jsonForCollectionPageOneWithTwoAlbums, 200,
          headers: {HttpHeaders.contentTypeHeader: 'application/json'})));

      await collection.updateUsername(username);
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isFalse);
      expect(collection.albums.length, 2);

      await collection.reload();
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isFalse);
      expect(collection.albums.length, 2);

      final cacheCalls = verify(cache.getSingleFile(captureAny, headers: captureAnyNamed('headers')));
      cacheCalls.called(2);
      final fallbackCalls = verify(fallbackClient.get(captureAny, headers: captureAnyNamed('headers')));
      fallbackCalls.called(2);
      expect(cacheCalls.captured.map((e) => e.toString()), equals(fallbackCalls.captured.map((e) => e.toString())));

      when(fallbackClient.get(any, headers: anyNamed('headers'))).thenAnswer((_) => Future.value(
          http.Response(jsonForRelease, 200, headers: {HttpHeaders.contentTypeHeader: 'application/json'})));

      final album = await collection.loadAlbumDetails(249504);
      expect(album, isNotNull);

      verify(cache.getSingleFile(any, headers: anyNamed('headers')));
      verify(fallbackClient.get(any, headers: anyNamed('headers')));

      // reset mock cache
      initializeCollectionMockCache();

      await collection.reload();
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isFalse);
      expect(collection.albums.length, 2);

      verify(cache.getSingleFile(any, headers: anyNamed('headers')));
      verifyNever(fallbackClient.get(any, headers: anyNamed('headers')));
    });

    test('doesn\'t try to load collection if username is empty', () async {
      await collection.updateUsername(null);

      expect(collection.isUserEmpty, isTrue);

      await collection.loadMoreAlbums();
      await verifyThrows<UIException>(collection.loadAllAlbums);
      await verifyThrows<UIException>(collection.reload);

      verifyNoMoreCacheOperations();
    });

    test('doesn\'t try to load collection if it\'s already loading', () async {
      collection.loadingNotifier.value = LoadingStatus.loading;

      await collection.updateUsername(username);

      await collection.loadMoreAlbums();
      await collection.loadAllAlbums();
      await collection.reload();

      verifyNoMoreCacheOperations();
    });

    test('doesn\'t try to load collection if it\' already fully loaded', () async {
      await collection.updateUsername(username);
      await collection.loadAllAlbums();

      expect(collection.isFullyLoaded, isTrue);
      expect(collection.isNotFullyLoaded, isFalse);

      verifyCollectionRequests([1, 2, 3]);

      await collection.loadMoreAlbums();
      await collection.loadAllAlbums();

      verifyNoMoreCacheOperations();
    });

    test('doesn\'t reload collection if the username is updated to the same value', () async {
      await collection.updateUsername(username);

      verifyCollectionRequest(1);

      await collection.updateUsername(username);

      verifyNoMoreCacheOperations();
    });
  });
}
