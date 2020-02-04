import 'package:drs_app/model/lastfm.dart';
import 'package:flutter/foundation.dart';

import 'discogs.dart';

class Playlist with ChangeNotifier {
  final Map<int, PlaylistItem> _itemById = Map<int, PlaylistItem>();
  bool _isScrobbling = false;

  int get numberOfItems => _itemById.length;

  bool get isEmpty => _itemById.isEmpty;

  bool get isNotEmpty => !isEmpty;

  bool get isScrobbling => _isScrobbling;

  List<PlaylistItem> getPlaylistItems() {
    return _itemById.values.toList();
  }

  List<int> getReleaseIds() {
    return _itemById.keys.toList();
  }

  Future<List<AlbumDetails>> _getAlbumsDetails(Collection collection) async {
    List<AlbumDetails> albums = await Future.wait<AlbumDetails>(
        _itemById.keys.map(collection.getAlbumDetails));
    return albums
        .expand((album) => List.filled(_itemById[album.releaseId].count, album))
        .toList();
  }

  Stream<int> scrobble(Scrobbler scrobbler, Collection collection) async* {
    if (scrobbler.isNotAuthenticated) {
      throw 'Oops! You need to login to Last.fm first with your username and password.';
    }
    if (_isScrobbling) {
      throw 'Cannot scrobble again until the previous request is complete.';
    }
    _isScrobbling = true;
    notifyListeners();
    try {
      await for (var accepted
          in scrobbler.scrobbleAlbums(await _getAlbumsDetails(collection))) {
        yield accepted;
      }
      clearAlbums();
    } finally {
      _isScrobbling = false;
      notifyListeners();
    }
  }

  void addAlbum(CollectionAlbum album) {
    _itemById.update(album.releaseId, (current) => current..increase(),
        ifAbsent: () => PlaylistItem(album));
    notifyListeners();
  }

  void removeAlbum(CollectionAlbum album) {
    _itemById.remove(album.releaseId);
    notifyListeners();
  }

  void clearAlbums() {
    _itemById.clear();
    notifyListeners();
  }

  PlaylistItem getPlaylistItem(CollectionAlbum album) {
    return _isScrobbling ? null : _itemById[album.releaseId];
  }
}

class PlaylistItem extends ValueNotifier<int> {
  CollectionAlbum album;

  PlaylistItem(this.album) : super(1);

  int get count => value;

  increase() {
    value++;
  }

  decrease() {
    if (value > 0) value--;
  }
}
