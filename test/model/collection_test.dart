import 'dart:io';

import 'package:scrobbler/components/error.dart';
import 'package:scrobbler/model/discogs.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:scrobbler/secrets.dart';
import 'package:test/test.dart';

import 'collection_test_data.dart';

const userAgent = 'test user-agent';
const username = 'test_user';

void main() {
  group('Discogs collection', () {
    Collection collection;

    setUp(() {
      collection = Collection(userAgent);
      collection.httpClient = null;
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
      collection.httpClient = createPageMockClient(expectedHits: 1);

      await collection.updateUsername(username);
      expect(collection.albums.length, 2);
      expect(collection.isFullyLoaded, equals(false));
      verifyCollectionTotals();
    });

    test('loads the next page for a valid username', () async {
      collection.httpClient = createPageMockClient(expectedHits: 2);

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
      collection.httpClient = createPageMockClient(expectedHits: 3);

      // page 1
      await collection.updateUsername(username);
      expect(collection.albums.length, 2);

      // page 2
      await collection.loadMoreAlbums();
      expect(collection.albums.length, 4);

      // last page (3)
      await collection.loadMoreAlbums();
      expect(collection.albums.length, 5);
      expect(collection.isFullyLoaded, equals(true));
      verifyCollectionTotals();
    });

    test('loads all albums for a valid username (for search)', () async {
      collection.httpClient = createPageMockClient(expectedHits: 3);

      // initialize
      await collection.updateUsername(username);
      expect(collection.albums.length, 2);

      // load all
      await collection.loadAllAlbums();
      expect(collection.albums.length, 5);
      expect(collection.isFullyLoaded, equals(true));
      verifyCollectionTotals();
    });

    test('search works', () async {
      collection.httpClient = createPageMockClient(expectedHits: 3);

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

      results = collection.search('bear grizzly vecka');
      expect(results.length, equals(1));
      expect(results[0].id, 32925711);

      results = collection.search('');
      expect(results.length, equals(5));

      results = collection.search('be');
      expect(results.length, equals(2));
      expect(results.map((album) => album.id), equals([428475133, 32925711]));
    });

    test('loads album details', () async {
      collection.httpClient =
          MockClient(expectAsync1<Future<Response>, Request>((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.toString(),
            equals('https://api.discogs.com/releases/249504'));
        verifyCommonHeaders(request);

        return Response(jsonForRelease, 200, headers: {
          HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8'
        });
      }, count: 1));

      final album = await collection.getAlbumDetails(249504);
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
      collection.httpClient =
          MockClient(expectAsync1<Future<Response>, Request>((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.toString(),
            equals('https://api.discogs.com/releases/1287017'));
        verifyCommonHeaders(request);

        return Response(jsonForReleaseWithSubtracks, 200, headers: {
          HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8'
        });
      }, count: 1));

      final album = await collection.getAlbumDetails(1287017);
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

    Future<void> verifyThrows(Future<dynamic> function()) async {
      try {
        await function();
        fail('Exception not thrown on: $function');
      } on Exception catch (e) {
        expect(e, const TypeMatcher<UIException>());
      }
    }

    test('throws UI exception on server error', () async {
      collection.httpClient = createErrorMockClient(code: 400);

      expect(collection.isLoading, isFalse);
      await verifyThrows(() => collection.updateUsername('something-else'));
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);

      // allow one successful request to fill totalPages
      collection.httpClient = createPageMockClient(expectedHits: 1);
      await collection.updateUsername(username);

      collection.httpClient = createErrorMockClient(code: 400);

      expect(collection.isLoading, isFalse);
      await verifyThrows(collection.loadMoreAlbums);
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);

      expect(collection.isLoading, isFalse);
      await verifyThrows(collection.loadAllAlbums);
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);

      expect(collection.isLoading, isFalse);
      await verifyThrows(collection.reload);
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);

      collection.httpClient = MockClient((_) async => Response('', 400));

      await verifyThrows(() => collection.getAlbumDetails(249504));
    });

    test('throws UI exception on network error', () async {
      collection.httpClient =
          createErrorMockClient(exception: const SocketException(''));

      expect(collection.isLoading, isFalse);
      await verifyThrows(() => collection.updateUsername('something-else'));
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);

      // allow one successful request to fill totalPages
      collection.httpClient = createPageMockClient(expectedHits: 1);
      await collection.updateUsername(username);

      collection.httpClient =
          createErrorMockClient(exception: const SocketException(''));

      expect(collection.isLoading, isFalse);
      await verifyThrows(collection.loadMoreAlbums);
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);

      expect(collection.isLoading, isFalse);
      await verifyThrows(collection.loadAllAlbums);
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);

      expect(collection.isLoading, isFalse);
      await verifyThrows(collection.reload);
      expect(collection.isLoading, isFalse);
      expect(collection.hasLoadingError, isTrue);

      collection.httpClient =
          MockClient((_) async => throw const SocketException(''));

      await verifyThrows(() => collection.getAlbumDetails(249504));
    });

    test('doesn\'t try to load collection if username is empty', () async {
      collection.httpClient = EmptyMockHttpClient();

      await collection.updateUsername(null);

      await collection.loadMoreAlbums();
      await verifyThrows(collection.loadAllAlbums);
      await verifyThrows(collection.reload);

      verifyNever(collection.httpClient.get(anything));
    });

    test('doesn\'t try to load collection if it\'s already loading', () async {
      collection.httpClient = EmptyMockHttpClient();

      collection.loadingNotifier.value = LoadingStatus.loading;

      await collection.updateUsername(username);

      await collection.loadMoreAlbums();
      await collection.loadAllAlbums();
      await collection.reload();

      verifyNever(collection.httpClient.get(anything));
    });

    test('doesn\'t try to load collection if it\' already fully loaded',
        () async {
      collection.httpClient = createPageMockClient(expectedHits: 3);

      await collection.updateUsername(username);
      await collection.loadAllAlbums();

      expect(collection.isFullyLoaded, isTrue);
      expect(collection.isNotFullyLoaded, isFalse);

      collection.httpClient = EmptyMockHttpClient();

      await collection.loadMoreAlbums();
      await collection.loadAllAlbums();

      verifyNever(collection.httpClient.get(anything));
    });
  });
}

class EmptyMockHttpClient extends Mock implements Client {}
