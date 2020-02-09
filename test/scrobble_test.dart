import 'package:drs_app/model/discogs.dart';
import 'package:drs_app/model/lastfm.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

String _createScrobbleResponse(int accepted, int ignored) =>
    '{"scrobbles":{"@attr":{"accepted":$accepted,"ignored":$ignored},"scrobble":[${List.generate(accepted, (_) => '{}').join(',')}]}}';

void main() {
  group('Scrobbler', () {
    const userAgent = 'test user-agent';
    const username = 'test-user';
    const password = 'test-password';
    const key = 'd580d57f32848f5dcf574d1ce18d78b2';
    Scrobbler scrobbler;

    setUp(() {
      scrobbler = Scrobbler(userAgent);
      scrobbler.httpClient = null;
    });

    test('initializes a Last.fm session', () async {
      // override http client
      scrobbler.httpClient =
          MockClient(expectAsync1<Future<Response>, Request>((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.toString(),
            equals('https://ws.audioscrobbler.com/2.0/'));

        expect(request.bodyFields['method'], equals('auth.getMobileSession'));
        expect(request.bodyFields['username'], equals(username));
        expect(request.bodyFields['password'], equals(password));
        expect(request.headers['User-Agent'], equals(userAgent));

        return Response(
          '{ "session": { "name": "me", "key": "$key", "subscriber": 0 } }',
          200,
        );
      }, count: 1));

      // login
      final returnedKey = await scrobbler.initializeSession(username, password);
      expect(returnedKey, equals(key));
    });

    test('submits albums to Last.fm', () async {
      // set a key
      scrobbler.updateSessionKey('test-session-key');

      // generate list of albums to scrobble
      final albums = List.generate(
          20,
          (index) => AlbumDetails(
                releaseId: index,
                artist: 'Radiohead',
                title: 'OK Computer $index',
                tracks: [
                  AlbumTrack(title: 'Airbag', duration: '4:44'),
                  AlbumTrack(title: 'Paranoid Android', position: 'A2'),
                  AlbumTrack(title: 'Subterranean Homesick Alien', subTracks: [
                    AlbumTrack(title: 'Exit Music (For A Film)'),
                    AlbumTrack(title: 'Let Down'),
                  ]),
                ],
              ));

      // override http client
      scrobbler.httpClient =
          MockClient(expectAsync1<Future<Response>, Request>((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.toString(),
            equals('https://ws.audioscrobbler.com/2.0/'));
        final regexp = RegExp(r'^track\[[1-4]?[0-9]\]$');
        final trackKeys = request.bodyFields.keys.where(regexp.hasMatch);
        final tracks = trackKeys.length;

        var index = 0;
        for (var key in trackKeys) {
          expect(key, 'track[${index++}]');
        }

        return Response(_createScrobbleResponse(tracks - 1, 1), 200);
      }, count: 2));

      // scrobble
      final acceptedList = await scrobbler.scrobbleAlbums(albums).toList();
      expect(acceptedList, equals([49, 29]));
    });
  });
}
