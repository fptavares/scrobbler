import 'dart:io';

import 'package:file/local.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:flutter_cache_manager/src/web_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:scrobbler/components/error.dart';
import 'package:scrobbler/model/discogs.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:scrobbler/secrets.dart';
import 'package:sqflite/src/sqflite_impl.dart' as sqflite_impl;

import 'collection_test_data.dart';

const userAgent = 'test user-agent';
const username = 'test_user';

Future<void> main() async {
  final tempDir = await const LocalFileSystem()
      .systemTempDirectory
      .createTemp('scrobblerTest');
  final tempPath = tempDir.path;

  group('Discogs collection', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    Collection collection;

    setUpAll(() async {
      // mock platform channel for path provider
      PathProviderPlatform.instance =
          MockPathProviderPlatform(tempPath: tempPath);
      // mock platform channel for sqflite
      sqflite_impl.channel.setMockMethodCallHandler((call) async {
        switch (call.method) {
          case 'getDatabasesPath':
            return '/tmp/test';
          case 'openDatabase':
            return 0;
          default:
            return null;
        }
      });
      // mock platform channel for firebase performance
      FirebasePerformance.channel.setMockMethodCallHandler((methodCall) async {
        switch (methodCall.method) {
          case 'FirebasePerformance#isPerformanceCollectionEnabled':
            return false;
          default:
            return null;
        }
      });
    });

    tearDownAll(() {
      // delete temp files created for the tests
      tempDir.deleteSync(recursive: true);
    });

    setUp(() async {
      collection = Collection(userAgent);

      // mock cache manager
      final store = MockStore();
      final cachePath = await Collection.cache.getFilePath();
      when(store.filePath).thenAnswer((_) async => cachePath);
      Collection.cache.store = store;
      Collection.cache.webHelper =
          WebHelper(store, CacheManager.fetchFromServer);
    });

    void verifyCommonHeaders(Request request) {
      expect(request.headers['User-Agent'], equals(userAgent));
      expect(
          request.headers['Authorization'],
          equals(
              'Discogs key=$discogsConsumerKey, secret=$discogsConsumerSecret'));
    }

    Client createPageMockClient({int expectedHits}) {
      final pages = [
        jsonForCollectionPageOneWithTwoAlbums,
        jsonForCollectionPageTwoWithTwoAlbums,
        jsonForCollectionLastPageWithOneAlbum,
      ];
      return MockClient(
          expectAsync1<Future<Response>, Request>((request) async {
        expect(collection.isLoading, isTrue);
        expect(collection.isNotLoading, isFalse);
        expect(request.method, equals('GET'));
        expect(
          request.url.toString(),
          allOf([
            startsWith(
                'https://api.discogs.com/users/$username/collection/folders/0/releases'),
            contains('page=${4 - pages.length}')
          ]),
        );
        verifyCommonHeaders(request);

        return Response(pages.removeAt(0), 200);
      }, count: expectedHits));
    }

    MockClient createErrorMockClient({int code, Exception exception}) {
      return MockClient((_) async {
        expect(collection.isLoading, isTrue);
        expect(collection.isNotLoading, isFalse);
        if (exception != null) {
          throw exception;
        } else {
          return Response('', code ?? 400);
        }
      });
    }

    void verifyCollectionTotals() {
      expect(collection.totalItems, equals(5));
      expect(collection.totalPages, equals(3));
    }

    test('loads the initial page for a valid username', () async {
      Collection.innerHttpClient = createPageMockClient(expectedHits: 1);

      expect(collection.isEmpty, isTrue);
      expect(collection.isUserEmpty, isTrue);

      await collection.updateUsername(username);
      expect(collection.albums.length, 2);
      expect(collection.isFullyLoaded, equals(false));
      verifyCollectionTotals();

      expect(collection.isEmpty, isFalse);
      expect(collection.isNotEmpty, isTrue);
      expect(collection.isUserEmpty, isFalse);
    });

    test('loads the next page for a valid username', () async {
      Collection.innerHttpClient = createPageMockClient(expectedHits: 2);

      // page 1
      await collection.updateUsername(username);
      expect(collection.albums.length, 2);

      // page 2
      await collection.loadMoreAlbums();
      expect(collection.albums.length, 4);
      expect(collection.isFullyLoaded, equals(false));
      verifyCollectionTotals();
    });

    test('loads the last page for a valid username', () async {
      Collection.innerHttpClient = createPageMockClient(expectedHits: 3);

      expect(collection.nextPage, equals(1));
      expect(collection.hasMorePages, isFalse);

      // page 1
      await collection.updateUsername(username);
      expect(collection.albums.length, 2);
      expect(collection.nextPage, equals(2));
      expect(collection.hasMorePages, isTrue);

      // page 2
      await collection.loadMoreAlbums();
      expect(collection.albums.length, 4);
      expect(collection.nextPage, equals(3));
      expect(collection.hasMorePages, isTrue);

      // last page (3)
      await collection.loadMoreAlbums();
      expect(collection.albums.length, 5);
      expect(collection.isFullyLoaded, isTrue);
      expect(collection.hasMorePages, isFalse);
      verifyCollectionTotals();
    });

    test('loads all albums for a valid username (for search)', () async {
      Collection.innerHttpClient = createPageMockClient(expectedHits: 3);

      // initialize
      await collection.updateUsername(username);
      expect(collection.albums.length, 2);

      // load all
      await collection.loadAllAlbums();
      expect(collection.albums.length, 5);
      expect(collection.isFullyLoaded, equals(true));
      verifyCollectionTotals();
    });

    test('reloads albums for a valid username', () async {
      Collection.innerHttpClient = createPageMockClient(expectedHits: 3);

      // initialize
      await collection.updateUsername(username);
      expect(collection.albums.length, 2);
      verifyNever(Collection.cache.store.emptyCache());

      // load all
      await collection.loadAllAlbums();
      expect(collection.albums.length, 5);
      expect(collection.isFullyLoaded, equals(true));
      verifyNever(Collection.cache.store.emptyCache());

      Collection.innerHttpClient = createPageMockClient(expectedHits: 1);

      // refresh
      await collection.reload(emptyCache: true);
      expect(collection.albums.length, 2);
      expect(collection.isFullyLoaded, equals(false));
      verifyCollectionTotals();
      verify(Collection.cache.store.emptyCache()).called(1);
    });

    test('search works', () async {
      Collection.innerHttpClient = createPageMockClient(expectedHits: 3);

      // initialize
      await collection.updateUsername(username);
      // load all
      await collection.loadAllAlbums();
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
    });

    test('search ignores accents and diacritical signs', () async {
      Collection.innerHttpClient = createPageMockClient(expectedHits: 3);

      // initialize
      await collection.updateUsername(username);
      // load all
      await collection.loadAllAlbums();
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
    });

    test('loads album details', () async {
      Collection.innerHttpClient =
          MockClient(expectAsync1<Future<Response>, Request>((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.toString(),
            equals('https://api.discogs.com/releases/249504'));
        verifyCommonHeaders(request);

        return Response(jsonForRelease, 200, headers: {
          HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8'
        });
      }, count: 1));

      final album = await collection.loadAlbumDetails(249504);
      expect(album.releaseId, equals(249504));
      expect(album.artist, equals('Rick Astley'));
      expect(album.title, equals('Never Gonna Give You Up'));
      expect(album.tracks.length, equals(2));
      expect(album.tracks[0].position, equals('A'));
      expect(album.tracks[0].title, equals('Never Gonna Give You Up'));
      expect(album.tracks[0].duration, equals('3:32'));
      expect(album.tracks[1].position, equals('B'));
      expect(album.tracks[1].title,
          equals('Never Gonna Give You Up (Instrumental)'));
      expect(album.tracks[1].duration, equals('3:30'));
    });

    test('loads album details with subtracks', () async {
      Collection.innerHttpClient =
          MockClient(expectAsync1<Future<Response>, Request>((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.toString(),
            equals('https://api.discogs.com/releases/1287017'));
        verifyCommonHeaders(request);

        return Response(jsonForReleaseWithSubtracks, 200, headers: {
          HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8'
        });
      }, count: 1));

      final album = await collection.loadAlbumDetails(1287017);
      expect(album.releaseId, equals(1287017));
      expect(album.tracks[2].title, equals('Rapsodie Espagnole'));

      final track3sub = album.tracks[2].subTracks;
      expect(track3sub.length, 4);
      expect(track3sub[3].title, 'Feria');
      expect(track3sub[3].duration, equals('6:25'));
      expect(track3sub[3].position, equals('B3'));

      expect(album.tracks[3].subTracks.length, 3);

      expect(album.tracks.length, equals(4));
    });

    Future<T> verifyThrows<T extends Exception>(
        Future<dynamic> function()) async {
      try {
        await function();
        fail('Exception not thrown on: $function');
      } on Exception catch (e) {
        expect(e, isA<T>());
        return e;
      }
    }

    test('throws UI exception on server error', () async {
      Collection.innerHttpClient = createErrorMockClient(code: 400);

      expect(collection.isLoading, isFalse);
      await verifyThrows<UIException>(
          () => collection.updateUsername('something-else'));
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);
      expect(collection.errorMessage, isNotNull);

      // allow one successful request to fill totalPages
      Collection.innerHttpClient = createPageMockClient(expectedHits: 1);
      await collection.updateUsername(username);
      expect(collection.hasLoadingError, isFalse);
      expect(collection.errorMessage, isNull);

      Collection.innerHttpClient = createErrorMockClient(code: 400);

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

      Collection.innerHttpClient = MockClient((_) async => Response('', 400));

      await verifyThrows<UIException>(
          () => collection.loadAlbumDetails(249504));
    });

    test('throws a different UI exception on 404 not found', () async {
      Collection.innerHttpClient = createErrorMockClient(code: 404);

      final exception404 = await verifyThrows<UIException>(
          () => collection.updateUsername(username));
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);
      expect(collection.errorMessage, isNotNull);

      Collection.innerHttpClient = createErrorMockClient(code: 500);

      final exception500 =
          await verifyThrows<UIException>(() => collection.reload());

      expect(exception404.message, isNot(equals(exception500.message)));
    });

    test('throws UI exception on network error', () async {
      Collection.innerHttpClient =
          createErrorMockClient(exception: const SocketException(''));

      expect(collection.isLoading, isFalse);
      await verifyThrows<UIException>(
          () => collection.updateUsername('something-else'));
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);
      expect(collection.errorMessage, isNotNull);

      // allow one successful request to fill totalPages
      Collection.innerHttpClient = createPageMockClient(expectedHits: 1);
      await collection.updateUsername(username);
      expect(collection.hasLoadingError, isFalse);
      expect(collection.errorMessage, isNull);

      Collection.innerHttpClient =
          createErrorMockClient(exception: const SocketException(''));

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

      Collection.innerHttpClient =
          MockClient((_) async => throw const SocketException(''));

      await verifyThrows<UIException>(
          () => collection.loadAlbumDetails(249504));
    });

    test('doesn\'t allow loading all albums before loading first page',
        () async {
      Collection.innerHttpClient = createErrorMockClient(code: 401);

      await verifyThrows<UIException>(
          () => collection.updateUsername(username));

      expect(collection.isEmpty, isTrue);
      expect(collection.isUserEmpty, isFalse);

      await verifyThrows<UIException>(collection.loadAllAlbums);
      expect(collection.isEmpty, isTrue);
      expect(collection.isLoading, isFalse);
    });

    test('bypasses the cache manager on file system error', () async {
      when(Collection.cache.store.retrieveCacheData(any))
          .thenThrow(const FileSystemException(''));

      Collection.innerHttpClient = createPageMockClient(expectedHits: 3);

      await collection.updateUsername(username);
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isFalse);
      expect(collection.albums.length, 2);

      await collection.loadMoreAlbums();
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isFalse);
      expect(collection.albums.length, 4);

      await collection.loadAllAlbums();
      expect(collection.hasLoadingError, isFalse);
      expect(collection.albums.length, 5);

      Collection.innerHttpClient = createPageMockClient(expectedHits: 1);

      await collection.reload();
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isFalse);
      expect(collection.albums.length, 2);

      Collection.innerHttpClient = MockClient(
          expectAsync1<Future<Response>, Request>(
              (request) async => Response(jsonForRelease, 200,
                  headers: {HttpHeaders.contentTypeHeader: 'application/json'}),
              count: 1));

      final album = await collection.loadAlbumDetails(249504);
      expect(album, isNotNull);
    });

    test('doesn\'t try to load collection if username is empty', () async {
      Collection.innerHttpClient = EmptyMockHttpClient();

      await collection.updateUsername(null);

      expect(collection.isUserEmpty, isTrue);

      await collection.loadMoreAlbums();
      await verifyThrows<UIException>(collection.loadAllAlbums);
      await verifyThrows<UIException>(collection.reload);

      verifyNever(Collection.innerHttpClient.get(anything));
    });

    test('doesn\'t try to load collection if it\'s already loading', () async {
      Collection.innerHttpClient = EmptyMockHttpClient();

      collection.loadingNotifier.value = LoadingStatus.loading;

      await collection.updateUsername(username);

      await collection.loadMoreAlbums();
      await collection.loadAllAlbums();
      await collection.reload();

      verifyNever(Collection.innerHttpClient.get(anything));
    });

    test('doesn\'t try to load collection if it\' already fully loaded',
        () async {
      Collection.innerHttpClient = createPageMockClient(expectedHits: 3);

      await collection.updateUsername(username);
      await collection.loadAllAlbums();

      expect(collection.isFullyLoaded, isTrue);
      expect(collection.isNotFullyLoaded, isFalse);

      Collection.innerHttpClient = EmptyMockHttpClient();

      await collection.loadMoreAlbums();
      await collection.loadAllAlbums();

      verifyNever(Collection.innerHttpClient.get(anything));
    });

    test(
        'doesn\'t reload collection if the username is updated to the same value',
        () async {
      Collection.innerHttpClient = createPageMockClient(expectedHits: 1);

      await collection.updateUsername(username);

      Collection.innerHttpClient = EmptyMockHttpClient();

      await collection.updateUsername(username);

      verifyNever(Collection.innerHttpClient.get(anything));
    });
  });
}

class EmptyMockHttpClient extends Mock implements Client {}

class MockStore extends Mock implements CacheStore {}

class MockWebHelper extends Mock implements WebHelper {}

class MockPathProviderPlatform extends Mock
    with
        MockPlatformInterfaceMixin // ignore: prefer_mixin
    implements
        PathProviderPlatform {
  MockPathProviderPlatform({@required this.tempPath});

  final String tempPath;

  @override
  Future<String> getTemporaryPath() async => tempPath;
}
