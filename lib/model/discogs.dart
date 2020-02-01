import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../secrets.dart';

class CollectionAlbum {
  final int id;
  final int releaseId;
  final String artist;
  final String title;
  final int year;
  final String thumbURL;
  final int rating;
  final String dateAdded;
  String searchString;

  CollectionAlbum(
      {this.id,
      this.releaseId,
      this.artist,
      this.title,
      this.year,
      this.thumbURL,
      this.rating,
      this.dateAdded}) {
    searchString = '$artist $title'.toLowerCase();
  }

  factory CollectionAlbum.fromJson(Map<String, dynamic> release) {
    final info = release['basic_information'];
    return CollectionAlbum(
      id: release['instance_id'],
      releaseId: release['id'],
      artist: _getSingleNameFromArtists(info['artists']),
      title: info['title'],
      year: info['year'],
      thumbURL: info['thumb'],
      rating: release['rating'],
      dateAdded: release['date_added'],
    );
  }

  @override
  String toString() {
    return '$id: $title ($year) by $artist';
  }
}

class AlbumDetails {
  int releaseId;
  String artist;
  String title;
  List<AlbumTrack> tracks;

  AlbumDetails({
    this.releaseId,
    @required this.artist,
    @required this.title,
    @required this.tracks,
  });

  factory AlbumDetails.fromJson(Map<String, dynamic> release) {
    return AlbumDetails(
      releaseId: release['id'],
      artist: _getSingleNameFromArtists(release['artists']),
      title: release['title'],
      tracks: release['tracklist']
          .map<AlbumTrack>((track) => AlbumTrack.fromJson(track))
          .toList(),
    );
  }
}

class AlbumTrack {
  final String title;
  final String position;
  final String duration;
  final String artist;
  final List<AlbumTrack> subTracks;

  AlbumTrack({
    @required this.title,
    this.position,
    this.duration,
    this.artist,
    this.subTracks,
  });

  factory AlbumTrack.fromJson(Map<String, dynamic> track) {
    return AlbumTrack(
      title: track['title'],
      position: track['position'],
      duration: track['duration'],
      artist: _getSingleNameFromArtists(track['artists']),
      subTracks: track['sub_tracks']
          ?.map<AlbumTrack>((subTrack) => AlbumTrack.fromJson(subTrack))
          ?.toList(),
    );
  }
}

class Collection with ChangeNotifier {
  String _username;
  List<CollectionAlbum> _albumList = [];

  final Loading _loading = Loading(false);

  //bool _isLoading = false;
  int _nextPage = 1;
  int _totalItems;
  int _totalPages;

  Loading get loadingNotifier => _loading;

  bool get isLoading => _loading.value;

  bool get isNotLoading => !_loading.value;

  bool get _isLoading => _loading.value;

  bool get isEmpty => _albumList.isEmpty;

  bool get isUserEmpty => _username == null;

  bool get isFullyLoaded => _nextPage > 1 && _nextPage > _totalPages;

  bool get isNotFullyLoaded => !isFullyLoaded;

  set _isLoading(newValue) => _loading.value = newValue;

  int get totalItems => _totalItems;

  int get totalPages => _totalPages;

  List<CollectionAlbum> get albums => _albumList;

  void _clearAlbums() {
    _albumList.clear();
    print('Cleared all albums.');
    notifyListeners();
  }

  void _addAlbums(List<CollectionAlbum> albums) {
    _albumList.addAll(albums);
    print('Added ${albums.length} albums.');
    notifyListeners();
  }

  Future<void> updateUsername(String newUsername) async {
    if (newUsername == null || newUsername.isEmpty) {
      print('Cannot update username because the new username is empty.');
      return;
    }
    if (newUsername == _username) {
      print('Collection updated with the same username, so didn\'t reload...');
      return;
    }
    _username = newUsername;
    print('Updated colletion username to: $_username');
    await reload();
  }

