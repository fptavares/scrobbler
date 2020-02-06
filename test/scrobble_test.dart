import 'package:drs_app/model/discogs.dart';
import 'package:drs_app/model/lastfm.dart';
import 'package:test/test.dart';


void main() {

  test('scrobble() works', () async {
    final albums = List.generate(20, (index) => AlbumDetails(
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

    final scrobbler = Scrobbler('');
    scrobbler.httpClient = null;
    return scrobbler.scrobbleAlbums(albums);
  }, skip: true);

  
}