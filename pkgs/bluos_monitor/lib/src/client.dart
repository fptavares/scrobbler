import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:xml/xml.dart';

import 'playlist.dart';

abstract class BluOSMonitor {
  bool get isLoading;
  bool get isPolling;
  String? get playerName;
  String? get errorMessage;
  List<BluOSTrack> get playlist;

  bool get canReload;

  Future<void> start(String host, int port, [String? name, bool? stopWhenPlayerStops]);
  Future<void> refresh();
  Future<void> stop();
  Future<void> clear(int timestamp);
}

class BluOSAPIMonitor implements BluOSMonitor {
  BluOSAPIMonitor._();

  factory BluOSAPIMonitor() => _instance;

  factory BluOSAPIMonitor.withNotifier(void Function() changeNotifier) {
    _instance._notifyListeners = changeNotifier;
    return _instance;
  }

  static final BluOSAPIMonitor _instance = BluOSAPIMonitor._();

  static const Duration initialRetryDelay = Duration(seconds: 30);
  static const Duration maxRetryDelay = Duration(minutes: 2);

  static http.Client httpClient = http.Client();

  static final _log = Logger('BluOSAPIMonitor');

  final int timeout = 100;

  BluOSTrackState state = BluOSTrackState();
  final _playlistTracker = BluOSPlaylistTracker();

  String? _playerName;
  bool _isLoading = false;
  bool _isPolling = false;
  Duration _retryDelay = initialRetryDelay;

  String? _userErrorMessage;
  @override
  String? get errorMessage => _userErrorMessage;

  @override
  bool get isLoading => _isLoading;
  @override
  bool get isPolling => _isPolling;
  @override
  String? get playerName => _playerName;
  @override
  List<BluOSTrack> get playlist => _playlistTracker.tracks;
  @override
  bool get canReload => false;

  // ignore: prefer_function_declarations_over_variables
  void Function() _notifyListeners = () {};

  @override
  Future<void> stop() async {
    if (_isPolling) {
      _isPolling = false;
      _playlistTracker.stop();
      _notifyListeners();
    }
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> start(String host, int port, [String? name, bool? stopWhenPlayerStops]) async {
    _isLoading = true;
    _notifyListeners();

    await stop();

    _isPolling = true;
    _playerName = name;
    state = BluOSTrackState(); // reset state so that no etag is sent on first request
    await _recursivePolling(host, port, stopWhenPlayerStops ?? false);

    _isLoading = false;
    _notifyListeners();
  }

  Future<void> _recursivePolling(String host, int port, bool stopWhenPlayerStops) async {
    if (!_isPolling) return;

    var delayedRetry = false;

    try {
      // long poll and process status update
      state = await _longPollStatusUpdate(host, port);

      _log.info(
          'Long poll result from $host (current state: ${state.playerState}, playlist length: ${_playlistTracker.length})');

      _retryDelay = initialRetryDelay; // reset retry delay

      if (stopWhenPlayerStops && state.isStopped) {
        return stop();
      }
    } on BluOSHttpException catch (e) {
      _pushErrorMessage('Received unexpected status code: ${e.statusCode}');
      _log.warning('Received unexpected status code: ${e.statusCode}');
      if (e.statusCode >= 400 && e.statusCode < 500) {
        // if client error, stop polling
        return stop();
      } else if (e.statusCode >= 500) {
        // if server error, delay retry
        delayedRetry = true;
      }
    } on TimeoutException catch (e, st) {
      _pushErrorMessage('Connection to $host timed out.');
      _log.info('Timeout error: ${e.toString()}', e, st);
    } on SocketException catch (e, st) {
      _pushErrorMessage('Could not connect to $host.');
      _log.info('Connection error: ${e.toString()}', e, st);
      delayedRetry = true;
    } catch (e, st) {
      _pushErrorMessage('Polling error: ${e.toString()}');
      _log.severe('Polling error: ${e.toString()}', e, st);
      delayedRetry = true;
    } finally {
      _notifyListeners();
    }

    // make sure that no more than one request per second is made
    var delay = Duration(seconds: 1);

    if (delayedRetry) {
      delay = _retryDelay;

      final retryTimeoutMessage = (_retryDelay.inMicroseconds < Duration.microsecondsPerMinute)
          ? 'Retrying in ${_retryDelay.inSeconds} seconds...'
          : 'Retrying in ${_retryDelay.inMinutes} minute${_retryDelay.inMinutes > 1 ? 's' : ''}...';
      _appendToErrorMessage(retryTimeoutMessage);
      _log.info(retryTimeoutMessage);

      if (_retryDelay < maxRetryDelay) {
        _retryDelay *= 2; // increase delay exponentially
      }
    }

    Future.delayed(delay, () => _recursivePolling(host, port, stopWhenPlayerStops));
  }

  Future<BluOSTrackState> _longPollStatusUpdate(String host, int port) async {
    final uriAuthority = '$host:$port';
    final response = await httpClient
        .get(Uri.http(uriAuthority, '/Status', {'timeout': timeout.toString(), 'etag': state.etag}))
        .timeout(Duration(milliseconds: (timeout * 1.1 * 1000).round()));

    _clearErrorMessage();

    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);

      final state = BluOSTrackState.fromXml(document);

      // if not polling anymore then we should ignore this update
      if (_isPolling && state.isActive) {
        _log.fine(document.toXmlString(pretty: true, indent: '  '));

        try {
          _playlistTracker.addTrack(BluOSAPITrack.fromXml(document, state, uriAuthority));
        } on UnknownTrackException catch (e) {
          // when the track cannot be parsed due to missing fields, we still have an etag so just ingore and continue
          if (state.isPlaying) {
            _pushErrorMessage('Could not get information about track, so it was ignored.');
            _log.warning('Could not parse attribute ${e.failedAttribute}, ignoring track');
          }
          _log.fine('BluOS API parsing failed: could not get value for ${e.failedAttribute}');
        }
      }

      return state;
    } else {
      throw BluOSHttpException(response.statusCode);
    }
  }

  @override
  Future<void> clear(int timestamp) async {
    _playlistTracker.clear(timestamp);
    _notifyListeners();
  }

  void _pushErrorMessage(String message) {
    _userErrorMessage = message;
  }

  void _appendToErrorMessage(String message) {
    _userErrorMessage = '${_userErrorMessage ?? ''} $message';
  }

  void _clearErrorMessage() {
    _userErrorMessage = null;
  }
}

class BluOSHttpException extends HttpException {
  final int statusCode;
  BluOSHttpException(this.statusCode) : super('BluOS device responded with error code');
}
