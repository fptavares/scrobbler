import 'package:fake_async/fake_async.dart';
import 'package:scrobbler_bluos_monitor/src/playlist.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

import 'bluos_test_data.dart';

void main() {
  group('BluOS playlist', () {
    BluOSAPITrack createTrack(int pid, double length, {double? initialPlaybackDuration}) => BluOSAPITrack(
          queuePosition: 'position$pid',
          artist: 'artist$pid',
          album: 'album$pid',
          title: 'title$pid',
          imageUrl: 'image$pid',
          length: length,
          initialPlaybackDuration: initialPlaybackDuration,
        );

    test('ensures that tracks meet the requirements to be scrobbled', () {
      FakeAsync().run((async) {
        final playlist = BluOSPlaylistTracker();

        // long tracks are deemed scrobbable after 4 min
        final longTrack = createTrack(1, 1200);
        expect(longTrack.isScrobbable, isFalse);

        playlist.updateWith(longTrack);
        expect(playlist.length, equals(1));
        expect(playlist.tracks.last, equals(longTrack));

        async.elapse(Duration(minutes: 2));
        expect(longTrack.isScrobbable, isFalse);

        // status update for the same track doesn't create a duplicate
        playlist.updateWith(longTrack);
        expect(playlist.length, equals(1));
        expect(longTrack.isScrobbable, isFalse);

        async.elapse(Duration(minutes: 2));
        expect(longTrack.isScrobbable, isTrue);

        // if initial playback duration is longer than the length, it should be ignored (happens is radios)
        final invalidPlaybackDurationTrack = createTrack(2, 180, initialPlaybackDuration: 181);
        expect(invalidPlaybackDurationTrack.isScrobbable, isFalse);

        playlist.updateWith(invalidPlaybackDurationTrack);
        expect(playlist.length, equals(2));
        expect(playlist.tracks.last, equals(invalidPlaybackDurationTrack));

        async.elapse(Duration(minutes: 1));
        expect(invalidPlaybackDurationTrack.isScrobbable, isFalse);

        // tracks listened to less than 50% of length are not kept in the playlist
        final notScrobbableTrack = createTrack(3, 240);
        expect(notScrobbableTrack.isScrobbable, isFalse);

        playlist.updateWith(notScrobbableTrack);
        expect(playlist.length, equals(2));
        expect(playlist.tracks.last, equals(notScrobbableTrack));

        async.elapse(Duration(minutes: 1));
        expect(notScrobbableTrack.isScrobbable, isFalse);

        // valid track should be kept and previous ones should have been removed
        final scrobbableTrack = createTrack(4, 120);
        expect(scrobbableTrack.isScrobbable, isFalse);

        playlist.updateWith(scrobbableTrack);
        expect(playlist.length, equals(2));
        expect(playlist.tracks.last, equals(scrobbableTrack));

        async.elapse(Duration(minutes: 1));
        expect(scrobbableTrack.isScrobbable, isTrue);

        // tracks picked up half way through have their current playback duration taken into account
        final halfwayTrack = createTrack(5, 90, initialPlaybackDuration: 45);
        expect(halfwayTrack.isScrobbable, isTrue);

        playlist.updateWith(halfwayTrack);
        expect(playlist.length, equals(3));
        expect(playlist.tracks.last, equals(halfwayTrack));

        // tracks need to be longer than 30 seconds
        final tooShortTrack = createTrack(6, 30);
        expect(tooShortTrack.isScrobbable, isFalse);

        playlist.updateWith(tooShortTrack);
        expect(playlist.length, equals(4));
        expect(playlist.tracks.last, equals(tooShortTrack));

        async.elapse(Duration(seconds: 30));
        expect(tooShortTrack.isScrobbable, isFalse);

        // last track is removed if not scrobbable when stopping
        playlist.stop();
        expect(playlist.length, equals(3));
        expect(playlist.tracks, equals([longTrack, scrobbableTrack, halfwayTrack]));
      });
    });

    void verifyMatches(String trackXml, BluOSAPITrack expectedTrack, BluOSPlayerState expectedState) {
      final document = XmlDocument.parse(trackXml);
      final state = BluOSPlayerState.fromXml(document);
      final track = BluOSAPITrack.fromXml(document, state, '');

      expect(expectedTrack.artist, equals(track.artist));
      expect(expectedTrack.album, equals(track.album));
      expect(expectedTrack.title, equals(track.title));
      expect(expectedTrack.imageUrl, isIn(track.imageUrl));
      expect(expectedTrack.length, equals(track.length));
      expect(expectedState.etag, equals(state.etag));
      expect(expectedState.playerState, equals(state.playerState));
      expect(expectedState.seconds, equals(state.seconds));
    }

    test('supports local music', () => verifyMatches(localXml, localExpected, localExpectedState));

    test('supports Qobuz', () => verifyMatches(qobuzXml, qobuzExpected, qobuzExpectedState));

    test('supports Tidal', () {
      verifyMatches(tidalXml, tidalExpected, tidalExpectedState);
      verifyMatches(tidalRadioXml, tidalRadioExpected, tidalRadioExpectedState);
      verifyMatches(tidalConnectXml, tidalConnectExpected, tidalConnectExpectedState);
    });

    test('supports Spotify (Connect)',
        () => verifyMatches(spotifyConnectXml, spotifyConnectExpected, spotifyConnectExpectedState));

    test('supports Radio Paradise',
        () => verifyMatches(radioParadiseXml, radioParadiseExpected, radioParadiseExpectedState));

    test('supports TuneIn', () => verifyMatches(tuneInXml, tuneInExpected, tuneInExpectedState));
  });
}
