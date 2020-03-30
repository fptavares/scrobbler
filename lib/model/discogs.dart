import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../components/error.dart';
import '../secrets.dart';
import 'analytics.dart';

abstract class Album {
  int get releaseId;

  String get artist;

  String get title;

  String get thumbUrl;
}

class CollectionAlbum implements Album {
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
  @override
  final int releaseId;
  @override
  final String artist;
  @override
  final String title;
  @override
  final String thumbUrl;
  final int year;
  final int rating;
  final String dateAdded;
  String searchString;

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

class AlbumDetails implements Album {
  AlbumDetails({
    this.releaseId,
    @required this.artist,
    @required this.title,
    @required this.thumbUrl,
    @required this.tracks,
  });

  factory AlbumDetails.fromJson(Map<String, dynamic> json) {
    return AlbumDetails(
      releaseId: json['id'] as int,
      artist: _oneNameForArtists(json['artists'] as List<dynamic>),
      title: json['title'] as String,
      thumbUrl: json['thumb'] as String,
      tracks: (json['tracklist'] as List<dynamic>)
          .where((track) => track['type_'] != 'heading')
          .map<AlbumTrack>((track) => AlbumTrack.fromJson(track))
          .toList(),
    );
  }

  @override
  final int releaseId;
  @override
  final String artist;
  @override
  final String title;
  @override
  final String thumbUrl;
  final List<AlbumTrack> tracks;
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

  static final MetricHttpClient _httpClient = MetricHttpClient(http.Client());

  @visibleForTesting
  static set innerHttpClient(http.Client newClient) {
    _httpClient.innerClient = newClient;
  }

  @visibleForTesting
  static http.Client get innerHttpClient => _httpClient.innerClient;

  static final CacheManager _cache = CacheManager();

  @visibleForTesting
  static CacheManager get cache => _cache;

  static final Logger log = Logger('Collection');

  final String userAgent;

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

  bool get hasMorePages => _totalPages != null && _nextPage <= _totalPages;

  List<CollectionAlbum> get albums => _albumList;

  Map<String, String> get _headers => <String, String>{
        'Authorization': 'Discogs key=$_consumerKey, secret=$_consumerSecret',
        'User-Agent': userAgent,
      };

  void _reset() {
    _albumList.clear();
    _nextPage = 1;
    _totalItems = null;
    _totalPages = null;
    log.fine('Reset collection.');
    notifyListeners();
  }

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

    // If the username has changed, then we must remove any albums
    // that may have been loaded from the previous user's collection.
    _reset();

    _username = newUsername;
    log.fine('Updated colletion username to: $_username');
    await reload();
  }

  Future<void> reload({bool emptyCache = false}) async {
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
      if (emptyCache) {
        _cache.emptyCache();
      }
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

  Future<List<CollectionAlbum>> _loadCollectionPage(int pageNumber) async {
    log.info('Started loading albums (page $pageNumber) for $_username...');

    final page = await _get(
        '/users/$_username/collection/folders/0/releases?sort=added&sort_order=desc&per_page=$_pageSize&page=$pageNumber');

    final pageInfo = page['pagination'] as Map<String, dynamic>;
    _totalItems = pageInfo['items'] as int;
    _totalPages = pageInfo['pages'] as int;
    final releases = page['releases'] as List<dynamic>;

    return releases
        .map((dynamic release) =>
            CollectionAlbum.fromJson(release as Map<String, dynamic>))
        .toList();
  }

  List<CollectionAlbum> search(String query) {
    final queries = query.toLowerCase().split(RegExp(r'\s+'));

    return _albumList
        .where((album) => queries.every((q) => album.searchString.contains(q)))
        .toList();
  }

  Future<AlbumDetails> loadAlbumDetails(int releaseId) async {
    log.info('Loading album details for: $releaseId');

    return AlbumDetails.fromJson(await _get('/releases/$releaseId'));
  }

  Future<Map<String, dynamic>> _get(String apiPath) async {
    final url = 'https://api.discogs.com$apiPath';
    String content;

    try {
      content = await _cache.get(url, headers: _headers);
    } on SocketException catch (e) {
      throw UIException(
          'Could not connect to Discogs. Please check your internet connection and try again later.',
          e);
    } on HttpException catch (e) {
      // If that response was not OK, throw an error.
      throw UIException(
          'The Discogs service is currently unavailable. Please try again later.',
          e);
    } on FileSystemException catch (e) {
      log.severe('Failed to read the chached file', e);
      // try falling back to direct download
      content = (await _fetchFromDiscogs(url, headers: _headers)).body;
    }

    return json.decode(content) as Map<String, dynamic>;
  }

  static Future<http.Response> _fetchFromDiscogs(String url,
      {Map<String, String> headers}) async {
    log.fine('Fetching from Discogs: $url');
    final response = await _httpClient.get(url, headers: headers);
    if (response?.statusCode == 404) {
      throw UIException(
          'Oops! Couldn\t find what you\'re looking for on Discogs (404 error).');
    }
    return response;
  }

  static const int _pageSize = 99;
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

@visibleForTesting
class CacheManager extends BaseCacheManager {
  CacheManager()
      : super(key,
            maxAgeCacheObject: const Duration(days: 30),
            fileFetcher: fetchFromServer);

  static Future<FileFetcherResponse> fetchFromServer(String url,
          {Map<String, String> headers}) async =>
      HttpFileFetcherResponse(
          await Collection._fetchFromDiscogs(url, headers: headers));

  static const key = 'scrobblerCache';

  @override
  Future<String> getFilePath() async {
    final directory = await getTemporaryDirectory();
    return p.join(directory.path, key);
  }

  Future<String> get(String url, {Map<String, String> headers}) async {
    final fileInfo = await getFile(url, headers: headers).first;
    return fileInfo.file.readAsStringSync();
  }
}
