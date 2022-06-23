import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:xml/xml.dart';

import 'playlist.dart';

class LongPollingSession {
  LongPollingSession(this.host, this.port,
      {required this.onChange, LongPollingSession? previousSession, bool? stopWhenPlayerStops, http.Client? httpClient})
      : _playlistTracker = previousSession?._playlistTracker ?? BluOSPlaylistTracker(),
        _stopWhenPlayerStops = stopWhenPlayerStops ?? false,
        _httpClient = httpClient ?? http.Client();

  final String host;
  final int port;
  final void Function() onChange;
  final bool _stopWhenPlayerStops;
  final BluOSPlaylistTracker _playlistTracker;
  final http.Client _httpClient;

  static const int timeout = 100;
  static const Duration initialRetryDelay = Duration(seconds: 15);
  static const Duration maxRetryDelay = Duration(minutes: 2);

  static final _log = Logger('LongPollingSession');

  BluOSPlayerState state = BluOSPlayerState();

  bool _isPolling = false;
  Duration _retryDelay = initialRetryDelay;
  String? _userErrorMessage;

  bool get isPolling => _isPolling;
  String? get errorMessage => _userErrorMessage;
  List<BluOSAPITrack> get playlist => _playlistTracker.tracks;

  Future<void> start() async {
    _isPolling = true;
    await _recursivePolling();
  }

  void stop() {
    if (_isPolling) {
      _isPolling = false;
      _playlistTracker.stop();
      onChange();
    }
  }

  void clear(int timestamp) {
    _playlistTracker.clear(timestamp);
    onChange();
  }

  Future<void> _recursivePolling() async {
    if (!_isPolling) return;

    var delayedRetry = false;
    // make sure that no more than one request per second is made
    var delay = Duration(seconds: 1);

    try {
      // long poll and process status update
      state = await _longPollStatusUpdate();

      _log.info(
          'Long poll result from $host (current state: ${state.playerState}, playlist length: ${_playlistTracker.length})');

      _retryDelay = initialRetryDelay; // reset retry delay

      if (_stopWhenPlayerStops && state.isStopped) {
        return stop();
      }
    } on BluOSHttpException catch (e) {
      _pushErrorMessage('Received unexpected status code: ${e.statusCode}.');
      _log.warning('Received unexpected status code: ${e.statusCode}.');
      if (e.statusCode >= 400 && e.statusCode < 500) {
        // if client error, stop polling
        return stop();
      } else if (e.statusCode >= 500) {
        // if server error, delay retry
        delayedRetry = true;
      }
    } on ClientStoppedException {
      return; // stop polling
    } on TimeoutException catch (e, st) {
      _pushErrorMessage('Connection to $host timed out.');
      _log.info('Timeout error: ${e.toString()}', e, st);
    } on http.ClientException catch (e, st) {
      _pushErrorMessage('The connection to the player was interrupted.');
      _log.warning('Client error: ${e.toString()}', e, st);
    } on SocketException catch (e) {
      _pushErrorMessage('Could not connect to $host.');
      _log.info('Connection error: ${e.toString()}');
      delayedRetry = true;
    } catch (e, st) {
      _pushErrorMessage('Polling error: ${e.toString()}.');
      _log.severe('Polling error: ${e.toString()}', e, st);
      delayedRetry = true;
    } finally {
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

      onChange();
    }

    Future.delayed(delay, () => _recursivePolling());
  }

  Future<BluOSPlayerState> _longPollStatusUpdate() async {
    final uriAuthority = '$host:$port';
    final response = await _httpClient
        .get(Uri.http(uriAuthority, '/Status', {'timeout': timeout.toString(), 'etag': state.etag}))
        .timeout(Duration(milliseconds: (timeout * 1.1 * 1000).round()));

    _clearErrorMessage();

    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);

      final state = BluOSPlayerState.fromXml(document);

      // if not polling anymore then we should stop and ignore this update
      if (!_isPolling) {
        throw ClientStoppedException();
      }

      _log.fine(document.toXmlString(pretty: true, indent: '  '));

      if (state.isActive) {
        try {
          _playlistTracker.updateWith(BluOSAPITrack.fromXml(document, state, uriAuthority));
        } on UnknownTrackException catch (e) {
          // when the track cannot be parsed due to missing fields, we still have an etag so just ingore and continue
          if (state.isPlaying) {
            _pushErrorMessage('Could not get information about track, so it was ignored.');
            _log.warning('Could not parse attribute ${e.failedAttribute}, ignoring track');
          }
          _log.info('BluOS API parsing failed: could not get value for ${e.failedAttribute}');
        }
      }

      return state;
    } else {
      throw BluOSHttpException(response.statusCode);
    }
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

class ClientStoppedException implements Exception {}
