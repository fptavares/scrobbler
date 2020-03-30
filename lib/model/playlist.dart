import 'dart:math';

import 'package:flutter/foundation.dart';

import '../components/error.dart';
import 'discogs.dart';
import 'lastfm.dart';

enum ScrobblingStatus { idle, active, paused }

class Playlist extends ChangeNotifier {
  final Map<int, PlaylistItem> _itemById = <int, PlaylistItem>{};
  var _status = ScrobblingStatus.idle;

  int get numberOfItems => _itemById.length;

  bool get isEmpty => _itemById.isEmpty;

  bool get isNotEmpty => !isEmpty;

  bool get isScrobbling => _status != ScrobblingStatus.idle;

  bool get isScrobblingPaused => _status == ScrobblingStatus.paused;

  List<PlaylistItem> getPlaylistItems() {
    return _itemById.values.toList();
  }

  Future<List<AlbumDetails>> _getAlbumsDetails(Collection collection) async {
    final albums = await Future.wait<AlbumDetails>(
        _itemById.keys.map(collection.loadAlbumDetails));
    return albums
        .expand((album) =>
            List<AlbumDetails>.filled(_itemById[album.releaseId].count, album))
        .toList();
  }

  Stream<int> scrobble(
      Scrobbler scrobbler,
      Collection collection,
      Future<ScrobbleOptions> requestOptions(
          List<AlbumDetails> albums)) async* {
    if (scrobbler.isNotAuthenticated) {
      throw UIException(
          'Oops! You need to login to Last.fm first with your username and password.');
    }
    if (isScrobbling) {
      throw UIException(
          'Cannot scrobble again until the previous request is complete.');
    }
    _status = ScrobblingStatus.active;
    notifyListeners();
    try {
      final albums = await _getAlbumsDetails(collection);

      _status = ScrobblingStatus.paused;
      notifyListeners();

      final options = await requestOptions(albums);
      if (options == null) {
        return;
      }

      _status = ScrobblingStatus.active;
      notifyListeners();

      await for (final int accepted in scrobbler.scrobbleAlbums(albums, options)) {
        yield accepted;
      }
      clearAlbums();
    } finally {
      _status = ScrobblingStatus.idle;
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
    return isScrobbling ? null : _itemById[album.releaseId];
  }

  void clearZeroCountAlbums() {
    _itemById.removeWhere((_, item) => item.count == 0);
  }

  int maxItemCount() {
    if (_itemById.isEmpty) {
      return 0;
    }
    return _itemById.values.map((item) => item.count).reduce(max);
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
