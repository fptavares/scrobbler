import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:scrobbler_bluos_monitor/scrobbler_bluos_monitor.dart';

import '../components/error.dart';

class BluOS extends ChangeNotifier implements BluOSMonitor {
  static final Logger _log = Logger('BluOS');

  BluOSMonitor _client = BluOSAPIMonitor();

  String? monitorAddress;

  @override
  bool get isLoading => _client.isLoading;
  @override
  bool get isPolling => _client.isPolling;
  @override
  String? get playerName => _client.playerName;
  @override
  String? get errorMessage => _client.errorMessage;
  @override
  bool get canReload => _client.canReload;

  @override
  List<BluOSTrack> get playlist => _client.playlist;

  void updateMonitorAddress(String? address) {
    if (address != null && address.trim().isEmpty) {
      address = null; // make sure empty (i.e. no) adress is always saved as null
    }

    if (address != monitorAddress) {
      monitorAddress = address;
      _log.info('Updated BluOS monitor address to: $address');

      if (address != null) {
        if (!_client.isPolling) {
          _client = BluOSExternalMonitorClient.withAddressAndNotifier(address, notifyListeners);
        }
        if (_client.canReload) {
          _client.refresh();
        }
      }
    }
  }

  @override
  Future<void> refresh() => _client.refresh();

  @override
  Future<void> start(String host, int port, [String? name, bool? stopWhenPlayerStops]) async {
    if (_client.isPolling) {
      _client.stop(); // stop the current player before starting again
    }

    final address = monitorAddress;
    if (address == null || address.trim().isEmpty) {
      _client = BluOSAPIMonitor.withNotifier(notifyListeners);
    } else {
      _client = BluOSExternalMonitorClient.withAddressAndNotifier(address, notifyListeners);
    }

    await _client.start(host, port, name, stopWhenPlayerStops);
  }

  @override
  Future<void> stop() => _client.stop();

  @override
  Future<void> clear(int timestamp) => _client.clear(timestamp);
}

class BluOSExternalMonitorClient implements BluOSMonitor {
  BluOSExternalMonitorClient._();

  factory BluOSExternalMonitorClient.withAddressAndNotifier(String address, Function() changeNotifier) {
    _instance._monitorAddress = address;
    _instance._notifyListeners = changeNotifier;
    return _instance;
  }

  static final BluOSExternalMonitorClient _instance = BluOSExternalMonitorClient._();

  @visibleForTesting
  static http.Client httpClient = http.Client();

  String? _monitorAddress;

  @override
  List<BluOSMonitorTrack> playlist = [];
  bool _isLoading = false;
  bool _isPolling = false;
  String? _playerName;
  String? playerState;
  @override
  String? errorMessage;

  // ignore: prefer_function_declarations_over_variables
  void Function() _notifyListeners = () {};

  @override
  bool get isLoading => _isLoading;
  @override
  bool get isPolling => _isPolling;
  @override
  String? get playerName => _playerName;
  @override
  bool get canReload => true;

  @override
  Future<void> start(String host, int port, [String? name, bool? _]) async {
    await _get('/start/$host/$port', {if (name != null) 'name': name});
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
    final address = _monitorAddress ?? (throw UIException('BluOS monitor address is not set.'));

    _isLoading = true;
    _notifyListeners();

    try {
      final response = await httpClient.get(Uri.http(address, path, queryParameters));

      final status = json.decode(response.body) as Map<String, dynamic>;

      _isPolling = status['isPolling'] as bool;
      _playerName = status['playerName'] as String?;
      playerState = status['playerState'] as String?;
      errorMessage = status['errorMessage'] as String?;

      playlist = (status['playlist'] as List<dynamic>).map((track) => BluOSMonitorTrack.fromJson(track)).toList();
    } on SocketException catch (error) {
      throw UIException('Could not connect to $address.', error);
    } catch (error) {
      throw UIException('Failed to process response from $address.', error);
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
    required timestamp,
    required artist,
    album,
    required title,
    imageUrl,
    required isScrobbable,
  })  : _isScrobbable = isScrobbable,
        super(
          timestamp: timestamp,
          artist: artist,
          album: album,
          title: title,
          imageUrl: imageUrl,
        );

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

  @override
  bool operator ==(Object other) => hashCode == other.hashCode;

  @override
  int get hashCode => '$host:$port'.hashCode;

  static Future<List<BluOSPlayer>> lookupBluOSPlayers() async {
    final players = <BluOSPlayer>[];

    const name = '_musc._tcp.local';
    final client = MDnsClient();
    await client.start();

    await for (final PtrResourceRecord ptr
        in client.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(name))) {
      await for (final SrvResourceRecord srv
          in client.lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))) {
        final bundleId = ptr.domainName.substring(0, ptr.domainName.indexOf('.$name'));
        players.add(BluOSPlayer(bundleId, srv.target, srv.port));
      }
    }
    client.stop();

    return players;
  }
}
