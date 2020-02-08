import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../components/error.dart';
import '../secrets.dart';

class CollectionAlbum {
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

  factory CollectionAlbum.fromJson(Map<String, dynamic> json) {
    final info = json['basic_information'] as Map<String, dynamic>;
    return CollectionAlbum(
      id: json['instance_id'] as int,
      releaseId: json['id'] as int,
      artist: _oneNameForArtists(info['artists'] as List<dynamic>),
      title: info['title'] as String,
      year: info['year'] as int,
      thumbURL: info['thumb'] as String,
      rating: json['rating'] as int,
      dateAdded: json['date_added'] as String,
    );
  }

  final int id;
  final int releaseId;
  final String artist;
  final String title;
  final int year;
  final String thumbURL;
  final int rating;
  final String dateAdded;
  String searchString;

  @override
  String toString() {
    return '$id: $title ($year) by $artist';
  }
}

class AlbumDetails {
  AlbumDetails({
    this.releaseId,
    @required this.artist,
    @required this.title,
    @required this.tracks,
  });

  factory AlbumDetails.fromJson(Map<String, dynamic> json) {
    return AlbumDetails(
      releaseId: json['id'] as int,
      artist: _oneNameForArtists(json['artists'] as List<dynamic>),
      title: json['title'] as String,
      tracks: (json['tracklist'] as List<dynamic>)
          .map<AlbumTrack>((track) => AlbumTrack.fromJson(track))
          .toList(),
    );
  }

  int releaseId;
  String artist;
  String title;
  List<AlbumTrack> tracks;
}

class AlbumTrack {
  AlbumTrack({
    @required this.title,
    this.position,
    this.duration,
    this.artist,
    this.subTracks,
  });

  factory AlbumTrack.fromJson(Map<String, dynamic> json) {
    return AlbumTrack(
      title: json['title'] as String,
      position: json['position'] as String,
      duration: json['duration'] as String,
      artist: _oneNameForArtists(json['artists'] as List<dynamic>),
      subTracks: (json['sub_tracks'] as List<Map<String, dynamic>>)
          ?.map<AlbumTrack>((subTrack) => AlbumTrack.fromJson(subTrack))
          ?.toList(),
    );
  }

  final String title;
  final String position;
  final String duration;
  final String artist;
  final List<AlbumTrack> subTracks;
}

class Collection extends ChangeNotifier {
  Collection(this.userAgent);

  final Logger log = Logger('Collection');

  final String userAgent;
  http.Client httpClient = http.Client();

  String _username;
  final List<CollectionAlbum> _albumList = <CollectionAlbum>[];

  final Loading _loading = Loading();

  int _nextPage = 1;
  int _totalItems;
  int _totalPages;

  Loading get loadingNotifier => _loading;

  bool get isLoading => _loading.value == LoadingStatus.loading;

  bool get isNotLoading => !isLoading;

  bool get hasLoadingError => _loading.value == LoadingStatus.error;

  bool get isEmpty => _albumList.isEmpty;

  bool get isNotEmpty => !isEmpty;

  bool get isUserEmpty => _username == null;

  bool get isFullyLoaded => _nextPage > 1 && _nextPage > _totalPages;

  bool get isNotFullyLoaded => !isFullyLoaded;

  // ignore: avoid_setters_without_getters
  set _loadingStatus(LoadingStatus newValue) => _loading.value = newValue;

  int get totalItems => _totalItems;

  int get totalPages => _totalPages;

  List<CollectionAlbum> get albums => _albumList;

  Map<String, String> get _headers => <String, String>{
        'Authorization': 'Discogs key=$_consumerKey, secret=$_consumerSecret',
        'User-Agent': userAgent,
      };

  void _clearAlbums() {
    _albumList.clear();
    log.info('Cleared all albums.');
    notifyListeners();
  }

  void _addAlbums(List<CollectionAlbum> albums) {
    _albumList.addAll(albums);
    log.fine('Added ${albums.length} albums.');
    notifyListeners();
  }

  Future<void> updateUsername(String newUsername) async {
    if (newUsername == null || newUsername.isEmpty) {
      log.warning('Cannot update username because the new username is empty.');
      return;
    }
    if (newUsername == _username) {
      log.info(
          'Collection updated with the same username, so didn\'t reload...');
      return;
    }
    _username = newUsername;
    log.fine('Updated colletion username to: $_username');
    await reload();
  }

