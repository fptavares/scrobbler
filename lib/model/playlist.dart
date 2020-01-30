import 'package:drs_app/model/lastfm.dart';
import 'package:flutter/foundation.dart';

import 'discogs.dart';

class Playlist with ChangeNotifier {
  final Map<int, int> _countById = Map<int, int>();
  bool _isScrobbling = false;

  int get numberOfItems => _countById.length;

  bool get isEmpty => _countById.isEmpty;

  bool get isNotEmpty => !isEmpty;

  bool get isScrobbling => _isScrobbling;

  List<int> getReleaseIds() {
    return _countById.keys.toList();
  }

  Future<List<AlbumDetails>> getAlbums() async {
    List<AlbumDetails> albums = await Future.wait<AlbumDetails>(_countById.keys.map(Collection.getAlbumDetails));
    return albums.expand((album) => List.filled(_countById[album.releaseId], album)).toList();
  }

  Stream<int> scrobble(Scrobbler scrobbler) async* {
    if (_isScrobbling) {
      throw 'Cannot scrobble again until the previous request is complete.';
    }
    _isScrobbling = true;
    notifyListeners();
    try {
      await for (var accepted in scrobbler.scrobbleAlbums(await getAlbums())) {
        yield accepted;
      }
      _countById.clear();
    } finally {
      _isScrobbling = false;
      notifyListeners();
    }
  }

  void addAlbum(CollectionAlbum album) {
    _countById.update(
        album.releaseId, (current) => current + 1, ifAbsent: () => 1);
    notifyListeners();
    //album.notifyListeners();
  }

  void removeAlbum(CollectionAlbum album) {
    _countById.remove(album.releaseId);
    notifyListeners();
    //album.notifyListeners();
  }

  void clearAlbums() {
    _countById.clear();
    notifyListeners();
    //collection.notifyListeners();
  }

  int getCountForAlbum(CollectionAlbum album) {
    return _isScrobbling ? 0 : _countById[album.releaseId] ?? 0;
  }
}
