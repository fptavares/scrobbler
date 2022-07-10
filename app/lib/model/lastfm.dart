import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:scrobbler_bluos_monitor/scrobbler_bluos_monitor.dart';

import '../components/error.dart';
import '../secrets.dart';
import 'discogs.dart';

class Scrobbler {
  Scrobbler(this.userAgent);

  static final Logger _log = Logger('Scrobbler');

  final String userAgent;

  @visibleForTesting
  http.Client httpClient = http.Client();

  String? _sessionKey;

  bool get isNotAuthenticated => _sessionKey == null;

  void updateSessionKey(String? value) {
    if (value != _sessionKey) {
      _sessionKey = value;
      _log.info('Updated session key to: $value');
    }
  }

  Future<String> initializeSession(String username, String password) async {
    _log.info('Initializing Last.fm session for $username...');
    try {
      final response = await _postRequest({
        'method': 'auth.getMobileSession',
        'username': username,
        'password': password,
        'api_key': _apiKey,
      });

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);

        _sessionKey = jsonResponse['session']['key'] as String;
        _log.info('Received new Last.fm session key: $_sessionKey');

        return _sessionKey!;
      } else {
        _log.info('Error response (${response.statusCode}): ${response.body}');
        // If that response was not OK, throw an error.
        final errorCode = json.decode(response.body)['error'];
        throw UIException(errorCode == 4
            ? 'Last.fm authentication failed, please try again.'
            : 'Failed to authenticate to Last.fm ($errorCode)!');
      }
    } on SocketException catch (e) {
      throw UIException('Failed to communicate to Last.fm. Please try again later.', e);
    } on FormatException catch (e) {
      throw UIException('Failed to communicate to Last.fm. Please try again later.', e);
    }
  }

  Stream<int> scrobbleAlbums(List<AlbumDetails> albums, [ScrobbleOptions? options]) async* {
    if (_sessionKey == null) {
      throw UIException('Oops! You need to login to Last.fm first with your username and password.');
    }
    if (albums.isEmpty) {
      throw UIException('Your playlist is empty! Try to add some albums to it first.');
    }

    final queue = _createScrobbleQueue(albums, options);
    for (final scrobbles in queue.batches) {
      yield await _postScrobbles(scrobbles);
    }
  }

  Stream<int> scrobbleBluOSTracks(Iterable<BluOSTrack> tracks) async* {
    if (_sessionKey == null) {
      throw UIException('Oops! You need to login to Last.fm first with your username and password.');
    }
    if (tracks.isEmpty) {
      throw UIException('Your playlist is empty! There\'s nothing to scrobble.');
    }

    final queue = ScrobbleQueue(0); // offset is not relevant because we have real timestamps
    tracks.forEach(queue.addBluosTrack);

    for (final scrobbles in queue.batches) {
      yield await _postScrobbles(scrobbles);
    }
  }

  ScrobbleQueue _createScrobbleQueue(List<AlbumDetails> albums, ScrobbleOptions? options) {
    // set default values if options are null
    options ??= const ScrobbleOptions(inclusionMask: {}, offsetInSeconds: 0);

    final queue = ScrobbleQueue(options.offsetInSeconds);

    for (var albumIndex = albums.length - 1; albumIndex >= 0; albumIndex--) {
      final album = albums[albumIndex];
      final albumMask = options.inclusionMask[albumIndex] ?? const {};

      for (var index = album.tracks.length - 1; index >= 0; index--) {
        final track = album.tracks[index];
        final trackIncluded = albumMask[index] ?? true; // included by default

        if (!trackIncluded) {
          continue;
        }

        if (track.subTracks?.isNotEmpty ?? false) {
          for (final subTrack in track.subTracks!.reversed) {
            queue.add(subTrack, album);
          }
        } else {
          queue.add(track, album);
        }
      }
    }
    return queue;
  }

  Future<int> _postScrobbles(List<Map<String, String>> scrobbles) async {
    if (scrobbles.isEmpty) {
      return 0;
    }
    _log.info('Posting ${scrobbles.length} tracks to Last.fm...');
    http.Response? response;
    try {
      response = await _postRequest(<String, String>{
        'method': 'track.scrobble',
        'api_key': _apiKey,
        'sk': _sessionKey!,
        ...scrobbles.reduce((v, e) => <String, String>{...v, ...e}),
      });

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

        final dynamic accepted = jsonResponse['scrobbles']['@attr']['accepted'];
        final dynamic ignored = jsonResponse['scrobbles']['@attr']['ignored'];
        _log.fine('Scrobbled ${scrobbles.length} tracks: $accepted accepted, $ignored ignored.');

        return accepted as int;
      } else {
        _log.info('Error response from Last.fm (${response.statusCode}): ${response.body}');
        // If that response was not OK, throw an error.
        final errorCode = json.decode(response.body)['error'];
        throw UIException(<int>[4, 9, 14].contains(errorCode)
            ? 'Last.fm authentication failed, please try re-entering your password.'
            : 'Failed to scrobble to Last.fm ($errorCode)!');
      }
    } on SocketException {
      throw UIException('Failed to communicate to Last.fm. Please try again later.');
    } on FormatException catch (e, stackTrace) {
      _log.severe('Failed to parse the Last.fm response: ${response!.body}', e, stackTrace);

      if (response.statusCode == 200) {
        // assume full success in case accepted can't be parsed
        return scrobbles.length;
      } else {
        throw UIException('Failed to communicate to Last.fm. Please try again later.', e);
      }
    }
  }

  Future<http.Response> _postRequest(Map<String, String> params) async {
    final response = await httpClient.post(Uri.https('ws.audioscrobbler.com', '2.0/'), body: <String, String>{
      ...params,
      'api_sig': _createAPISignature(params),
      'format': 'json',
    }, headers: <String, String>{
      'User-Agent': userAgent
    });
    return response;
  }

  static const String _apiKey = lastfmApiKey;
  static const String _sharedSecret = lastfmSharedSecret;

  static String _createAPISignature(Map<String, String> params) {
    var sortedParams = '';
    SplayTreeMap<String, String>.from(params).forEach((k, v) => sortedParams += '$k$v');
    return md5.convert(utf8.encode('$sortedParams$_sharedSecret')).toString();
  }
}

