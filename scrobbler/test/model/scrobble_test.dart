import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:scrobbler/components/error.dart';
import 'package:scrobbler/model/lastfm.dart';

import '../bluos_test_data.dart';
import '../discogs_test_data.dart';

String _createScrobbleResponse(int accepted, int ignored) =>
    '{"scrobbles":{"@attr":{"accepted":$accepted,"ignored":$ignored},"scrobble":[${List.generate(accepted, (_) => '{}').join(',')}]}}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Last.fm client', () {
    const userAgent = 'test user-agent';
    const username = 'test-user';
    const password = 'test-password';
    const key = 'd580d57f32848f5dcf574d1ce18d78b2';

    test('initializes a Last.fm session', () async {
      final scrobbler = Scrobbler(userAgent);
      // override http client
      scrobbler.httpClient = MockClient(expectAsync1<Future<Response>, Request>((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.toString(), equals('https://ws.audioscrobbler.com/2.0/'));

        expect(request.bodyFields['method'], equals('auth.getMobileSession'));
        expect(request.bodyFields['username'], equals(username));
        expect(request.bodyFields['password'], equals(password));
        expect(request.headers['User-Agent'], equals(userAgent));

        return Response(
          '{ "session": { "name": "me", "key": "$key", "subscriber": 0 } }',
          200,
        );
      }, count: 1));

      expect(scrobbler.isNotAuthenticated, isTrue);

      // login
      final returnedKey = await scrobbler.initializeSession(username, password);
      expect(returnedKey, equals(key));

      expect(scrobbler.isNotAuthenticated, isFalse);
    });

    test('submits more than 50 tracks to Last.fm with exclusions but no offset', () async {
      final scrobbler = Scrobbler(userAgent);
      // set a key
      scrobbler.updateSessionKey('test-session-key');

      // generate list of albums to scrobble
      final albums = List.generate(20, (index) => testAlbumDetails1);

      // inclusion mask
      const mask = {
        16: {0: false, 2: true},
        18: {2: false}, // this is an index track with 2 sub-tracks
        19: {1: true},
      };

      // expected timestamp ranges
      final now = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
      final endTime = now - 60; // minus duration of the last track played
      final startTime = endTime -
          20 * testAlbumDetails1DurationInSeconds +
          (4 * 60 + 44) +
          2 * 60; // 20 times the album minus 3 excluded tracks

      // override http client
      scrobbler.httpClient = MockClient(expectAsync1<Future<Response>, Request>((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.toString(), equals('https://ws.audioscrobbler.com/2.0/'));
        final regexp = RegExp(r'^track\[[1-4]?[0-9]\]$');
        final trackKeys = request.bodyFields.keys.where(regexp.hasMatch);
        final tracks = trackKeys.length;

        var index = 0;
        for (var key in trackKeys) {
          // expect that the tracks use the correct index
          expect(key, equals('track[$index]'));
          // expect the timestamp to be in the range from now beck to total duration of playlist
          // 2 second delta to account for the test running on a slower platform
          expect(int.parse(request.bodyFields['timestamp[$index]']!), inInclusiveRange(startTime - 2, endTime + 2));

          index++;
        }

        return Response(_createScrobbleResponse(tracks - 1, 1), 200);
      }, count: 2));

      // scrobble
      final acceptedList = await scrobbler
          .scrobbleAlbums(albums, const ScrobbleOptions(inclusionMask: mask, offsetInSeconds: 0))
          .toList();
      expect(acceptedList, equals([50 - 1, 30 - 1 - 3]));
    });

    test('submit a single album to Last.fm with a 4 hour offset', () async {
      const offset = 240 * 60; // 4 hour offset

      final scrobbler = Scrobbler(userAgent);
      // set a key
      scrobbler.updateSessionKey('test-session-key');

      // list of albums to scrobble
      final albums = [testAlbumDetails1];

      // expected timestamp for the most recent track submitted
      final now = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
      final endTime = now - offset - 60; // last track is 60 seconds (default)
      final startTime = now - offset - testAlbumDetails1DurationInSeconds;

      // override http client
      scrobbler.httpClient = MockClient(expectAsync1<Future<Response>, Request>((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.toString(), equals('https://ws.audioscrobbler.com/2.0/'));
        final regexp = RegExp(r'^track\[[1-4]?[0-9]\]$');
        final trackKeys = request.bodyFields.keys.where(regexp.hasMatch);
        final tracks = trackKeys.length;

        var index = 0;
        for (var key in trackKeys) {
          expect(key, 'track[${index++}]');
        }

        // expect first timestamp to be close to the expected end time
        // 2 second delta to account for the test running on a slower platform
        expect(int.parse(request.bodyFields['timestamp[0]']!), closeTo(endTime, 2));
        // expect last timestamp to be close to the expected start time
        // 2 second delta to account for the test running on a slower platform
        expect(int.parse(request.bodyFields['timestamp[${tracks - 1}]']!), closeTo(startTime, 2));

        return Response(_createScrobbleResponse(tracks, 0), 200);
      }, count: 1));

      // scrobble
      final acceptedList = await scrobbler
          .scrobbleAlbums(albums, const ScrobbleOptions(inclusionMask: {}, offsetInSeconds: offset))
          .toList();
      expect(acceptedList, equals([4]));
    });

    test('submit BluOS tracks to Last.fm', () async {
      final scrobbler = Scrobbler(userAgent);
      // set a key
      scrobbler.updateSessionKey('test-session-key');

      // list of tracks to scrobble
      final tracks = BluOSTestData.listOfBluOSMonitorTracks.sublist(0, 2);

      // override http client
      scrobbler.httpClient = MockClient(expectAsync1<Future<Response>, Request>((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.toString(), equals('https://ws.audioscrobbler.com/2.0/'));

        var index = 0;
        for (final track in tracks) {
          expect(request.bodyFields['timestamp[$index]'], track.timestamp.toString());
          expect(request.bodyFields['artist[$index]'], track.artist);
          expect(request.bodyFields['album[$index]'], track.album);
          expect(request.bodyFields['track[$index]'], track.title);
          index++;
        }

        return Response(_createScrobbleResponse(1, 0), 200);
      }, count: 1));

      // scrobble
      final acceptedList = await scrobbler.scrobbleBluOSTracks(tracks).toList();
      expect(acceptedList, equals([1]));
    });

    Future<void> verifyThrows(Future<dynamic> Function() function, [String? messageContainsText]) async {
      try {
        await function();
        fail('Exception not thrown on: $function');
      } on Exception catch (e) {
        expect(e, isA<UIException>());
        if (messageContainsText != null && e is UIException) {
          expect(e.message, contains('authentication failed'));
        }
      }
    }

    test('throws UI exception on Last.fm authentication error', () async {
      final scrobbler = Scrobbler(userAgent);
      scrobbler.httpClient = MockClient((_) async => Response('{ "error": 4 }', 300));

      await verifyThrows(() => scrobbler.initializeSession(username, password));

      scrobbler.updateSessionKey(key);
      await verifyThrows(() async => await scrobbler.scrobbleAlbums([testAlbumDetails1]).toList());
    });

    test('throws UI exception on server error', () async {
      final scrobbler = Scrobbler(userAgent);
      scrobbler.httpClient = MockClient((_) async => Response('', 500));

      await verifyThrows(() => scrobbler.initializeSession(username, password));

      scrobbler.updateSessionKey(key);
      await verifyThrows(() async => await scrobbler.scrobbleAlbums([testAlbumDetails1]).toList());
    });

    test('throws UI exception on no connection error', () async {
      final scrobbler = Scrobbler(userAgent);
      scrobbler.httpClient = MockClient((_) async => throw const SocketException(''));

      await verifyThrows(() => scrobbler.initializeSession(username, password));

      scrobbler.updateSessionKey(key);
      await verifyThrows(() async => await scrobbler.scrobbleAlbums([testAlbumDetails1]).toList());
    });

    test('throws UI exception if album list is empty', () async {
      final scrobbler = Scrobbler(userAgent);
      scrobbler.httpClient = MockClient((_) async => Response(_createScrobbleResponse(1, 1), 200));

      scrobbler.updateSessionKey(key);
      await verifyThrows(() async => await scrobbler.scrobbleAlbums([]).toList());
      await verifyThrows(() async => await scrobbler.scrobbleBluOSTracks([]).toList());
    });

    test('throws UI exception if session key is empty', () async {
      final scrobbler = Scrobbler(userAgent);
      scrobbler.httpClient = MockClient((_) async => Response(_createScrobbleResponse(1, 1), 200));

      await verifyThrows(() async => await scrobbler.scrobbleAlbums([testAlbumDetails1]).toList());
      await verifyThrows(() async => await scrobbler.scrobbleBluOSTracks([]).toList());
    });
  });
}
