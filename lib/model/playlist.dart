import 'package:flutter/foundation.dart';

import '../components/error.dart';
import 'discogs.dart';
import 'lastfm.dart';

class Playlist extends ChangeNotifier {
  final Map<int, PlaylistItem> _itemById = <int, PlaylistItem>{};
  bool _isScrobbling = false;

  int get numberOfItems => _itemById.length;

  bool get isEmpty => _itemById.isEmpty;

  bool get isNotEmpty => !isEmpty;

  bool get isScrobbling => _isScrobbling;

  List<PlaylistItem> getPlaylistItems() {
    return _itemById.values.toList();
  }

  Future<List<AlbumDetails>> _getAlbumsDetails(Collection collection) async {
    final albums = await Future.wait<AlbumDetails>(
        _itemById.keys.map(collection.getAlbumDetails));
    return albums
        .expand((album) =>
            List<AlbumDetails>.filled(_itemById[album.releaseId].count, album))
        .toList();
  }

  Stream<int> scrobble(Scrobbler scrobbler, Collection collection) async* {
    if (scrobbler.isNotAuthenticated) {
      throw UIException(
          'Oops! You need to login to Last.fm first with your username and password.');
    }
    if (_isScrobbling) {
      throw UIException(
          'Cannot scrobble again until the previous request is complete.');
    }
    _isScrobbling = true;
    notifyListeners();
    try {
      await for (final int accepted
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

  void clearZeroCountAlbums() {
    _itemById.removeWhere((_, item) => item.count == 0);
  }
}

class PlaylistItem extends ValueNotifier<int> {
  PlaylistItem(this.album) : super(1);

  CollectionAlbum album;

  int get count => value;

  void increase() {
    value++;
  }

  void decrease() {
    if (value > 0) {
      value--;
    }
  }
}
