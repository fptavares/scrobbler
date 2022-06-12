import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:scrobbler_bluos_monitor/scrobbler_bluos_monitor.dart';

import '../components/error.dart';

class BluOS extends ChangeNotifier {
  static final _log = Logger('BluOS');
  static const mdnsName = '_musc._tcp.local';

  BluOS({BluOSAPIMonitor? apiMonitor}) {
    _client = apiMonitorInstance = apiMonitor ?? BluOSAPIMonitor.withNotifier(notifyListeners);
  }

  @visibleForTesting
  late final BluOSAPIMonitor apiMonitorInstance;
  @visibleForTesting
  BluOSExternalMonitorClient? externalMonitorClientInstance;

  late BluOSMonitor _client;

  bool get isLoading => _client.isLoading;
  bool get isPolling => _client.isPolling;
  String? get playerName => _client.playerName;
  String? get errorMessage => _client.errorMessage;
  bool get canReload => _client.canReload;
  bool get isExternal => _client is BluOSExternalMonitorClient;

  List<BluOSTrack> get playlist => _client.playlist;

  void updateMonitorAddress(String? address) {
    address = address?.trim();
    if (address != null && address.isEmpty) {
      address = null; // make sure empty (i.e. no) adress is always saved as null
    }

    if (address != externalMonitorClientInstance?.monitorAddress) {
      if (address == null) {
        externalMonitorClientInstance = null;
        _log.info('Removed external BluOS monitor');
      } else {
        externalMonitorClientInstance = BluOSExternalMonitorClient.withAddressAndNotifier(address, notifyListeners);
        _log.info('Updated external BluOS monitor address to: $address');
      }
    }
  }

  Future<void> refresh() async {
    if (!_client.isPolling) {
      _client = externalMonitorClientInstance ?? apiMonitorInstance;
    }
    await _client.refresh();
  }

  Future<void> start(String host, int port, [String? name, bool? stopWhenPlayerStops]) async {
    if (_client.isPolling) {
      await _client.stop(); // stop the current player before starting again
    }

    _client = externalMonitorClientInstance ?? apiMonitorInstance;

    await _client.start(host, port, name, stopWhenPlayerStops);
  }

  Future<void> stop() => _client.stop();

  Future<void> clear(int timestamp) => _client.clear(timestamp);

  Future<List<BluOSPlayer>> lookupBluOSPlayers() async {
    final players = <BluOSPlayer>[];
    final client = MDnsClient();

    await client.start();
    await for (final ptr in client.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(mdnsName))) {
      await for (final srv in client.lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))) {
        players
            .add(BluOSPlayer(ptr.domainName.substring(0, ptr.domainName.indexOf('.$mdnsName')), srv.target, srv.port));
      }
    }
    client.stop();

    return players;
  }
}

class BluOSExternalMonitorClient implements BluOSMonitor {
  BluOSExternalMonitorClient._(this.monitorAddress);

  factory BluOSExternalMonitorClient.withAddressAndNotifier(String address, Function() changeNotifier) {
    final instance = BluOSExternalMonitorClient._(address);
    instance._changeNotifier = changeNotifier;
    return instance;
  }

  @visibleForTesting
  http.Client httpClient = http.Client();

  final String monitorAddress;

  List<BluOSMonitorTrack> _playlist = [];
  bool _isLoading = false;
  bool _isPolling = false;
  String? _playerName;
  //String? _playerState;
  String? _errorMessage;

  void Function()? _changeNotifier;

  void _notifyListeners() => _changeNotifier?.call();

  @override
  List<BluOSMonitorTrack> get playlist => _playlist;
  @override
  bool get isLoading => _isLoading;
  @override
  bool get isPolling => _isPolling;
  @override
  String? get playerName => _playerName;
  @override
  String? get errorMessage => _errorMessage;
  @override
  bool get canReload => true;

  @override
  Future<void> start(String host, int port, [String? name, bool? _]) async {
    await _get('/start/$host/$port', name != null ? {'name': name} : null);
  }

  @override
  Future<void> refresh() async {
    await _get('/playlist');
  }

  @override
  Future<void> stop() async {
    await _get('/stop');
  }

  Future<void> _get(String path, [Map<String, dynamic>? queryParameters]) async {
    _isLoading = true;
    _notifyListeners();

    try {
      final response =
          await httpClient.get(Uri.http(monitorAddress, path, queryParameters)).timeout(const Duration(seconds: 10));

      final status = json.decode(response.body) as Map<String, dynamic>;

      _isPolling = status['isPolling'] as bool;
      _playerName = status['playerName'] as String?;
      //_playerState = status['playerState'] as String?;
      _errorMessage = status['errorMessage'] as String?;

      _playlist = (status['playlist'] as List<dynamic>).map((track) => BluOSMonitorTrack.fromJson(track)).toList();
    } on SocketException {
      throw UIException('Could not connect to $monitorAddress.');
    } on TimeoutException {
      throw UIException('Connection to $monitorAddress timed out.');
    } catch (error) {
      throw UIException('Failed to process response from $monitorAddress.', error);
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  @override
  Future<void> clear(int timestamp) async {
    await _get('/clear/$timestamp');
  }
}

class BluOSMonitorTrack extends BluOSTrack {
  BluOSMonitorTrack({
    required super.timestamp,
    required super.artist,
    super.album,
    required super.title,
    super.imageUrl,
    required isScrobbable,
  }) : _isScrobbable = isScrobbable;

  factory BluOSMonitorTrack.fromJson(Map<String, dynamic> track) {
    return BluOSMonitorTrack(
      timestamp: track['timestamp'] as int,
      artist: track['artist'] as String,
      title: track['title'] as String,
      album: track['album'] as String?,
      imageUrl: track['image'] as String?,
      isScrobbable: track['isScrobbable'] as bool? ?? true,
    );
  }

  final bool _isScrobbable;

  @override
  bool get isScrobbable => _isScrobbable;
}

@immutable
class BluOSPlayer {
  const BluOSPlayer(this.name, this.host, this.port);

  final String name;
  final String host;
  final int port;
}
