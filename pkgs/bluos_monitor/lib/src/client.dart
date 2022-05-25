import 'dart:core';

import 'package:http/http.dart' as http;

import 'playlist.dart';
import 'polling.dart';

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
  BluOSAPIMonitor();

  factory BluOSAPIMonitor.withNotifier(void Function() changeNotifier) {
    final instance = BluOSAPIMonitor();
    instance._changeNotifier = changeNotifier;
    return instance;
  }

  http.Client? httpClient;

  LongPollingSession? _session;

  String? _playerName;
  bool _isLoading = false;

  @override
  String? get errorMessage => _session?.errorMessage;
  @override
  bool get isLoading => _isLoading;
  @override
  bool get isPolling => _session?.isPolling ?? false;
  @override
  String? get playerName => _playerName;
  @override
  List<BluOSTrack> get playlist => _session?.playlist ?? [];
  @override
  bool get canReload => false;

  BluOSTrackState? get state => _session?.state;

  void Function()? _changeNotifier;

  void _notifyListeners() => _changeNotifier?.call();

  @override
  Future<void> stop() async {
    _session?.stop();
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> start(String host, int port, [String? name, bool? stopWhenPlayerStops]) async {
    if (isLoading) {
      throw BluOSLoadingException();
    }

    _isLoading = true;
    _notifyListeners();

    // stop previous session first
    _session?.stop();

    _playerName = name;

    // create new session
    final newSession = LongPollingSession(host, port,
        onChange: _notifyListeners,
        previousSession: _session,
        stopWhenPlayerStops: stopWhenPlayerStops,
        httpClient: httpClient);

    // start new session
    await newSession.start();
    _session = newSession;

    _isLoading = false;
    _notifyListeners();
  }

  @override
  Future<void> clear(int timestamp) async {
    _session?.clear(timestamp);
  }
}

class BluOSLoadingException implements Exception {}
