import 'dart:collection';
import 'dart:convert';

import 'package:drs_app/secrets.dart';

import 'discogs.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class Scrobbler {
  String _sessionKey;

  final String userAgent;

  Scrobbler(this.userAgent);

  bool get isNotAuthenticated => (_sessionKey == null);

  set sessionKey(String value) {
    _sessionKey = value;
    print('Updated session key to: $value');
  }

  Future<String> initializeSession(String username, String password) async {
    print('Initializing Last.fm session for $username...');
    http.Response response;
    try {
      response = await _postRequest({
        'method': 'auth.getMobileSession',
        'username': username,
        'password': password,
        'api_key': _apiKey,
      });
    } catch (e, stacktrace) {
      print('Failed to authenticate to Last.fm: $e');
      print(stacktrace);
      throw 'Failed to communicate to Last.fm. Please try again later.';
    }

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      _sessionKey = jsonResponse['session']['key'];
      print('Received new Last.fm session key: $_sessionKey');

      return _sessionKey;
    } else {
      print('Error response (${response.statusCode}): ${response.body}');
      // If that response was not OK, throw an error.
      int errorCode = json.decode(response.body)['error'];
      throw (errorCode == 4)
          ? 'Last.fm authentication failed, please try again.'
          : 'Failed to authenticate to Last.fm ($errorCode)!';
    }
  }

  Stream<int> scrobbleAlbums(List<AlbumDetails> albums) async* {
    if (_sessionKey == null) {
      throw 'Oops! You need to login to Last.fm first with your username and password.';
    }

    ScrobbleQueue queue = _createScrobbleQueue(albums);
    for (var scrobbles in queue.batches) {
      yield await _postScrobbles(scrobbles);
    }
    //return accepted.reduce((v, e) => v + e);
  }

  ScrobbleQueue _createScrobbleQueue(List<AlbumDetails> albums) {
    ScrobbleQueue queue = ScrobbleQueue();

    albums.reversed.forEach((album) {
      album.tracks.reversed.forEach((track) {
        if (track.subTracks?.isNotEmpty ?? false) {
          track.subTracks.reversed
              .forEach((subTrack) => queue.add(subTrack, album));
        } else {
          queue.add(track, album);
        }
      });
    });
    return queue;
  }

  Future<int> _postScrobbles(List<Map<String, String>> scrobbles) async {
    print('Posting ${scrobbles.length} tracks to Last.fm...');
    http.Response response;
    try {
      response = await _postRequest({
        'method': 'track.scrobble',
        'api_key': _apiKey,
        'sk': _sessionKey,
        ...scrobbles.reduce((v, e) => {...v, ...e}),
      });
    } catch (e, stacktrace) {
      print('Failed to scrobble to Last.fm: $e');
      print(stacktrace);
      throw 'Failed to communicate to Last.fm. Please try again later.';
    }

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        final accepted = jsonResponse['scrobbles']['@attr']['accepted'];
        final ignored = jsonResponse['scrobbles']['@attr']['ignored'];
        print('Scrobbled ${scrobbles.length} tracks: $accepted accepted, $ignored ignored.');

        return accepted;

      } catch(e, stacktrace) {
        print('Failed to scrobble to Last.fm: $e');
        print(stacktrace);
        throw 'Failed to communicate to Last.fm. Please try again later.';
      }
    } else {
      print('Error response (${response.statusCode}): ${response.body}');
      // If that response was not OK, throw an error.
      int errorCode = json.decode(response.body)['error'];
      throw ([4, 9, 14].contains(errorCode))
          ? 'Last.fm authentication failed, please try re-entering your password.'
          : 'Failed to scrobble to Last.fm ($errorCode)!';
    }
  }

  Future<http.Response> _postRequest(Map<String, String> params) async {
    http.Response response = await http.post(
        'https://ws.audioscrobbler.com/2.0/',
        body: {
          ...params,
          'api_sig': _createAPISignature(params),
          'format': 'json',
        },
        headers: { 'User-Agent': userAgent }
    );
    return response;
  }

  static const String _apiKey = LASTFM_apiKey;
  static const String _sharedSecret = LASTFM_sharedSecret;

  static String _createAPISignature(Map<String, String> params) {
    String sortedParams = '';
    SplayTreeMap.from(params).forEach((k, v) => sortedParams += '$k$v');
    return md5.convert(utf8.encode('$sortedParams$_sharedSecret')).toString();
  }
}

class ScrobbleQueue {
  List<List<Map<String, String>>> batches = [[]];
  int timestamp = (new DateTime.now().millisecondsSinceEpoch / 1000).floor();

  add(AlbumTrack track, AlbumDetails album) {
    final splitDuration = (track.duration?.isNotEmpty ?? false)
        ? track.duration?.split(':')?.map<int>((c) => int.parse(c))
        : [1, 0];
    final durationInSeconds = splitDuration.reduce((v, e) => v * 60 + e);

    timestamp -= durationInSeconds;

    int index = batches.last.length;
    if (index == 50) {
      batches.add([]);
      index = 0;
    }

    batches.last.add({
      'artist[$index]': track.artist ?? album.artist ?? '(unknown)',
      'track[$index]': track.title,
      'album[$index]': album.title,
      'timestamp[$index]': timestamp.toString(),
    });
  }
}
