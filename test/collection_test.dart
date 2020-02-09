import 'dart:io';

import 'package:drs_app/model/discogs.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
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

    test('loads the initial page for a valid username', () async {
      collection.httpClient = createPageMockClient(expectedHits: 1);

      await collection.updateUsername(username);
      expect(collection.albums.length, 2);
      expect(collection.isFullyLoaded, equals(false));
      verifyCollectionTotals(collection);
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
      verifyCollectionTotals(collection);
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
      verifyCollectionTotals(collection);
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
      verifyCollectionTotals(collection);
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
  });
}

Client createPageMockClient({int expectedHits}) {
  final pages = [
    jsonForCollectionPageOneWithTwoAlbums,
    jsonForCollectionPageTwoWithTwoAlbums,
    jsonForCollectionLastPageWithOneAlbum,
  ];
  return MockClient(expectAsync1<Future<Response>, Request>((request) async {
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

void verifyCollectionTotals(Collection collection) {
  expect(collection.totalItems, equals(5));
  expect(collection.totalPages, equals(3));
}

void verifyCommonHeaders(Request request) {
  expect(request.headers['User-Agent'], equals(userAgent));
  expect(request.headers['Authorization'],
      matches(r'Discogs key=\w+, secret=\w+'));
}