class ScrobbleQueue {
  ScrobbleQueue(int timeOffset)
      : assert(timeOffset >= 0),
        timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor() - timeOffset;

  List<List<Map<String, String>>> batches = <List<Map<String, String>>>[<Map<String, String>>[]];
  int timestamp;

  void add(AlbumTrack track, AlbumDetails album) {
    final splitDuration =
        ((track.duration?.isNotEmpty ?? false) ? track.duration?.split(':').map<int>(int.parse) : <int>[1, 0])!;
    final durationInSeconds = splitDuration.reduce((v, e) => v * 60 + e);

    timestamp -= durationInSeconds;

    addScrobble(
      artist: track.artist ?? album.artist,
      track: track.title,
      album: album.title,
      timestamp: timestamp,
    );
  }

  void addBluosTrack(BluOSTrack track) {
    addScrobble(artist: track.artist, track: track.title, album: track.album, timestamp: track.timestamp);
  }

  void addScrobble({required String artist, required String track, required String? album, required int timestamp}) {
    var index = batches.last.length;
    if (index == 50) {
      batches.add(<Map<String, String>>[]);
      index = 0;
    }

    batches.last.add(<String, String>{
      'artist[$index]': artist,
      'track[$index]': track,
      if (album != null) 'album[$index]': album,
      'timestamp[$index]': timestamp.toString(),
    });
  }
}

class ScrobbleOptions {
  const ScrobbleOptions({required this.inclusionMask, required this.offsetInSeconds});

  final Map<int, Map<int, bool?>> inclusionMask;
  final int offsetInSeconds;
}