  Future<void> reload() async {
    if (_username == null) {
      log.warning('Cannot reload albums because the username is empty.');
      return;
    }
    if (isLoading) {
      log.info('Cannot reload yet because the collection is still loading...');
      return;
    }

    log.fine('Reloading collection for $_username...');
    _clearAlbums();
    _nextPage = 1;
    _totalItems = null;
    _totalPages = null;
    await loadMoreAlbums();
  }

  Future<void> loadMoreAlbums() async {
    if (isLoading) {
      log.info(
          'Cannot load more yet because the collection is still loading...');
      return;
    }
    if (isFullyLoaded) {
      log.info('Reached last page, not loading any more.');
      return;
    }
    if (_username == null) {
      log.warning('Cannot load albums because the username is empty.');
      return;
    }

    _loadingStatus = LoadingStatus.loading;
    try {
      _addAlbums(await _loadCollectionPage(_nextPage));
      _nextPage++;

      _loadingStatus = LoadingStatus.finished;
    } on Exception {
      _loadingStatus = LoadingStatus.error;
      rethrow;
    }
  }

  Future<void> loadAllAlbums() async {
    if (isLoading) {
      log.info(
          'Cannot load more yet because the collection is still loading...');
      return;
    }
    if (isFullyLoaded) {
      log.info('Reached last page, not loading any more.');
      return;
    }
    if (_username == null) {
      throw UIException('Cannot load albums because the username is empty.');
    }

    _loadingStatus = LoadingStatus.loading;
    try {
      final pages = await Future.wait<List<CollectionAlbum>>(
        <Future<List<CollectionAlbum>>>[
          for (int page = _nextPage; page <= _totalPages; page++)
            _loadCollectionPage(page)
        ],
        eagerError: true,
      );

      pages.forEach(_addAlbums);

      _nextPage = _totalPages + 1; // setting page index to the end

      _loadingStatus = LoadingStatus.finished;
    } on Exception {
      _loadingStatus = LoadingStatus.error;
    }
  }

  Future<List<CollectionAlbum>> _loadCollectionPage(int page) async {
    log.info('Started loading albums (page $page) for $_username...');
    final response = await httpClient.get(
      'https://api.discogs.com/users/$_username/collection/folders/0/releases?sort=added&sort_order=desc&per_page=100&page=$page',
      headers: _headers,
    );

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.
      final page = json.decode(response.body) as Map<String, dynamic>;

      final pageInfo = page['pagination'] as Map<String, dynamic>;
      _totalItems = pageInfo['items'] as int;
      _totalPages = pageInfo['pages'] as int;
      final releases = page['releases'] as List<dynamic>;

      return releases
          .map((dynamic release) =>
              CollectionAlbum.fromJson(release as Map<String, dynamic>))
          .toList();
    } else {
      log.info(
          'Discogs responded with an error loading collection page (${response.statusCode}): ${response.body}');
      // If that response was not OK, throw an error.
      throw UIException(
          'The Discogs service is currently unavailable (${response.statusCode}). Please try again later.');
    }
  }

  List<CollectionAlbum> search(String query) {
    final queries = query.toLowerCase().split(RegExp(r'\s+'));

    return _albumList
        .where((album) => queries.every((q) => album.searchString.contains(q)))
        .toList();
  }

  Future<AlbumDetails> getAlbumDetails(int releaseId) async {
    final response = await httpClient.get(
      'https://api.discogs.com/releases/$releaseId',
      headers: _headers,
    );

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.
      log.info('Loaded album details for: $releaseId');
      return AlbumDetails.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    } else {
      log.info(
          'Discogs responded with an error loading album details (${response.statusCode}): ${response.body}');
      // If that response was not OK, throw an error.
      throw UIException(
          'The Discogs service is currently unavailable (${response.statusCode}). Please try again later.');
    }
  }

  static const int pageSize = 50;
  static const String _consumerKey = discogsConsumerKey;
  static const String _consumerSecret = discogsConsumerSecret;
}

enum LoadingStatus { neverLoaded, loading, finished, error }

class Loading extends ValueNotifier<LoadingStatus> {
  Loading() : super(LoadingStatus.neverLoaded);
}

String _oneNameForArtists(List<dynamic> artists) {
  if (artists?.isEmpty ?? true) {
    return null;
  }
  return (artists[0]['name'] as String).replaceAllMapped(
    RegExp(r'^(.+) \([0-9]+\)$'),
    (m) => m[1],
  );
}