  Future<void> reload() async {
    if (_username == null) {
      print('Cannot reload albums because the username is empty.');
      return;
    }
    if (_isLoading) {
      print('Cannot reload yet because the collection is still loading...');
      return;
    }

    print('Reloading collection for $_username...');
    _clearAlbums();
    _nextPage = 1;
    _totalItems = null;
    _totalPages = null;
    await loadMoreAlbums();
  }

  Future<void> loadMoreAlbums() async {
    if (_isLoading) {
      print('Cannot load more yet because the collection is still loading...');
      return;
    }
    if (isFullyLoaded) {
      print('Reached last page, not loading any more.');
      return;
    }
    if (_username == null) {
      throw ('Cannot load albums because the username is empty.');
    }

    _isLoading = true;
    try {
      _addAlbums(await _loadCollectionPage(_nextPage));

      _nextPage++;
    } catch (e, stacktrace) {
      print('Failed to load collection: $e');
      print(stacktrace);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> loadAllAlbums() async {
    if (_isLoading) {
      print('Cannot load more yet because the collection is still loading...');
      return;
    }
    if (isFullyLoaded) {
      print('Reached last page, not loading any more.');
      return;
    }
    if (_username == null) {
      throw ('Cannot load albums because the username is empty.');
    }

    _isLoading = true;
    try {
      final pages = await Future.wait<List<CollectionAlbum>>(
        [
          for (var page = _nextPage; page <= _totalPages; page++)
            _loadCollectionPage(page)
        ],
        eagerError: true,
      );

      pages.forEach(_addAlbums);

      _nextPage = _totalPages + 1; // setting page index to the end

    } catch (e, stacktrace) {
      print('Failed to load collection: $e');
      print(stacktrace);
    } finally {
      _isLoading = false;
    }
  }

  Future<List<CollectionAlbum>> _loadCollectionPage(int page) async {
    print('Started loading albums (page $page) for $_username...');
    http.Response response = await http.get(
      'https://api.discogs.com/users/$_username/collection/folders/0/releases?sort=added&sort_order=desc&per_page=100&page=$page',
      headers: _headers,
    );

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.
      final Map<String, dynamic> page = json.decode(response.body);

      final pageInfo = page['pagination'];
      _totalItems = pageInfo['items'];
      _totalPages = pageInfo['pages'];
      final releases = page['releases'];

      return (releases as List)
          .map((release) => CollectionAlbum.fromJson(release))
          .toList();
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load collection (${response.statusCode})!');
    }
  }

  List<CollectionAlbum> search(String query) {
    final lowerCaseQuery = query.toLowerCase();

    return _albumList
        .where((album) => album.searchString.contains(lowerCaseQuery))
        .toList();
  }

  static Future<AlbumDetails> getAlbumDetails(int releaseId) async {
    try {
      http.Response response = await http.get(
        'https://api.discogs.com/releases/$releaseId',
        headers: _headers,
      );

      if (response.statusCode == 200) {
        // If server returns an OK response, parse the JSON.
        print('Loaded album details for: $releaseId');
        return AlbumDetails.fromJson(json.decode(response.body));
      } else {
        // If that response was not OK, throw an error.
        throw Exception('Received error from Discogs: ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      print('Failed to load album details: $e');
      print(stacktrace);
      throw Exception(e);
    }
  }

  static const int pageSize = 50;
  static const String _consumerKey = DISCOGS_consumerKey;
  static const String _consumerSecret = DISCOGS_consumerSecret;
  static const Map<String, String> _headers = {
    'Authorization': 'Discogs key=$_consumerKey, secret=$_consumerSecret'
  };
}

class Loading extends ValueNotifier<bool> {
  Loading(bool value) : super(value);
}

String _getSingleNameFromArtists(List artists) {
  if (artists?.isEmpty ?? true) {
    return null;
  }
  return artists[0]['name'].replaceAllMapped(
    new RegExp(r'^(.+) \([0-9]+\)$'),
    (Match m) => m[1],
  );
}
