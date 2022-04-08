import 'dart:convert';
import 'dart:io';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../components/error.dart';
import '../secrets.dart';

abstract class Album {
  int get releaseId;

  String get artist;

  String get title;

  String? get thumbUrl;
}

String _normalizeSearchString(String s) => removeDiacritics(s).toLowerCase();

class CollectionAlbum implements Album {
  CollectionAlbum(
      {required this.id,
      required this.releaseId,
      required this.artist,
      required this.title,
      required this.formats,
      required this.year,
      required this.thumbUrl,
      required this.rating,
      required this.dateAdded})
      : searchString = _normalizeSearchString('$artist $title');

  factory CollectionAlbum.fromJson(Map<String, dynamic> json) {
    final info = json['basic_information'] as Map<String, dynamic>;
    return CollectionAlbum(
      id: json['instance_id'] as int,
      releaseId: json['id'] as int,
      artist: _oneNameForArtists(info['artists'] as List<dynamic>?),
      title: info['title'] as String,
      formats: (info['formats'] as List<dynamic>?)?.map((format) => AlbumFormat.fromJson(format)).toList() ?? [],
      year: info['year'] as int,
      thumbUrl: info['thumb'] as String?,
      rating: json['rating'] as int?,
      dateAdded: json['date_added'] as String?,
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
  final String? thumbUrl;
  final List<AlbumFormat> formats;
  final int year;
  final int? rating;
  final String? dateAdded;
  final String searchString;

  CollectionAlbum copyWith({required int id}) {
    return CollectionAlbum(
      id: id,
      releaseId: releaseId,
      artist: artist,
      title: title,
      formats: formats,
      year: year,
      thumbUrl: thumbUrl,
      rating: rating,
      dateAdded: dateAdded,
    );
  }
}

class AlbumFormat {
  AlbumFormat({required this.name, this.extraText, this.descriptions, required this.quantity});

  factory AlbumFormat.fromJson(Map<String, dynamic> json) {
    return AlbumFormat(
      name: json['name'],
      extraText: json['text'],
      descriptions:
          (json['descriptions'] as List<dynamic>?)?.map((description) => description as String).toList() ?? [],
      quantity: int.tryParse(json['qty']) ?? 1,
    );
  }

  final String name;
  final String? extraText;
  final List<String>? descriptions;
  final int quantity;

  @override
  String toString() {
    var string = '${quantity > 1 ? '$quantity x ' : ''}$name';
    if (extraText?.isNotEmpty ?? false) {
      string += ' $extraText';
    }
    if (descriptions?.isNotEmpty ?? false) {
      string += ' (${descriptions!.join(', ')})';
    }
    return string;
  }
}

class AlbumDetails implements Album {
  AlbumDetails({
    required this.releaseId,
    required this.artist,
    required this.title,
    required this.thumbUrl,
    required this.tracks,
  });

  factory AlbumDetails.fromJson(Map<String, dynamic> json) {
    return AlbumDetails(
      releaseId: json['id'] as int,
      artist: _oneNameForArtists(json['artists'] as List<dynamic>?),
      title: json['title'] as String,
      thumbUrl: json['thumb'] as String?,
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
  final String? thumbUrl;
  final List<AlbumTrack> tracks;
}

class AlbumTrack {
  AlbumTrack({
    required this.title,
    this.position,
    this.duration,
    this.artist,
    this.subTracks,
  });

  factory AlbumTrack.fromJson(Map<String, dynamic> json) {
    return AlbumTrack(
      title: json['title'] as String,
      position: json['position'] as String?,
      duration: json['duration'] as String?,
      artist: _oneNameForArtists(json['artists'] as List<dynamic>?),
      subTracks:
          (json['sub_tracks'] as List<dynamic>?)?.map<AlbumTrack>((subTrack) => AlbumTrack.fromJson(subTrack)).toList(),
    );
  }

  final String title;
  final String? position;
  final String? duration;
  final String? artist;
  final List<AlbumTrack>? subTracks;
}

class Collection extends ChangeNotifier {
  Collection(this.userAgent);

  @visibleForTesting
  static http.Client fallbackClient = http.Client();

  @visibleForTesting
  static CacheManager cache = CacheManager(
    Config(
      'scrobblerCache',
      stalePeriod: const Duration(days: 30),
    ),
  );

  static final Logger log = Logger('Collection');

  final String userAgent;

  String? _username;
  final List<CollectionAlbum> _albumList = <CollectionAlbum>[];

  final _Progress _progress = _Progress();

  int _nextPage = 1;
  int _totalItems = 0;
  int _totalPages = 0;

  ValueNotifier<LoadingStatus> get loadingNotifier => _progress.statusNotifier;

  bool get isLoading => _progress.status == LoadingStatus.loading;

  bool get isNotLoading => !isLoading;

  bool get hasLoadingError => _progress.status == LoadingStatus.error;

  String? get errorMessage => _progress.errorMessage;

  bool get isEmpty => _albumList.isEmpty;

  bool get isNotEmpty => !isEmpty;

  bool get isUserEmpty => _username == null;

  bool get isFullyLoaded => _nextPage > 1 && _nextPage > _totalPages;

  bool get isNotFullyLoaded => !isFullyLoaded;

  int get totalItems => _totalItems;

  int get totalPages => _totalPages;

  int get nextPage => _nextPage;

  bool get hasMorePages => _nextPage <= _totalPages;

  List<CollectionAlbum> get albums => _albumList;

  Map<String, String> get _headers => <String, String>{
        'Authorization': 'Discogs key=$_consumerKey, secret=$_consumerSecret',
        'User-Agent': userAgent,
      };

  void _reset() {
    _albumList.clear();
    _nextPage = 1;
    _totalItems = 0;
    _totalPages = 0;
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

  Future<void> updateUsername(String? newUsername) async {
    if (newUsername == null || newUsername.isEmpty) {
      log.warning('Cannot update username because the new username is empty.');
      return;
    }
    if (newUsername == _username) {
      log.info('Collection updated with the same username, so didn\'t reload...');
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
        cache.emptyCache();
      }
      _clearAndAddAlbums(await _loadCollectionPage(1));
      _nextPage = 2;

      _progress.finished();
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      _progress.error(e);
      rethrow;
    }
  }

  Future<void> loadMoreAlbums() async {
    if (isLoading) {
      log.info('Cannot load more yet because the collection is still loading...');
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
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      _progress.error(e);
      rethrow;
    }
  }

  Future<void> loadAllAlbums() async {
    if (isLoading) {
      log.info('Cannot load more yet because the collection is still loading...');
      return;
    }
    if (isFullyLoaded) {
      log.info('Reached last page, not loading any more.');
      return;
    }
    if (_username == null) {
      throw UIException('Cannot load albums because the username is empty.');
    }
    if (_totalPages == 0) {
      throw UIException('Cannot load all remaining albums before loading the first page.');
    }

    _progress.loading();
    try {
      final pages = await Future.wait<List<CollectionAlbum>>(
        <Future<List<CollectionAlbum>>>[
          for (int page = _nextPage; page <= _totalPages; page++) _loadCollectionPage(page)
        ],
        eagerError: true,
      );

      pages.forEach(_addAlbums);

      _nextPage = _totalPages + 1; // setting page index to the end

      _progress.finished();
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
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

    return releases.map((dynamic release) => CollectionAlbum.fromJson(release as Map<String, dynamic>)).toList();
  }

  List<CollectionAlbum> search(String query) {
    final queries = _normalizeSearchString(query).split(RegExp(r'\s+'));

    return _albumList.where((album) => queries.every((q) => album.searchString.contains(q))).toList();
  }

  Future<AlbumDetails> loadAlbumDetails(int releaseId) async {
    log.info('Loading album details for: $releaseId');

    return AlbumDetails.fromJson(await _get('/releases/$releaseId'));
  }

  Future<Map<String, dynamic>> _get(String apiPath) async {
    final url = 'https://api.discogs.com$apiPath';
    late String content;

    try {
      content = (await cache.getSingleFile(url, headers: _headers)).readAsStringSync();
    } on SocketException catch (e) {
      throw UIException('Could not connect to Discogs. Please check your internet connection and try again later.', e);
    } on HttpExceptionWithStatus catch (e) {
      // If that response was not OK, throw an error.
      if (e.statusCode == 404) {
        throw UIException('Oops! Couldn\'t find what you\'re looking for on Discogs (404 error).', e);
      } else if (e.statusCode >= 400) {
        throw UIException('The Discogs service is currently unavailable (${e.statusCode}). Please try again later.', e);
      }
    } on HttpException catch (e) {
      // If that response was not OK, throw an error.
      throw UIException('The Discogs service is currently unavailable. Please try again later.', e);
    } on FileSystemException catch (e) {
      log.severe('Failed to read the chached file', e);
      // try falling back to direct download
      final response = await fallbackClient.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) {
        throw UIException('The Discogs service is currently unavailable. Please try again later.',
            HttpException('Fallback request to Discogs failed with status code: ${response.statusCode}'));
      }
      content = response.body;
    }

    return json.decode(content);
  }

  static const int _pageSize = 99;
  static const String _consumerKey = discogsConsumerKey;
  static const String _consumerSecret = discogsConsumerSecret;
}

enum LoadingStatus { neverLoaded, loading, finished, error }

class _Progress {
  final ValueNotifier<LoadingStatus> statusNotifier = ValueNotifier<LoadingStatus>(LoadingStatus.neverLoaded);
  String? errorMessage;

  LoadingStatus get status => statusNotifier.value;

  void loading() {
    errorMessage = null;
    statusNotifier.value = LoadingStatus.loading;
  }

  void finished() {
    errorMessage = null;
    statusNotifier.value = LoadingStatus.finished;
  }

  void error(Object exception) {
    errorMessage = exception is UIException ? exception.message : null;
    statusNotifier.value = LoadingStatus.error;
  }
}

String _oneNameForArtists(List<dynamic>? artists) {
  if (artists?.isEmpty ?? true) {
    return '(unknown)';
  }
  return (artists![0]['name'] as String).replaceAllMapped(
    RegExp(r'^(.+) \([0-9]+\)$'),
    (m) => m[1]!,
  );
}
