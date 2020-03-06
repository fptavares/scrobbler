import 'dart:convert';
import 'dart:io';

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
      this.thumbUrl,
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
      thumbUrl: info['thumb'] as String,
      rating: json['rating'] as int,
      dateAdded: json['date_added'] as String,
    );
  }

  final int id;
  final int releaseId;
  final String artist;
  final String title;
  final int year;
  final String thumbUrl;
  final int rating;
  final String dateAdded;
  String searchString;

  @override
  String toString() {
    return '$id: $title ($year) by $artist';
  }

  CollectionAlbum copyWith({@required int id}) {
    return CollectionAlbum(
      id: id,
      releaseId: releaseId,
      artist: artist,
      title: title,
      year: year,
      thumbUrl: thumbUrl,
      rating: rating,
      dateAdded: dateAdded,
    );
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
      subTracks: (json['sub_tracks'] as List<dynamic>)
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

  final _Progress _progress = _Progress();

  int _nextPage = 1;
  int _totalItems;
  int _totalPages;

  ValueNotifier<LoadingStatus> get loadingNotifier => _progress.statusNotifier;

  bool get isLoading => _progress.status == LoadingStatus.loading;

  bool get isNotLoading => !isLoading;

  bool get hasLoadingError => _progress.status == LoadingStatus.error;

  String get errorMessage => _progress.errorMessage;

  bool get isEmpty => _albumList.isEmpty;

  bool get isNotEmpty => !isEmpty;

  bool get isUserEmpty => _username == null;

  bool get isFullyLoaded => _nextPage > 1 && _nextPage > _totalPages;

  bool get isNotFullyLoaded => !isFullyLoaded;

  int get totalItems => _totalItems;

  int get totalPages => _totalPages;

  int get nextPage => _nextPage;

  List<CollectionAlbum> get albums => _albumList;

  Map<String, String> get _headers => <String, String>{
        'Authorization': 'Discogs key=$_consumerKey, secret=$_consumerSecret',
        'User-Agent': userAgent,
      };

  void _clearAndAddAlbums(List<CollectionAlbum> albums) {
    _albumList.clear();
    log.fine('Cleared all albums.');
    _addAlbums(albums);
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
    if (isLoading) {
      log.info('Cannot reload yet because the collection is still loading...');
      return;
    }
    if (_username == null) {
      throw UIException('Cannot load albums because the username is empty.');
    }

    log.fine('Reloading collection for $_username...');

    _progress.loading();
    try {
      _clearAndAddAlbums(await _loadCollectionPage(1));
      _nextPage = 2;

      _progress.finished();
    } on Exception catch (e) {
      _progress.error(e);
      rethrow;
    }
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
      log.info('Cannot load albums because the username is empty.');
      return;
    }

    _progress.loading();
    try {
      _addAlbums(await _loadCollectionPage(_nextPage));
      _nextPage++;

      _progress.finished();
    } on Exception catch (e) {
      _progress.error(e);
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
    if (_totalPages == null) {
      throw UIException(
          'Cannot load all remaining albums before loading the first page.');
    }

    _progress.loading();
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

      _progress.finished();
    } on Exception catch (e) {
      _progress.error(e);
      rethrow;
    }
  }

  Future<List<CollectionAlbum>> _loadCollectionPage(int page) async {
    log.info('Started loading albums (page $page) for $_username...');

    http.Response response;
    try {
      response = await httpClient.get(
        'https://api.discogs.com/users/$_username/collection/folders/0/releases?sort=added&sort_order=desc&per_page=100&page=$page',
        headers: _headers,
      );
    } on SocketException catch (e) {
      throw UIException('Could not connect to Discogs. Please check your internet connection and try again later.', e);
    }

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
    } else if (response.statusCode == 404) {
      throw UIException(
          'Discogs couldn\'t find your collection! Please make that the username you provided is correct.');
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
    http.Response response;
    try {
      response = await httpClient.get(
        'https://api.discogs.com/releases/$releaseId',
        headers: _headers,
      );
    } on SocketException catch (e) {
      throw UIException('Could not connect to Discogs. Please check your internet connection and try again later.', e);
    }

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

class _Progress {
  final ValueNotifier<LoadingStatus> statusNotifier =
      ValueNotifier<LoadingStatus>(LoadingStatus.neverLoaded);
  String errorMessage;

  LoadingStatus get status => statusNotifier.value;

  void loading() {
    errorMessage = null;
    statusNotifier.value = LoadingStatus.loading;
  }

  void finished() {
    errorMessage = null;
    statusNotifier.value = LoadingStatus.finished;
  }

  void error(Exception exception) {
    errorMessage = exception is UIException ? exception.message : null;
    statusNotifier.value = LoadingStatus.error;
  }
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
