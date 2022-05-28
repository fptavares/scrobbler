import 'package:scrobbler_bluos_monitor/src/playlist.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

import 'test_data.dart';

void main() {
  group('BluOS playlist', () {
    BluOSAPITrack createTrack(int pid, double length, double secs) => BluOSAPITrack(
          playId: '$pid',
          artist: 'artist$pid',
          album: 'album$pid',
          title: 'title$pid',
          imageUrl: 'image$pid',
          length: length,
          state: BluOSTrackState('etag$pid', 'play', secs),
        );

    test('ensures that tracks meet the requirements to be scrobbled', () {
      final playlist = BluOSPlaylistTracker();

      // long tracks are deemed scrobbable after 4 min
      final longTrack = createTrack(1, 1200, 240);
      expect(longTrack.isScrobbable, isTrue);

      playlist.addTrack(longTrack);
      expect(playlist.length, equals(1));
      expect(playlist.tracks.last, equals(longTrack));

      // status update for the same track doesn't create a duplicate
      playlist.addTrack(longTrack);
      expect(playlist.length, equals(1));

      // tracks listened to less than 50% of length are not kept in the playlist
      final notScrobbableTrack = createTrack(2, 240, 20);
      expect(notScrobbableTrack.isScrobbable, isFalse);

      playlist.addTrack(notScrobbableTrack);
      expect(playlist.length, equals(2));
      expect(playlist.tracks.last, equals(notScrobbableTrack));

      final scrobbableTrack = createTrack(3, 120, 60);
      expect(scrobbableTrack.isScrobbable, isTrue);

      playlist.addTrack(scrobbableTrack);
      expect(playlist.length, equals(2));
      expect(playlist.tracks.last, equals(scrobbableTrack));

      // tracks need to be longer than 30 seconds
      final tooShortTrack = createTrack(4, 30, 30);
      expect(tooShortTrack.isScrobbable, isFalse);

      playlist.addTrack(tooShortTrack);
      expect(playlist.length, equals(3));
      expect(playlist.tracks.last, equals(tooShortTrack));

      // last track is removed if not scrobbable when stopping
      playlist.stop();
      expect(playlist.length, equals(2));
      expect(playlist.tracks, equals([longTrack, scrobbableTrack]));
    });

    void verifyMatches(String trackXml, BluOSAPITrack expectedTrack) {
      final document = XmlDocument.parse(trackXml);
      final state = BluOSTrackState.fromXml(document);
      final track = BluOSAPITrack.fromXml(document, state, '');

      expect(expectedTrack.playId, equals(track.playId));
      expect(expectedTrack.artist, equals(track.artist));
      expect(expectedTrack.album, equals(track.album));
      expect(expectedTrack.title, equals(track.title));
      expect(expectedTrack.imageUrl, isIn(track.imageUrl));
      expect(expectedTrack.length, equals(track.length));
      expect(expectedTrack.state.etag, equals(track.state.etag));
      expect(expectedTrack.state.playerState, equals(track.state.playerState));
      expect(expectedTrack.state.seconds, equals(track.state.seconds));
    }

    test('supports local music', () => verifyMatches(localXml, localExpected));

    test('supports Qobuz', () => verifyMatches(qobuzXml, qobuzExpected));

    test('supports Tidal', () {
      verifyMatches(tidalXml, tidalExpected);
      verifyMatches(tidalRadioXml, tidalRadioExpected);
      verifyMatches(tidalConnectXml, tidalConnectExpected);
    });

    test('supports Spotify (Connect)', () => verifyMatches(spotifyConnectXml, spotifyConnectExpected));

    test('supports Radio Paradise', () => verifyMatches(radioParadiseXml, radioParadiseExpected));

    test('supports TuneIn', () => verifyMatches(tuneInXml, tuneInExpected));
  });
}
